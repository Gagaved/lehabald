import 'dart:async';
import 'dart:convert';

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
  // Monotonically increasing id for the current connection attempt. Callbacks
  // from a superseded channel carry an older id and are ignored, so a late
  // onDone/onError from a dead socket can never clobber a live connection.
  int _generation = 0;
  // The server broadcasts state every tick (~16ms); if nothing arrives for this
  // long the socket is half-open (common on WiFi) and we force a reconnect.
  static const _watchdogTimeout = Duration(seconds: 3);

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
    if (channel == null) return;
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

  void layClutch() {
    send(const ClientMessage(type: ClientMessageType.layClutch));
  }

  void restart() {
    send(const ClientMessage(type: ClientMessageType.restart));
  }

  void _onMessage(dynamic raw) {
    _lastMessageAt = DateTime.now();
    if (raw is! String) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      snapshot = MapperContainer.globals.fromMap<GameSnapshotDto>(decoded);
      status = snapshot?.status ?? '';
      notifyListeners();
    } catch (error) {
      status = 'Ошибка протокола: $error';
      notifyListeners();
    }
  }

  void _scheduleReconnect([int? generation]) {
    // Ignore late callbacks from a channel we already replaced.
    if (generation != null && generation != _generation) return;
    _channel = null;
    _watchdogTimer?.cancel();
    status = 'Связь потеряна. Переподключение...';
    notifyListeners();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(milliseconds: 900), connect);
  }
}
