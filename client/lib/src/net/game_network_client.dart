import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/widgets.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  final List<String> _logLines = <String>[];
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
  String status = 'Подключение к серверу...';
  bool get connected => _channel != null;
  int get snapshotVersion => _snapshotCount;
  int get snapshotReceivedMs => _snapshotReceivedMs;
  String get diagnosticsText => _buildDiagnosticsText();

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
        onDone: () => _scheduleReconnect(generation),
        onError: (_) => _scheduleReconnect(generation),
      );
      _lastMessageAt = DateTime.now();
      _startWatchdog();
      // Re-register our nickname: the server creates a fresh connection each time.
      _sendName();
    } catch (_) {
      _addLog('connect-error', {'url': serverUrl});
      _scheduleReconnect(generation);
    }
  }

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_channel == null) return;
      // Don't treat a throttled background tab as a dead connection.
      if (!_appActive) return;
      if (DateTime.now().difference(_lastMessageAt) > _watchdogTimeout) {
        // Socket looks alive but the server went silent — tear it down and
        // reconnect rather than keep firing input into a dead pipe.
        _addLog('watchdog-timeout', {
          'silentMs': DateTime.now().difference(_lastMessageAt).inMilliseconds,
        });
        _channel?.sink.close();
        _scheduleReconnect();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reconnectTimer?.cancel();
    _watchdogTimer?.cancel();
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

  void placeTrap() {
    send(const ClientMessage(type: ClientMessageType.placeTrap));
  }

  void useAbility() {
    send(const ClientMessage(type: ClientMessageType.useAbility));
  }

  void placeMagicCrystal() {
    send(const ClientMessage(type: ClientMessageType.placeMagicCrystal));
  }

  void layClutch() {
    send(const ClientMessage(type: ClientMessageType.layClutch));
  }

  void activateMagicChain() {
    send(const ClientMessage(type: ClientMessageType.activateMagicChain));
  }

  void restart() {
    send(const ClientMessage(type: ClientMessageType.restart));
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
      snapshot = MapperContainer.globals.fromMap<GameSnapshotDto>(decoded);
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
    final ts = DateTime.now().toIso8601String();
    final suffix = fields.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
    _logLines.add(suffix.isEmpty ? '$ts $event' : '$ts $event $suffix');
    if (_logLines.length > _maxLogLines) {
      _logLines.removeRange(0, _logLines.length - _maxLogLines);
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
      'status=$status',
      'snapshots=$_snapshotCount',
      'snapshotGapMs avg=${_gapEwmaMs.toStringAsFixed(1)} min=$minGap max=$_maxGapMs lastSilent=$silentMs',
      'lastPayloadBytes=$_lastPayloadBytes',
      'sent=$_sentCount inputOrStop=$_inputCount reconnects=$_reconnects protocolErrors=$_protocolErrors',
      if (snapshot != null)
        'you id=${snapshot!.you.id} role=${snapshot!.you.role.name} slot=${snapshot!.you.slot} phase=${snapshot!.game.phase.name} players=${snapshot!.players.length}',
      '',
      'Recent log:',
      ..._logLines,
    ];
    return summary.join('\n');
  }
}
