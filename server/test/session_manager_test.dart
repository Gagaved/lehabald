import 'dart:async';
import 'dart:io';

import 'package:leha_bald_server/src/net/session_manager.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';
import 'package:test/test.dart';

class _SocketPair {
  _SocketPair(this.server, this.client, this.listener);
  final WebSocket server;
  final WebSocket client;
  final HttpServer listener;

  Future<void> close() async {
    await client.close();
    await server.close();
    await listener.close(force: true);
  }
}

Future<_SocketPair> _socketPair() async {
  final listener = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final connected = Completer<WebSocket>();
  listener.listen((request) async {
    connected.complete(await WebSocketTransformer.upgrade(request));
  });
  final client = await WebSocket.connect(
      'ws://${listener.address.address}:${listener.port}');
  return _SocketPair(await connected.future, client, listener);
}

void main() {
  test(
      'manager isolates sessions, keeps spectators passive and removes empties',
      () async {
    final sockets = await Future.wait(List.generate(4, (_) => _socketPair()));
    addTearDown(() async {
      for (final pair in sockets) {
        await pair.close();
      }
    });

    final manager = SessionManager();
    final peers = sockets
        .map((pair) => manager.createPeer(pair.server))
        .toList(growable: false);

    manager.applyMessage(
        peers[0],
        const ClientMessage(
          type: ClientMessageType.createSession,
          sessionName: 'First',
        ));
    final firstId = peers[0].session!.id;
    manager.applyMessage(
        peers[1],
        ClientMessage(
          type: ClientMessageType.joinSession,
          sessionId: firstId,
        ));
    manager.applyMessage(
        peers[2],
        const ClientMessage(
          type: ClientMessageType.createSession,
          sessionName: 'Second',
        ));
    final second = peers[2].session!;

    manager.applyMessage(
        peers[0],
        const ClientMessage(
          type: ClientMessageType.selectRole,
          role: PlayerRole.leha,
        ));
    manager.applyMessage(
        peers[1],
        const ClientMessage(
          type: ClientMessageType.selectRole,
          role: PlayerRole.hunter,
        ));

    expect(peers[0].session!.phase, SessionPhase.picking);
    expect(second.phase, SessionPhase.waiting);
    expect(identical(peers[0].session!.engine, second.engine), isFalse);

    manager.applyMessage(
        peers[3],
        ClientMessage(
          type: ClientMessageType.joinSession,
          sessionId: firstId,
        ));
    manager.applyMessage(
        peers[3],
        const ClientMessage(
          type: ClientMessageType.input,
          direction: MoveDirection.left,
        ));
    expect(peers[3].player!.slot, isNull);
    expect(peers[3].player!.direction, isNull);

    manager.removePeer(peers[3]);
    manager.removePeer(peers[1]);
    manager.removePeer(peers[0]);
    manager.tick();
    expect(manager.sessions.containsKey(firstId), isFalse);
    expect(manager.sessions.containsKey(second.id), isTrue);
  });
}
