import 'package:leha_bald_server/src/domain/game_constants.dart';
import 'package:leha_bald_server/src/domain/game_models.dart';
import 'package:leha_bald_server/src/game/game_engine.dart';
import 'package:leha_bald_server/src/game/maze_service.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';
import 'package:test/test.dart';

const _maze = [
  '#########',
  '#.......#',
  '#.......#',
  '#.......#',
  '#.......#',
  '#.......#',
  '#.......#',
  '#.......#',
  '#########',
];

GameEngine _engine() => GameEngine(
      maze: MazeService(mazeData: _maze, biomes: {CaveBiome.forest}),
    )..round.phase = GamePhase.playing;

PlayerConnection _hunter() =>
    PlayerConnection(id: 'hunter', socket: null, x: 4.5, y: 4.5)
      ..slot = 1
      ..role = PlayerRole.hunter
      ..trapCharges = GameConstants.maxTrapCharges;

void main() {
  test('placement target is accepted inside range and rejected outside it', () {
    final engine = _engine();
    final hunter = _hunter();
    engine.clients[hunter.id] = hunter;

    engine.placeTrap(hunter, 6.5, 4.5);
    expect(engine.round.traps.single.x, 6);
    expect(engine.round.traps.single.y, 4);

    engine.placeTrap(hunter, 1.5, 1.5);
    expect(engine.round.traps, hasLength(1));
  });

  test('barrel uses continuous cursor direction rather than movement octant',
      () {
    final engine = _engine();
    final hunter = _hunter()..hunterKind = HunterKind.sashaYakuza;
    engine.clients[hunter.id] = hunter;

    engine.throwBarrel(hunter, 6.5, 5.5);

    final barrel = engine.round.barrels.single;
    expect(barrel.dirX, closeTo(0.8944, 0.001));
    expect(barrel.dirY, closeTo(0.4472, 0.001));
  });

  test('aim updates facing without changing movement input', () {
    final engine = _engine();
    final hunter = _hunter()..nextDirection = MoveDirection.left;

    engine.updateAim(hunter, 7.5, 1.5);

    expect(hunter.lastDirection, MoveDirection.upRight);
    expect(hunter.nextDirection, MoveDirection.left);
  });
}
