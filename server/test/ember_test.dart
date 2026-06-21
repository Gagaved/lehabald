import 'dart:math';

import 'package:leha_bald_server/src/domain/game_constants.dart';
import 'package:leha_bald_server/src/domain/game_models.dart';
import 'package:leha_bald_server/src/game/game_engine.dart';
import 'package:leha_bald_server/src/game/maze_service.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';
import 'package:test/test.dart';

PlayerConnection player(String id, int slot, double x, double y) =>
    PlayerConnection(id: id, socket: null, x: x, y: y)
      ..slot = slot
      ..role = slot == 0 ? PlayerRole.leha : PlayerRole.hunter
      ..speed = GameConstants.baseSpeed;

/// A lava cell on [stream] with open ground on both banks — a usable crossing.
Point<int> crossingCell(MazeService maze, int stream) =>
    maze.lavaStreams[stream]
        .map((key) => key.split(',').map(int.parse).toList())
        .map((xy) => Point<int>(xy[0], xy[1]))
        .firstWhere((c) =>
            !maze.isWall(c.x, c.y - 1) &&
            !maze.isWall(c.x, c.y + 1) &&
            !maze.isLava(c.x, c.y - 1) &&
            !maze.isLava(c.x, c.y + 1));

void main() {
  test('ember generation creates exactly 2 or 3 zones without bushes', () {
    for (var seed = 0; seed < 20; seed++) {
      final maze = MazeService.generate(seed: seed, biomes: {CaveBiome.ember});
      expect(maze.bushes, isEmpty);
      expect(maze.lavaStreams.length, inInclusiveRange(1, 2));
      expect(maze.hasValidEmberZones, isTrue,
          reason:
              'seed $seed zones=${maze.emberZoneCount} streams=${maze.lavaStreams.length}');
      expect(maze.isLava(12, GameConstants.starts.first.y), isFalse);
      expect(maze.isLava(12, GameConstants.starts.last.y), isFalse);
    }
  });

  test('a surfaced rock makes only its lava cell steppable', () {
    final maze = MazeService.generate(seed: 12, biomes: {CaveBiome.ember});
    final engine = GameEngine(maze: maze)..round.phase = GamePhase.playing;
    final cell = crossingCell(maze, 0);
    engine.round.emberRocks = [
      EmberRockState(id: 1, x: cell.x, y: cell.y, stream: 0),
    ];
    final p = player('p', 0, cell.x + 0.5, cell.y - 1.5);
    engine.clients[p.id] = p;

    // Standing on the surfaced rock is allowed; a bare lava cell is not.
    expect(engine.isPositionOpen(p, cell.x + 0.5, cell.y + 0.5, 0), isTrue);
    final bare = maze.lavaStreams.first
        .map((key) => key.split(',').map(int.parse).toList())
        .map((xy) => Point<int>(xy[0], xy[1]))
        .firstWhere((c) => c != cell);
    expect(engine.isPositionOpen(p, bare.x + 0.5, bare.y + 0.5, 0), isFalse);
  });

  test('a stepped rock sinks after the delay, but only once vacated, then a '
      'replacement surfaces', () {
    final maze = MazeService.generate(seed: 18, biomes: {CaveBiome.ember});
    final engine = GameEngine(maze: maze)..round.phase = GamePhase.playing;
    final cell = crossingCell(maze, 0);
    final rock = EmberRockState(id: 77, x: cell.x, y: cell.y, stream: 0);
    engine.round.emberRocks = [rock];
    final p = player('a', 0, cell.x + 0.5, cell.y + 0.5);
    engine.clients[p.id] = p;

    // First step starts the sink timer.
    engine.updateEmber(1000);
    expect(rock.steppedSince, 1000);
    expect(rock.sinking, isFalse);

    // Timer elapses but the player is still on it: it sinks yet stays.
    engine.updateEmber(1000 + GameConstants.emberBridgeSinkMs);
    expect(rock.sinking, isTrue);
    expect(engine.round.emberRocks.any((r) => r.id == 77), isTrue);

    // Player steps clear: the rock vanishes and the stream gets a fresh one.
    p
      ..x = cell.x + 0.5
      ..y = cell.y - 1.5;
    engine.updateEmber(1000 + GameConstants.emberBridgeSinkMs + 1);
    expect(engine.round.emberRocks.any((r) => r.id == 77), isFalse);
    expect(engine.round.emberRocks.any((r) => r.stream == 0), isTrue,
        reason: 'the stream immediately receives a replacement rock');
  });

  test('a geyser erupts into a sulfur cloud', () {
    final maze = MazeService.generate(seed: 5, biomes: {CaveBiome.ember});
    final engine = GameEngine(maze: maze)..round.phase = GamePhase.playing;
    final start = GameConstants.starts.first;
    final geyser =
        EmberGeyserState(id: 1, x: start.x, y: start.y, eruptAt: 1000);
    engine.round.geysers = [geyser];
    // Keep the periodic scheduler from queuing a fresh geyser this tick.
    engine.round.nextGeyserAt = 1 << 30;

    engine.updateEmber(1000);

    expect(engine.round.geysers.any((g) => g.id == 1), isFalse);
    expect(
        engine.round.sulfur.any((c) => c.x == start.x && c.y == start.y),
        isTrue);
  });
}
