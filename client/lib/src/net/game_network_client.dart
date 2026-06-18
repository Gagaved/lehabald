import 'dart:async';
import 'dart:convert';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class GameNetworkClient extends ChangeNotifier {
  GameNetworkClient({required String initialUrl}) : serverUrl = initialUrl {
    _loadNickname();
    connect();
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
