import 'dart:math';

import 'package:leha_bald_server/src/domain/game_constants.dart';
import 'package:leha_bald_server/src/domain/game_models.dart';
import 'package:leha_bald_server/src/game/game_engine.dart';
import 'package:leha_bald_server/src/game/maze_service.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';
import 'package:test/test.dart';

Point<int> parseCell(String key) {
  final xy = key.split(',').map(int.parse).toList();
  return Point(xy[0], xy[1]);
}

void main() {
  test('biome settings regenerate the lobby map immediately', () {
    final engine = GameEngine(
      maze: MazeService(rng: Random(3), biomes: {CaveBiome.forest}),
    );
    final oldMaze = engine.maze;

    engine.setEnabledBiomes({CaveBiome.amethyst});

    expect(engine.maze, isNot(same(oldMaze)));
    expect(engine.maze.biome, CaveBiome.amethyst);
    expect(engine.round.shardsIntact, engine.maze.amethystShards);
    expect(engine.round.mushrooms, isNotEmpty);
  });

  test('biome settings do not replace a map during an active round', () {
    final engine = GameEngine(
      maze: MazeService(rng: Random(5), biomes: {CaveBiome.forest}),
    );
    engine.round.phase = GamePhase.playing;
    final activeMaze = engine.maze;

    engine.setEnabledBiomes({CaveBiome.frost});

    expect(engine.maze, same(activeMaze));
    expect(engine.enabledBiomes, {CaveBiome.frost});
  });

  test('amethyst sources form a few larger balanced colonies', () {
    for (var seed = 0; seed < 30; seed++) {
      final maze = MazeService.generate(
        seed: seed,
        biomes: {CaveBiome.amethyst},
      );
      expect(maze.amethystWalls, isNotEmpty);
      expect(maze.amethystWallGroups.length, inInclusiveRange(2, 3));
      expect(maze.amethystShards.length,
          lessThanOrEqualTo(GameConstants.amethystShardCount));
      for (final group in maze.amethystWallGroups) {
        expect(
            group.length,
            inInclusiveRange(GameConstants.amethystSourcesPerColonyMin,
                GameConstants.amethystSourcesPerColonyMax));
      }
      for (final key in maze.amethystWalls) {
        final wall = parseCell(key);
        expect(maze.isWall(wall.x, wall.y), isTrue);
      }
      for (final key in maze.amethystShards) {
        final shard = parseCell(key);
        final distance = maze.amethystWalls
            .map(parseCell)
            .map((wall) => (wall.x - shard.x).abs() + (wall.y - shard.y).abs())
            .reduce(min);
        expect(distance,
            lessThanOrEqualTo(GameConstants.amethystShardSourceRadius));
      }
      for (final group in maze.amethystWallGroups) {
        final sources = group.map(parseCell).toList();
        final localCount = maze.amethystShards.map(parseCell).where((shard) {
          final ownDistance = sources
              .map((source) =>
                  (source.x - shard.x).abs() + (source.y - shard.y).abs())
              .reduce(min);
          final nearestDistance = maze.amethystWalls
              .map(parseCell)
              .map(
                  (wall) => (wall.x - shard.x).abs() + (wall.y - shard.y).abs())
              .reduce(min);
          return ownDistance == nearestDistance;
        }).length;
        expect(localCount, greaterThanOrEqualTo(4),
            reason: 'seed $seed group $group has no large starting colony');
      }
    }
  });

  test('a mature mushroom releases fog beyond its own tile', () {
    final maze = MazeService(
      rng: Random(7),
      biomes: {CaveBiome.amethyst},
    );
    final engine = GameEngine(maze: maze);
    Point<int>? cell;
    for (var y = 1; y < maze.rows - 1 && cell == null; y++) {
      for (var x = 1; x < maze.cols - 1; x++) {
        var open = 0;
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            if (!maze.isWall(x + dx, y + dy)) open++;
          }
        }
        if (!maze.isWall(x, y) && open >= 3) {
          cell = Point(x, y);
          break;
        }
      }
    }
    expect(cell, isNotNull);
    engine.round.mushrooms = [
      MushroomState(
        x: cell!.x,
        y: cell.y,
        stage: GameConstants.mushroomMaxStage,
        nextGrowAt: 0,
      ),
    ];
    engine.updateMushrooms(1);
    expect(engine.round.spores.length, greaterThan(1));
  });

  test('expiring spores cannot create more than the growth budget at once', () {
    final maze = MazeService(
      rng: Random(11),
      biomes: {CaveBiome.amethyst},
    );
    final engine = GameEngine(maze: maze);
    for (var y = 1; y < maze.rows - 1; y++) {
      for (var x = 1; x < maze.cols - 1; x++) {
        if (!maze.isWall(x, y)) {
          engine.round.spores.add(SporeState(x: x, y: y, expiresAt: 1));
        }
      }
    }
    engine.updateMushrooms(1);
    expect(engine.round.mushrooms.length,
        lessThanOrEqualTo(GameConstants.mushroomSporeMaxBirthsPerTick));
  });
}
