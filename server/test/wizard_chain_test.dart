import 'package:leha_bald_server/src/domain/game_constants.dart';
import 'package:leha_bald_server/src/domain/game_models.dart';
import 'package:leha_bald_server/src/game/game_engine.dart';
import 'package:leha_bald_server/src/game/maze_service.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';
import 'package:test/test.dart';
import 'dart:math';

const openMaze = [
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

(GameEngine, PlayerConnection, PlayerConnection) wizardGame() {
  final engine = GameEngine(
    maze: MazeService(mazeData: openMaze, biomes: {CaveBiome.forest}),
  )..round.phase = GamePhase.playing;
  final wizard = PlayerConnection(id: 'wizard', socket: null, x: 2.5, y: 2.5)
    ..slot = 0
    ..role = PlayerRole.leha
    ..aspect = LehaAspect.wizard;
  final hunter = PlayerConnection(id: 'hunter', socket: null, x: 7.5, y: 7.5)
    ..slot = 1
    ..role = PlayerRole.hunter;
  engine.clients
    ..[wizard.id] = wizard
    ..[hunter.id] = hunter;
  return (engine, wizard, hunter);
}

void setCrystals(GameEngine engine, List<(int, int)> cells) {
  engine.round.magicCrystals = [
    for (var i = 0; i < cells.length; i++)
      MagicCrystalState(id: i + 1, x: cells[i].$1, y: cells[i].$2),
  ];
  engine.round.nextMagicCrystalId = cells.length + 1;
}

String _edgeKey(int a, int b) => a < b ? '$a-$b' : '$b-$a';

Set<String> chainEdges(GameEngine engine) => {
      for (final chain in engine.round.magicChains)
        for (final contour in chain.contours)
          for (var i = 0; i < contour.length; i++)
            _edgeKey(contour[i], contour[(i + 1) % contour.length]),
    };

void expectValidChainNetwork(
  GameEngine engine, {
  required Set<int> expectedVertices,
}) {
  expect(engine.round.magicChains, hasLength(1));
  final chain = engine.round.magicChains.single;
  expect(chain.contours, isNotEmpty);
  final usedVertices = <int>{};
  final edges = <(int, int)>[];
  final contourEdgeSets = <Set<String>>[];
  for (final contour in chain.contours) {
    expect(contour.length, greaterThanOrEqualTo(3));
    expect(contour.toSet(), hasLength(contour.length));
    usedVertices.addAll(contour);
    final contourEdges = <String>{};
    for (var i = 0; i < contour.length; i++) {
      final a = contour[i], b = contour[(i + 1) % contour.length];
      contourEdges.add(_edgeKey(a, b));
      edges.add((a, b));
    }
    expect(contourEdgeSets, isNot(contains(contourEdges)),
        reason: 'the same closed contour must not be stored twice');
    contourEdgeSets.add(contourEdges);
  }
  expect(usedVertices, expectedVertices);

  final byId = {
    for (final crystal in engine.round.magicCrystals)
      crystal.id: Point<double>(crystal.x + 0.5, crystal.y + 0.5),
  };
  double cross(Point<double> a, Point<double> b, Point<double> c) =>
      (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
  bool crosses(
          Point<double> a, Point<double> b, Point<double> c, Point<double> d) =>
      cross(a, b, c) * cross(a, b, d) < 0 &&
      cross(c, d, a) * cross(c, d, b) < 0;
  for (var i = 0; i < edges.length; i++) {
    final (a, b) = edges[i];
    for (var j = i + 1; j < edges.length; j++) {
      final (c, d) = edges[j];
      if ({a, b}.intersection({c, d}).isNotEmpty) continue;
      expect(crosses(byId[a]!, byId[b]!, byId[c]!, byId[d]!), isFalse,
          reason: 'non-neighbouring boundary edges must not cross');
    }
  }
}

void main() {
  test('wizard closes the largest visible simple contour', () {
    final (engine, wizard, _) = wizardGame();
    setCrystals(engine, [(2, 2), (6, 2), (6, 6), (2, 6)]);
    expect(
        engine.maze.hasLineOfSight(const Point(2.5, 2.5), const Point(6.5, 2.5),
            ignoreCover: true),
        isTrue);

    engine.activateMagicChain(wizard);

    expect(engine.round.magicChains, hasLength(1));
    expect(
        engine.round.magicChains.single.contours.single.toSet(), {1, 2, 3, 4});

    // Reactivating the same contour succeeds without duplicating its progress.
    engine.activateMagicChain(wizard);
    expectValidChainNetwork(engine, expectedVertices: {1, 2, 3, 4});
  });

  test('incremental activation preserves old edges and adds a longer contour',
      () {
    final (engine, wizard, _) = wizardGame();
    setCrystals(engine, [(1, 6), (4, 6), (3, 4)]);
    wizard
      ..x = 1.5
      ..y = 6.5;
    engine.activateMagicChain(wizard);
    final oldEdges = chainEdges(engine);

    engine.round.magicCrystals.addAll([
      MagicCrystalState(id: 4, x: 2, y: 3),
      MagicCrystalState(id: 5, x: 3, y: 1),
    ]);
    wizard
      ..x = 2.5
      ..y = 3.5;
    engine.activateMagicChain(wizard);

    expect(engine.round.magicChains.single.contours.length, greaterThan(1));
    expect(chainEdges(engine), containsAll(oldEdges));
    expect(chainEdges(engine).length, greaterThan(oldEdges.length));
    expectValidChainNetwork(engine, expectedVertices: {1, 2, 3, 4, 5});
  });

  final convexCells = <(int, int)>[
    (1, 3),
    (2, 1),
    (5, 1),
    (7, 3),
    (6, 6),
    (2, 6),
  ];
  final insertionOrders = <List<int>>[
    [0, 2, 4, 1, 3, 5],
    [1, 3, 5, 0, 2, 4],
    [0, 1, 3, 5, 4, 2],
  ];
  for (var caseIndex = 0; caseIndex < insertionOrders.length; caseIndex++) {
    test('incremental six-crystal boundary order ${caseIndex + 1}', () {
      final (engine, wizard, _) = wizardGame();
      final order = insertionOrders[caseIndex];
      var previousEdges = <String>{};
      for (var step = 0; step < order.length; step++) {
        final cell = convexCells[order[step]];
        engine.round.magicCrystals.add(
          MagicCrystalState(id: step + 1, x: cell.$1, y: cell.$2),
        );
        engine.round.nextMagicCrystalId = step + 2;
        if (step < 2) continue;
        wizard
          ..x = cell.$1 + 0.5
          ..y = cell.$2 + 0.5;
        engine.activateMagicChain(wizard);
        expectValidChainNetwork(
          engine,
          expectedVertices: {for (var id = 1; id <= step + 1; id++) id},
        );
        final currentEdges = chainEdges(engine);
        expect(currentEdges, containsAll(previousEdges));
        expect(currentEdges.length, greaterThan(previousEdges.length));
        previousEdges = currentEdges;
      }

      final before = engine.round.magicChains.single.contours
          .map((contour) => List<int>.from(contour))
          .toList();
      final beforeEdges = chainEdges(engine);
      engine.activateMagicChain(wizard);
      expect(engine.round.magicChains, hasLength(1));
      expect(engine.round.magicChains.single.contours, before,
          reason: 'reactivation must not duplicate or mutate the boundary');
      expect(chainEdges(engine), beforeEdges);
    });
  }

  test('invalid activation drops the seed and stuns wizard', () {
    final (engine, wizard, _) = wizardGame();
    setCrystals(engine, [(2, 2), (5, 2)]);

    engine.activateMagicChain(wizard);

    expect(engine.round.magicCrystals.first.fallen, isTrue);
    expect(wizard.stunnedUntil, greaterThan(0));
    expect(wizard.magicChainCooldownUntil, greaterThan(0));
  });

  test('picking one vertex keeps a valid remaining triangle active', () {
    final (engine, wizard, _) = wizardGame();
    setCrystals(engine, [(2, 2), (6, 2), (6, 6), (2, 6)]);
    engine.activateMagicChain(wizard);

    engine.placeOrPickMagicCrystal(wizard);

    expect(engine.round.magicCrystals.map((c) => c.id), isNot(contains(1)));
    expect(engine.round.magicChains.single.contours.single, hasLength(3));
  });

  test('hunter breaks a crystal and line destroys non-wall objects', () {
    final (engine, wizard, hunter) = wizardGame();
    setCrystals(engine, [(2, 2), (6, 2), (4, 6)]);
    engine.round.traps.add(TrapState(
      x: 4,
      y: 2,
      placedAt: 0,
      expiresAt: 1 << 60,
    ));
    engine.maze.bushes.add('5,2');
    engine.activateMagicChain(wizard);
    engine.updateMagicChains(1, GameConstants.tickMs);
    expect(engine.round.traps, isEmpty);
    expect(engine.maze.bushes, isNot(contains('5,2')));

    hunter
      ..x = 6.5
      ..y = 2.5;
    engine.updateMagicChains(2, GameConstants.tickMs);
    expect(engine.round.magicCrystals.singleWhere((c) => c.id == 2).fallen,
        isTrue);
    expect(engine.round.magicChains, isEmpty);
  });

  test('active chain accumulates saturation without hunter inside', () {
    final (engine, wizard, hunter) = wizardGame();
    setCrystals(engine, [(1, 1), (7, 1), (7, 7), (1, 7)]);
    engine.activateMagicChain(wizard
      ..x = 1.5
      ..y = 1.5);
    hunter
      ..x = 4.5
      ..y = 4.5;

    engine.updateMagicChains(1, 1000);

    expect(engine.round.wizardSaturation, greaterThan(0));
  });
}
