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

GameEngine _engineFor(CaveBiome biome) => GameEngine(
      maze: MazeService(mazeData: _maze, biomes: {biome}),
    )..round.phase = GamePhase.playing;

PlayerConnection _hunter() =>
    PlayerConnection(id: 'hunter', socket: null, x: 4.5, y: 4.5)
      ..slot = 1
      ..role = PlayerRole.hunter
      ..trapCharges = GameConstants.maxTrapCharges;

PlayerConnection _spider() =>
    PlayerConnection(id: 'spider', socket: null, x: 4.5, y: 4.5)
      ..slot = 0
      ..role = PlayerRole.leha
      ..aspect = LehaAspect.spider
      ..webCharges = GameConstants.maxWebCharges;

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

  test('spider web can be placed on ordinary floor', () {
    final engine = _engine();
    final spider = _spider();
    engine.clients[spider.id] = spider;

    engine.placeWeb(spider, 5.5, 4.5);

    expect(engine.round.webs, hasLength(1));
    expect(engine.round.webs.single.x, 5);
    expect(engine.round.webs.single.y, 4);
  });

  test('spider web rejects quicksand, amethyst and mushroom cells', () {
    final quicksandEngine = _engineFor(CaveBiome.sandstone);
    final quicksandSpider = _spider();
    quicksandEngine.clients[quicksandSpider.id] = quicksandSpider;
    quicksandEngine.maze.quicksand.add('5,4');
    quicksandEngine.placeWeb(quicksandSpider, 5.5, 4.5);
    expect(quicksandEngine.round.webs, isEmpty);

    final amethystEngine = _engineFor(CaveBiome.amethyst);
    final amethystSpider = _spider();
    amethystEngine.clients[amethystSpider.id] = amethystSpider;
    amethystEngine.round.shardsIntact.add('5,4');
    amethystEngine.placeWeb(amethystSpider, 5.5, 4.5);
    expect(amethystEngine.round.webs, isEmpty);

    final mushroomEngine = _engine();
    final mushroomSpider = _spider();
    mushroomEngine.clients[mushroomSpider.id] = mushroomSpider;
    mushroomEngine.round.mushrooms.add(MushroomState(x: 5, y: 4));
    mushroomEngine.placeWeb(mushroomSpider, 5.5, 4.5);
    expect(mushroomEngine.round.webs, isEmpty);
    expect(mushroomSpider.webCharges, GameConstants.maxWebCharges);
  });
}
