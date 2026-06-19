import 'package:leha_bald_server/src/domain/game_constants.dart';
import 'package:leha_bald_server/src/domain/game_models.dart';
import 'package:leha_bald_server/src/game/game_engine.dart';
import 'package:leha_bald_server/src/game/maze_service.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';
import 'package:test/test.dart';

const _openMaze = [
  '#######',
  '#.....#',
  '#.....#',
  '#.....#',
  '#.....#',
  '#.....#',
  '#######',
];

GameEngine _engine() => GameEngine(
      maze: MazeService(mazeData: _openMaze, biomes: {CaveBiome.frost}),
    );

PlayerConnection _wizard() =>
    PlayerConnection(id: 'wizard', socket: null, x: 2.5, y: 2.5)
      ..slot = 0
      ..role = PlayerRole.leha
      ..aspect = LehaAspect.wizard
      ..ready = true;

void main() {
  test('sandbox starts with one ready player and cannot end', () {
    final engine = _engine()..sandboxMode = true;
    final wizard = _wizard();
    engine.clients[wizard.id] = wizard;

    engine.ensureRoundState();
    expect(engine.round.phase, GamePhase.playing);

    engine.endGame(1, 'ignored in sandbox');
    expect(engine.round.phase, GamePhase.playing);
  });

  test('wizard portals and crystals are separate actions', () {
    final engine = _engine()..round.phase = GamePhase.playing;
    final wizard = _wizard();
    engine.clients[wizard.id] = wizard;

    engine.useAbility(wizard);
    expect(engine.round.portals, hasLength(1));
    expect(engine.round.magicCrystals, isEmpty);

    wizard
      ..x = 4.5
      ..y = 4.5;
    engine.useAbility(wizard);
    expect(engine.round.portals, hasLength(2));
    expect(wizard.portalCooldownUntil - engine.nowMs(),
        closeTo(GameConstants.portalCooldownMs, 100));

    engine.placeOrPickMagicCrystal(wizard);
    expect(engine.round.magicCrystals, hasLength(1));
  });
}
