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
const _devClientPort = 4183;

/// Resolves the WebSocket backend URL.
///
/// Priority:
/// 1. Explicit `SERVER_URL` dart-define — manual override for unusual setups
///    (e.g. a tunnel where the backend lives on a different host).
/// 2. Dev split: when the page is served by the Flutter dev server (port
///    4183), the backend is the same host on port 4173.
/// 3. Single-origin: otherwise connect to the same scheme/host/port that
///    served the page at `/ws`. This is the hosted path — the Dart backend
///    serves both the app and the socket on one port, so it works directly,
///    over the VPN, or behind an https tunnel (scheme upgrades to `wss`)
///    without rebuilding.
/// 4. Localhost fallback for native runs.
String defaultServerUrl() {
  const fromDefine = String.fromEnvironment('SERVER_URL');
  if (fromDefine.isNotEmpty) return fromDefine;

  final base = Uri.base;
  final scheme = base.scheme == 'https' ? 'wss' : 'ws';
  if (base.host.isEmpty || base.host == 'localhost' || base.host == '127.0.0.1') {
    return 'ws://127.0.0.1:$_backendPort/ws';
  }
  if (base.port == _devClientPort) {
    return '$scheme://${base.host}:$_backendPort/ws';
  }
  return '$scheme://${base.host}:${base.port}/ws';
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
      title: 'Леха против Охотника',
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
