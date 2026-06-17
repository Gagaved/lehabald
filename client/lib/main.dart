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

const _backendPort = 4173;

/// Resolves the WebSocket backend URL.
///
/// Priority:
/// 1. Explicit `SERVER_URL` dart-define (manual override, e.g. for tunnels
///    where the backend lives on a different host than the client).
/// 2. On web, the same host that served this page, on the backend port — so a
///    single build works on LAN, over the VPN, or behind an https tunnel
///    (which upgrades the scheme to `wss`) without rebuilding.
/// 3. Localhost fallback for native/dev runs.
String defaultServerUrl() {
  const fromDefine = String.fromEnvironment('SERVER_URL');
  if (fromDefine.isNotEmpty) return fromDefine;

  final base = Uri.base;
  if (base.host.isNotEmpty && base.host != 'localhost' && base.host != '127.0.0.1') {
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    return '$scheme://${base.host}:$_backendPort/ws';
  }
  return 'ws://127.0.0.1:$_backendPort/ws';
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
