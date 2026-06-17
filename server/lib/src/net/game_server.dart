import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';

import '../domain/game_constants.dart';
import '../domain/game_models.dart';
import '../game/game_engine.dart';
import '../game/maze_service.dart';

class GameServer {
  GameServer({required this.port}) : engine = GameEngine(maze: MazeService());

  final int port;
  final GameEngine engine;
  HttpServer? _server;
  Timer? _tickTimer;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _tickTimer = Timer.periodic(
      const Duration(milliseconds: GameConstants.tickMs),
      (_) {
        engine.tick();
        broadcastState();
      },
    );

    await _printAddresses();

    await for (final request in _server!) {
      if (WebSocketTransformer.isUpgradeRequest(request) && request.uri.path == '/ws') {
        await _handleSocket(request);
      } else {
        _handleHttp(request);
      }
    }
  }

  Future<void> stop() async {
    _tickTimer?.cancel();
    await _server?.close(force: true);
  }

  Future<void> _handleSocket(HttpRequest request) async {
    final socket = await WebSocketTransformer.upgrade(request);
    final client = engine.createClient(socket);
    socket.listen(
      (data) => _handleMessage(client, data),
      onDone: () {
        engine.removeClient(client);
        broadcastState();
      },
      onError: (_) {
        engine.removeClient(client);
        broadcastState();
      },
    );
    broadcastState();
  }

  void _handleMessage(PlayerConnection client, Object? raw) {
    if (raw is! String) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final message = MapperContainer.globals.fromMap<ClientMessage>(decoded);
      engine.applyMessage(client, message);
      broadcastState();
    } catch (_) {
      return;
    }
  }

  void broadcastState() {
    for (final client in engine.clients.values) {
      final socket = client.socket;
      if (socket.readyState != WebSocket.open) continue;
      socket.add(jsonEncode(engine.snapshotFor(client).toMap()));
    }
  }

  void _handleHttp(HttpRequest request) {
    if (request.uri.path == '/health') {
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'ok': true, 'players': engine.clients.length}))
        ..close();
      return;
    }

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write('''
<!doctype html>
<html lang="ru">
  <head><meta charset="utf-8"><title>Leha Bald Dart Server</title></head>
  <body>
    <h1>Leha Bald Dart Server</h1>
    <p>WebSocket endpoint: <code>/ws</code></p>
    <p>Flutter Flame client connects to this backend over LAN.</p>
  </body>
</html>
''')
      ..close();
  }

  Future<void> _printAddresses() async {
    stdout.writeln('Dart server: http://127.0.0.1:$port/');
    for (final interface in await NetworkInterface.list()) {
      for (final address in interface.addresses) {
        if (address.type == InternetAddressType.IPv4 && !address.isLoopback) {
          stdout.writeln('LAN:         http://${address.address}:$port/');
        }
      }
    }
  }
}
