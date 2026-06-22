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
    ..aspect = LehaAspect.wizard
    ..crystalCharges = GameConstants.wizardMaxCrystals;
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
  test('two crystals — no polygon contour, but a beam exists for stun checks',
      () {
    final (engine, wizard, hunter) = wizardGame();
    setCrystals(engine, [(1, 2), (7, 2)]);
    // No polygon possible with 2 crystals.
    expect(engine.round.magicChains, isEmpty);
    // Hunter sitting on the beam should be detected as "on chain".
    hunter
      ..x = 4.5
      ..y = 2.5;
    wizard
      ..x = 2.5
      ..y = 2.5;
    // One tick — hunter gets stunned (beam is active).
    engine.updateMagicChains(1000, GameConstants.tickMs);
    expect(hunter.stunnedUntil, greaterThan(0));
  });

  test('three crystals auto-close the largest visible contour', () {
    final (engine, _, __) = wizardGame();
    setCrystals(engine, [(2, 2), (6, 2), (6, 6)]);
    engine.autoActivateMagicChains(0);

    expect(engine.round.magicChains, hasLength(1));
    expect(engine.round.magicChains.single.contours.single.toSet(), {1, 2, 3});
  });

  test('four crystals auto-close to largest quadrilateral', () {
    final (engine, wizard, _) = wizardGame();
    setCrystals(engine, [(2, 2), (6, 2), (6, 6), (2, 6)]);
    wizard
      ..x = 2.5
      ..y = 2.5;
    engine.autoActivateMagicChains(0);

    expectValidChainNetwork(engine, expectedVertices: {1, 2, 3, 4});
  });

  test('hunter touching a crystal removes it immediately (no fallen state)',
      () {
    final (engine, wizard, hunter) = wizardGame();
    setCrystals(engine, [(6, 2), (4, 6)]);
    wizard
      ..x = 2.5
      ..y = 2.5;
    hunter
      ..x = 6.5
      ..y = 2.5;

    engine.updateMagicChains(1, GameConstants.tickMs);

    expect(engine.round.magicCrystals.map((c) => c.id), isNot(contains(1)));
    expect(engine.round.magicCrystals.any((c) => c.fallen), isFalse);
  });

  test('hunter stunned on beam and immune for wizardChainStunImmuneMs', () {
    final (engine, wizard, hunter) = wizardGame();
    wizard
      ..x = 2.5
      ..y = 2.5;
    setCrystals(engine, [(1, 2), (7, 2)]);
    hunter
      ..x = 4.5
      ..y = 2.5;

    const now = 1000;
    engine.updateMagicChains(now, GameConstants.tickMs);

    expect(hunter.stunnedUntil, now + GameConstants.wizardChainStunMs);
    expect(
      hunter.chainStunImmuneUntil,
      now +
          GameConstants.wizardChainStunMs +
          GameConstants.wizardChainStunImmuneMs,
    );
  });

  test('hunter immune to re-stun during immunity window', () {
    final (engine, wizard, hunter) = wizardGame();
    wizard
      ..x = 2.5
      ..y = 2.5;
    setCrystals(engine, [(1, 2), (7, 2)]);
    hunter
      ..x = 4.5
      ..y = 2.5;

    engine.updateMagicChains(1000, GameConstants.tickMs);
    final firstStunnedUntil = hunter.stunnedUntil;
    final immune = hunter.chainStunImmuneUntil;

    // Still in immunity window — no new stun.
    engine.updateMagicChains(1500, GameConstants.tickMs);
    expect(hunter.stunnedUntil, firstStunnedUntil);
    expect(hunter.chainStunImmuneUntil, immune);
  });

  test('hunter can be re-stunned after immunity expires', () {
    final (engine, wizard, hunter) = wizardGame();
    wizard
      ..x = 2.5
      ..y = 2.5;
    setCrystals(engine, [(1, 2), (7, 2)]);
    hunter
      ..x = 4.5
      ..y = 2.5;

    const t1 = 1000;
    engine.updateMagicChains(t1, GameConstants.tickMs);

    // Tick after immunity expires.
    final afterImmune = hunter.chainStunImmuneUntil + 1;
    engine.updateMagicChains(afterImmune, GameConstants.tickMs);
    expect(hunter.stunnedUntil,
        afterImmune + GameConstants.wizardChainStunMs);
  });

  test('crystal charges start at max and recharge after cooldown', () {
    final (engine, wizard, _) = wizardGame();
    expect(wizard.crystalCharges, GameConstants.wizardMaxCrystals);

    // Simulate spending a charge.
    wizard.crystalCharges -= 1;
    round_addPendingCrystal(engine, 0);
    wizard.magicChainCooldownUntil = GameConstants.wizardCrystalCooldownMs;

    // Before cooldown expires — no recharge.
    engine.rechargeCrystals(5000);
    expect(wizard.crystalCharges, GameConstants.wizardMaxCrystals - 1);

    // After cooldown — charge restored.
    engine.rechargeCrystals(GameConstants.wizardCrystalCooldownMs + 1);
    expect(wizard.crystalCharges, GameConstants.wizardMaxCrystals);
  });

  test('active polygon chain accumulates saturation', () {
    final (engine, wizard, hunter) = wizardGame();
    setCrystals(engine, [(1, 1), (7, 1), (7, 7), (1, 7)]);
    engine.autoActivateMagicChains(0);
    wizard
      ..x = 1.5
      ..y = 1.5;
    hunter
      ..x = 4.5
      ..y = 4.5;

    engine.updateMagicChains(1, 1000);

    expect(engine.round.wizardSaturation, greaterThan(0));
  });

  test('line destroys non-wall objects on chain edges', () {
    final (engine, wizard, hunter) = wizardGame();
    setCrystals(engine, [(2, 2), (6, 2), (4, 6)]);
    engine.round.traps.add(TrapState(
      x: 4,
      y: 2,
      placedAt: 0,
      expiresAt: 1 << 60,
    ));
    engine.maze.bushes.add('5,2');
    engine.autoActivateMagicChains(0);
    engine.updateMagicChains(1, GameConstants.tickMs);
    expect(engine.round.traps, isEmpty);
    expect(engine.maze.bushes, isNot(contains('5,2')));
  });
}

void round_addPendingCrystal(GameEngine engine, int now) {
  engine.round.pendingCrystalRechargeAt
      .add(now + GameConstants.wizardCrystalCooldownMs);
}
