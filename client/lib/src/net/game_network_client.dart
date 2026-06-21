import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/widgets.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'client_log_event.dart';
import '../game/skill_targeting.dart';

class GameNetworkClient extends ChangeNotifier with WidgetsBindingObserver {
  GameNetworkClient({required String initialUrl}) : serverUrl = initialUrl {
    WidgetsBinding.instance.addObserver(this);
    _loadNickname();
    connect();
  }

  // True only while the tab/app is in the foreground. A backgrounded browser
  // tab gets its timers and message delivery throttled, which would otherwise
  // make the watchdog wrongly think the socket died and reconnect — dropping
  // the player's slot and bouncing everyone back to the lobby.
  bool _appActive = true;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    // On return to the foreground, give the connection a fresh grace window so
    // the watchdog doesn't fire on stale timestamps from while we were hidden.
    if (_appActive) _lastMessageAt = DateTime.now();
  }

  static const _nicknameKey = 'leha_nickname';

  String serverUrl;
  String nickname = '';
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  Timer? _watchdogTimer;
  Timer? _pingTimer;
  DateTime _lastMessageAt = DateTime.now();
  int _lastMessageMs = 0;
  int _snapshotCount = 0;
  int _snapshotReceivedMs = 0;
  int _sentCount = 0;
  int _inputCount = 0;
  int _protocolErrors = 0;
  int _reconnects = 0;
  double _gapEwmaMs = 0;
  int _minGapMs = 1 << 30;
  int _maxGapMs = 0;
  int _lastPayloadBytes = 0;
  final List<ClientLogEvent> _logs = <ClientLogEvent>[];
  int _pingSequence = 0;
  final Map<int, int> _pendingPings = {};
  double _pingMs = 0;
  TargetingSkill? targetingSkill;
  double? aimX;
  double? aimY;
  int _lastAimSentAt = 0;
  // Monotonically increasing id for the current connection attempt. Callbacks
  // from a superseded channel carry an older id and are ignored, so a late
  // onDone/onError from a dead socket can never clobber a live connection.
  int _generation = 0;
  // The server broadcasts state every tick (~16ms); if nothing arrives for this
  // long the socket is half-open (common on WiFi) and we force a reconnect.
  static const _watchdogTimeout = Duration(seconds: 3);
  static const _maxLogLines = 260;

  Future<void> _loadNickname() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_nicknameKey) ?? '';
      if (saved.isNotEmpty && nickname.isEmpty) {
        nickname = saved;
        _sendName();
        notifyListeners();
      }
    } catch (_) {
      // Persistence unavailable — nickname stays in-memory only.
    }
  }

  /// Registers (or changes) the player's nickname and persists it locally.
  Future<void> register(String name) async {
    nickname = name.trim();
    _sendName();
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nicknameKey, nickname);
    } catch (_) {}
  }

  void _sendName() {
    if (nickname.isEmpty) return;
    send(ClientMessage(type: ClientMessageType.setName, name: nickname));
  }

  GameSnapshotDto? snapshot;
  DirectorySnapshotDto? directory;
  String status = 'Подключение к серверу...';
  bool get connected => _channel != null;

  /// True only while the socket is alive AND data is actually flowing. A channel
  /// can be non-null yet silent — e.g. behind a VPN/tunnel whose MTU is below
  /// 1500, large frames get black-holed after the handshake and nothing arrives.
  /// So "have a channel" isn't enough; we also require a recent message. The 1s
  /// watchdog notifies while we're silent, so the UI flips promptly.
  bool get online =>
      _channel != null &&
      DateTime.now().difference(_lastMessageAt) < _watchdogTimeout;

  /// Human-readable reason for the most recent socket drop (close code/reason,
  /// error, or watchdog timeout). Surfaced in the UI and the diagnostics dump.
  String? lastDisconnectReason;
  int get snapshotVersion => _snapshotCount;
  int get snapshotReceivedMs => _snapshotReceivedMs;
  String get diagnosticsText => _buildDiagnosticsText();
  double get pingMs => _pingMs;
  List<ClientLogEvent> get logs => List.unmodifiable(_logs);

  void beginTargeting(TargetingSkill skill) {
    targetingSkill = targetingSkill == skill ? null : skill;
    notifyListeners();
  }

  void cancelTargeting() {
    if (targetingSkill == null) return;
    targetingSkill = null;
    notifyListeners();
  }

  void updateAim(double x, double y) {
    aimX = x;
    aimY = y;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastAimSentAt < 50) return;
    _lastAimSentAt = now;
    send(ClientMessage(type: ClientMessageType.aim, targetX: x, targetY: y));
  }

  void applyTarget(double x, double y) {
    final skill = targetingSkill;
    if (skill == null) return;
    switch (skill) {
      case TargetingSkill.trap:
        placeTrap(targetX: x, targetY: y);
      case TargetingSkill.barrel ||
            TargetingSkill.femboy ||
            TargetingSkill.web ||
            TargetingSkill.portal:
        useAbility(targetX: x, targetY: y);
      case TargetingSkill.crystal:
        placeMagicCrystal(targetX: x, targetY: y);
      case TargetingSkill.chain:
        activateMagicChain(targetX: x, targetY: y);
      case TargetingSkill.clutch:
        layClutch(targetX: x, targetY: y);
    }
    targetingSkill = null;
    notifyListeners();
  }

  void addClientLog(String event, [Map<String, Object?> fields = const {}]) {
    _addLog(event, fields);
  }

  void connect([String? url]) {
    if (url != null && url.isNotEmpty) serverUrl = url;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();

    final generation = ++_generation;
    try {
      final channel = WebSocketChannel.connect(Uri.parse(serverUrl));
      _channel = channel;
      status = 'Ожидание сервера...';
      _addLog('connect', {'url': serverUrl, 'generation': generation});
      notifyListeners();
      _subscription = channel.stream.listen(
        _onMessage,
        onDone: () {
          _noteDisconnect(
            'socket-closed',
            code: channel.closeCode,
            reason: channel.closeReason,
          );
          _scheduleReconnect(generation);
        },
        onError: (Object error) {
          _noteDisconnect('socket-error', error: error);
          _scheduleReconnect(generation);
        },
      );
      _lastMessageAt = DateTime.now();
      _startWatchdog();
      _startPing();
      // Re-register our nickname: the server creates a fresh connection each time.
      _sendName();
    } catch (error) {
      _noteDisconnect('connect-error', error: error);
      _scheduleReconnect(generation);
    }
  }

  /// Records why the socket went down so the UI can show a real reason instead
  /// of silently dropping back to an empty session list. Also logs it and pokes
  /// listeners so the disconnect banner appears immediately.
  void _noteDisconnect(String event, {int? code, String? reason, Object? error}) {
    final parts = <String>[
      if (code != null) 'код $code',
      if (reason != null && reason.isNotEmpty) reason,
      if (error != null) '$error',
    ];
    lastDisconnectReason = parts.isEmpty ? event : parts.join(' · ');
    _addLog(event, {
      if (code != null) 'code': code,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (error != null) 'error': '$error',
    });
    notifyListeners();
  }

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_channel == null) return;
      // Don't treat a throttled background tab as a dead connection.
      if (!_appActive) return;
      final silentMs = DateTime.now().difference(_lastMessageAt).inMilliseconds;
      if (silentMs > _watchdogTimeout.inMilliseconds) {
        // Socket looks alive but the server went silent — tear it down and
        // reconnect rather than keep firing input into a dead pipe. (Classic
        // symptom of an MTU black hole: handshake succeeds, frames never come.)
        _noteDisconnect('watchdog-timeout',
            reason: 'сервер молчит $silentMs мс');
        _channel?.sink.close();
        _scheduleReconnect();
      }
    });
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pendingPings.clear();
    _pingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      final channel = _channel;
      if (channel == null || !_appActive) return;
      final id = ++_pingSequence;
      final sentAt = DateTime.now().millisecondsSinceEpoch;
      _pendingPings[id] = sentAt;
      _pendingPings.removeWhere((_, value) => sentAt - value > 10000);
      channel.sink.add(jsonEncode({'ping': id}));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();
    _watchdogTimer?.cancel();
    _pingTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  void send(ClientMessage message) {
    final channel = _channel;
    if (channel == null) {
      _addLog('send-drop', {'type': message.type.name, 'reason': 'no-channel'});
      return;
    }
    _sentCount += 1;
    if (message.type == ClientMessageType.input ||
        message.type == ClientMessageType.stop) {
      _inputCount += 1;
    }
    channel.sink.add(jsonEncode(message.toMap()));
  }

  void input(MoveDirection direction) {
    send(ClientMessage(type: ClientMessageType.input, direction: direction));
  }

  void stop() {
    send(const ClientMessage(type: ClientMessageType.stop));
  }

  void selectRole(PlayerRole role) {
    send(ClientMessage(type: ClientMessageType.selectRole, role: role));
  }

  void selectAspect(LehaAspect aspect) {
    send(ClientMessage(type: ClientMessageType.selectAspect, aspect: aspect));
  }

  void selectHunter(HunterKind hunter) {
    send(ClientMessage(type: ClientMessageType.selectHunter, hunter: hunter));
  }

  void addBot(PlayerRole role) {
    send(ClientMessage(type: ClientMessageType.addBot, role: role));
  }

  void removeBot(PlayerRole role) {
    send(ClientMessage(type: ClientMessageType.removeBot, role: role));
  }

  void ready(bool ready) {
    send(ClientMessage(type: ClientMessageType.ready, ready: ready));
  }

  void spectate() {
    send(const ClientMessage(type: ClientMessageType.spectate));
  }

  void createSession(String name) {
    send(ClientMessage(
      type: ClientMessageType.createSession,
      sessionName: name,
    ));
  }

  void joinSession(String id) {
    send(ClientMessage(type: ClientMessageType.joinSession, sessionId: id));
  }

  void leaveSession() {
    send(const ClientMessage(type: ClientMessageType.leaveSession));
  }

  void rematch() {
    send(const ClientMessage(type: ClientMessageType.rematch));
  }

  void placeTrap({double? targetX, double? targetY}) {
    send(ClientMessage(
        type: ClientMessageType.placeTrap, targetX: targetX, targetY: targetY));
  }

  void useAbility({double? targetX, double? targetY}) {
    send(ClientMessage(
        type: ClientMessageType.useAbility,
        targetX: targetX,
        targetY: targetY));
  }

  void placeMagicCrystal({double? targetX, double? targetY}) {
    send(ClientMessage(
        type: ClientMessageType.placeMagicCrystal,
        targetX: targetX,
        targetY: targetY));
  }

  void layClutch({double? targetX, double? targetY}) {
    send(ClientMessage(
        type: ClientMessageType.layClutch, targetX: targetX, targetY: targetY));
  }

  void activateMagicChain({double? targetX, double? targetY}) {
    send(ClientMessage(
        type: ClientMessageType.activateMagicChain,
        targetX: targetX,
        targetY: targetY));
  }

  void setBiomes(List<CaveBiome> biomes) {
    send(ClientMessage(type: ClientMessageType.setBiomes, biomes: biomes));
  }

  void setSandbox(bool enabled) {
    send(ClientMessage(type: ClientMessageType.setSandbox, sandbox: enabled));
  }

  void _onMessage(dynamic raw) {
    final receivedAt = DateTime.now();
    final receivedMs = receivedAt.millisecondsSinceEpoch;
    _lastMessageAt = receivedAt;
    if (raw is! String) return;
    try {
      final decodeWatch = Stopwatch()..start();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final pong = decoded['pong'];
      if (pong is int) {
        final sentAt = _pendingPings.remove(pong);
        if (sentAt != null) {
          final measured = max(0, receivedMs - sentAt).toDouble();
          _pingMs = _pingMs == 0 ? measured : _pingMs * 0.75 + measured * 0.25;
          _addLog('ping', {'ms': measured.toStringAsFixed(0)});
          notifyListeners();
        }
        return;
      }
      if (decoded['type'] == 'directory') {
        directory =
            MapperContainer.globals.fromMap<DirectorySnapshotDto>(decoded);
        snapshot = null;
        status = '';
        notifyListeners();
        return;
      }
      snapshot = MapperContainer.globals.fromMap<GameSnapshotDto>(decoded);
      directory = null;
      decodeWatch.stop();
      _recordSnapshot(raw.length, receivedMs, decodeWatch.elapsedMicroseconds);
      status = snapshot?.status ?? '';
      notifyListeners();
    } catch (error) {
      _protocolErrors += 1;
      _addLog('protocol-error', {'error': '$error'});
      status = 'Ошибка протокола: $error';
      notifyListeners();
    }
  }

  void _scheduleReconnect([int? generation]) {
    // Ignore late callbacks from a channel we already replaced.
    if (generation != null && generation != _generation) return;
    _reconnects += 1;
    _addLog('reconnect-scheduled', {
      if (generation != null) 'generation': generation,
      'total': _reconnects,
    });
    _channel = null;
    _watchdogTimer?.cancel();
    _pingTimer?.cancel();
    status = 'Связь потеряна. Переподключение...';
    notifyListeners();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(milliseconds: 900), connect);
  }

  void _recordSnapshot(int payloadBytes, int receivedMs, int decodeUs) {
    _snapshotCount += 1;
    _snapshotReceivedMs = receivedMs;
    _lastPayloadBytes = payloadBytes;
    if (_lastMessageMs != 0) {
      final gap = max(0, receivedMs - _lastMessageMs);
      _minGapMs = min(_minGapMs, gap);
      _maxGapMs = max(_maxGapMs, gap);
      _gapEwmaMs =
          _gapEwmaMs == 0 ? gap.toDouble() : _gapEwmaMs * 0.92 + gap * 0.08;
      if (gap > 80) {
        _addLog('snapshot-gap', {'gapMs': gap, 'bytes': payloadBytes});
      }
    }
    _lastMessageMs = receivedMs;
    if (_snapshotCount == 1 || _snapshotCount % 300 == 0) {
      _addLog('snapshot-stats', {
        'count': _snapshotCount,
        'gapAvgMs': _gapEwmaMs.toStringAsFixed(1),
        'gapMaxMs': _maxGapMs,
        'decodeUs': decodeUs,
        'bytes': payloadBytes,
      });
    }
  }

  void _addLog(String event, [Map<String, Object?> fields = const {}]) {
    _logs.add(ClientLogEvent.create(event, fields));
    if (_logs.length > _maxLogLines) {
      _logs.removeRange(0, _logs.length - _maxLogLines);
    }
  }

  String _buildDiagnosticsText() {
    final now = DateTime.now();
    final silentMs = now.difference(_lastMessageAt).inMilliseconds;
    final minGap = _minGapMs == 1 << 30 ? 0 : _minGapMs;
    final summary = <String>[
      'Leha Bald client diagnostics',
      'time=${now.toIso8601String()}',
      'url=$serverUrl',
      'connected=$connected',
      'pingMs=${_pingMs.toStringAsFixed(0)}',
      'status=$status',
      'online=$online lastDisconnect=${lastDisconnectReason ?? '-'}',
      'snapshots=$_snapshotCount',
      'snapshotGapMs avg=${_gapEwmaMs.toStringAsFixed(1)} min=$minGap max=$_maxGapMs lastSilent=$silentMs',
      'lastPayloadBytes=$_lastPayloadBytes',
      'sent=$_sentCount inputOrStop=$_inputCount reconnects=$_reconnects protocolErrors=$_protocolErrors',
      if (snapshot != null)
        'you id=${snapshot!.you.id} role=${snapshot!.you.role.name} slot=${snapshot!.you.slot} phase=${snapshot!.game.phase.name} players=${snapshot!.players.length}',
      '',
      'Recent log:',
      ..._logs.map((log) => '[${log.category.name}] ${log.formatted}'),
    ];
    return summary.join('\n');
  }
}
