import 'dart:async';
import 'dart:convert';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class GameNetworkClient extends ChangeNotifier {
  GameNetworkClient({required String initialUrl}) : serverUrl = initialUrl {
    connect();
  }

  String serverUrl;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;

  GameSnapshotDto? snapshot;
  String status = 'Подключение к серверу...';
  bool get connected => _channel != null;

  void connect([String? url]) {
    if (url != null && url.isNotEmpty) serverUrl = url;
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();

    try {
      final channel = WebSocketChannel.connect(Uri.parse(serverUrl));
      _channel = channel;
      status = 'Ожидание сервера...';
      notifyListeners();
      _subscription = channel.stream.listen(
        _onMessage,
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
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

  void _scheduleReconnect() {
    _channel = null;
    status = 'Связь потеряна. Переподключение...';
    notifyListeners();
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(milliseconds: 900), connect);
  }
}
