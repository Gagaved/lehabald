import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';

import '../domain/game_constants.dart';
import 'session_manager.dart';

class GameServer {
  GameServer({required this.port});

  final int port;
  final SessionManager sessions = SessionManager();
  HttpServer? _server;
  Timer? _tickTimer;
  late final Directory? _webRoot = _resolveWebRoot();

  static Directory? _resolveWebRoot() {
    final candidates = <String>[
      Platform.environment['WEB_ROOT'] ?? '',
      'client/build/web',
      '../client/build/web',
    ];
    for (final candidate in candidates) {
      if (candidate.isEmpty) continue;
      final dir = Directory(candidate);
      if (dir.existsSync() && File('${dir.path}/index.html').existsSync()) {
        return dir.absolute;
      }
    }
    return null;
  }

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _tickTimer = Timer.periodic(
      const Duration(milliseconds: GameConstants.tickMs),
      (_) {
        sessions.tick();
        broadcastState();
      },
    );

    await _printAddresses();

    await for (final request in _server!) {
      if (WebSocketTransformer.isUpgradeRequest(request) &&
          request.uri.path == '/ws') {
        // Do NOT await: the WS handshake is a network round-trip with the
        // client. Awaiting here serializes the accept loop behind each upgrade,
        // so one slow/remote client blocks everyone else from connecting —
        // invisible on localhost (sub-ms handshakes) but ~1/3 of connects time
        // out over WAN. Dispatch concurrently and swallow a failed upgrade so it
        // can't tear down the accept loop.
        unawaited(_handleSocket(request).catchError((Object _) {}));
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
    final client = sessions.createPeer(socket);
    socket.listen(
      (data) => _handleMessage(client, data),
      onDone: () {
        sessions.removePeer(client);
        broadcastState();
      },
      onError: (_) {
        sessions.removePeer(client);
        broadcastState();
      },
    );
    broadcastState();
  }

  void _handleMessage(ClientPeer client, Object? raw) {
    if (raw is! String) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      final ping = decoded['ping'];
      if (ping is int) {
        client.socket.add(jsonEncode({'pong': ping}));
        return;
      }
      final message = MapperContainer.globals.fromMap<ClientMessage>(decoded);
      sessions.applyMessage(client, message);
      broadcastState();
    } catch (_) {
      return;
    }
  }

  void broadcastState() {
    for (final client in sessions.peers.values) {
      final socket = client.socket;
      if (socket.readyState != WebSocket.open) continue;
      final session = client.session;
      final payload = session == null
          ? sessions.directory().toMap()
          : session.snapshotFor(client).toMap();
      socket.add(jsonEncode(payload));
    }
  }

  void _handleHttp(HttpRequest request) {
    if (request.uri.path == '/health') {
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({
          'ok': true,
          'players': sessions.peers.length,
          'sessions': sessions.sessions.length,
        }))
        ..close();
      return;
    }

    if (_serveStatic(request)) return;

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
    <p>Web client build not found. Run <code>fvm flutter build web</code> in <code>client/</code>.</p>
  </body>
</html>
''')
      ..close();
  }

  /// Serves the built Flutter web client from [_webRoot] so the app and the
  /// WebSocket live on the same origin (one port → one tunnel). Returns false
  /// when no build is present, so the caller can fall back to a notice page.
  bool _serveStatic(HttpRequest request) {
    final root = _webRoot;
    if (root == null) return false;

    var path = Uri.decodeComponent(request.uri.path);
    if (path == '/' || path.isEmpty) path = '/index.html';
    if (path.contains('..')) {
      request.response
        ..statusCode = HttpStatus.forbidden
        ..close();
      return true;
    }

    var file = File('${root.path}$path');
    if (!file.existsSync()) {
      // SPA fallback: unknown routes serve index.html.
      file = File('${root.path}/index.html');
      if (!file.existsSync()) return false;
    }

    request.response.headers.contentType = _contentTypeFor(file.path);
    // Dev/LAN server: never let the browser cache a stale client build.
    request.response.headers
      ..set(HttpHeaders.cacheControlHeader, 'no-store, must-revalidate')
      ..set(HttpHeaders.pragmaHeader, 'no-cache')
      ..set(HttpHeaders.expiresHeader, '0');
    unawaited(
      file.openRead().pipe(request.response).catchError((Object _) {}),
    );
    return true;
  }

  ContentType _contentTypeFor(String filePath) {
    final dot = filePath.lastIndexOf('.');
    final ext = dot == -1 ? '' : filePath.substring(dot + 1).toLowerCase();
    switch (ext) {
      case 'html':
        return ContentType.html;
      case 'js':
      case 'mjs':
        return ContentType('text', 'javascript', charset: 'utf-8');
      case 'json':
        return ContentType.json;
      case 'css':
        return ContentType('text', 'css', charset: 'utf-8');
      case 'wasm':
        return ContentType('application', 'wasm');
      case 'png':
        return ContentType('image', 'png');
      case 'jpg':
      case 'jpeg':
        return ContentType('image', 'jpeg');
      case 'gif':
        return ContentType('image', 'gif');
      case 'svg':
        return ContentType('image', 'svg+xml');
      case 'ico':
        return ContentType('image', 'x-icon');
      case 'ttf':
        return ContentType('font', 'ttf');
      case 'otf':
        return ContentType('font', 'otf');
      case 'woff':
        return ContentType('font', 'woff');
      case 'woff2':
        return ContentType('font', 'woff2');
      default:
        return ContentType('application', 'octet-stream');
    }
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
