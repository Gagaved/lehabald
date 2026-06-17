import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';

import 'src/game/leha_bald_game.dart';
import 'src/net/game_network_client.dart';
import 'src/ui/game_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ensureProtocolMappersInitialized();
  final network = GameNetworkClient(initialUrl: defaultServerUrl());
  final game = LehaBaldGame(network: network);
  runApp(LehaBaldApp(network: network, game: game));
}

String defaultServerUrl() {
  const fromDefine = String.fromEnvironment('SERVER_URL');
  if (fromDefine.isNotEmpty) return fromDefine;
  return 'ws://127.0.0.1:4173/ws';
}

class LehaBaldApp extends StatelessWidget {
  const LehaBaldApp({
    required this.network,
    required this.game,
    super.key,
  });

  final GameNetworkClient network;
  final LehaBaldGame game;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Леха против Бахиркина',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xff05070d),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff00f2ea),
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: GameWidget(game: game),
            ),
            Positioned.fill(
              child: GameOverlay(network: network),
            ),
          ],
        ),
      ),
    );
  }
}
