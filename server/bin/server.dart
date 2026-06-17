import 'dart:io';

import 'package:leha_bald_shared/leha_bald_shared.dart';
import 'package:leha_bald_server/src/net/game_server.dart';

Future<void> main(List<String> args) async {
  ensureProtocolMappersInitialized();
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 4173;
  final server = GameServer(port: port);
  await server.start();
}
