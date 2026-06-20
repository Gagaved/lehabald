import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leha_bald_client/src/game/leha_bald_game.dart';
import 'package:leha_bald_client/src/net/game_network_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('game uses Flame lifecycle, keyboard and performance mixins', () {
    final game = LehaBaldGame(
      network: GameNetworkClient(initialUrl: 'ws://127.0.0.1:4173/ws'),
    );

    expect(game, isA<HasKeyboardHandlerComponents>());
    expect(game, isA<SingleGameInstance>());
    expect(game, isA<HasPerformanceTracker>());
  });
}
