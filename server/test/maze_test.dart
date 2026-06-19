import 'dart:collection';

import 'package:leha_bald_server/src/domain/game_constants.dart';
import 'package:leha_bald_server/src/game/maze_generator.dart';
import 'package:leha_bald_server/src/game/maze_service.dart';
import 'package:test/test.dart';

/// Every open interior cell must be reachable from the first spawn (otherwise a
/// player or collectible could be stranded). Tunnel-row wrap is honoured.
void expectFullyConnected(MazeService svc) {
  final (sx, sy) = (GameConstants.starts.first.x, GameConstants.starts.first.y);
  final cols = svc.cols, rows = svc.rows;
  final seen = <int>{};
  final queue = Queue<(int, int)>();
  void add(int x, int y) {
    var nx = x;
    if (GameConstants.tunnelRows.contains(y)) {
      if (nx < 0) nx = cols - 1;
      if (nx >= cols) nx = 0;
    }
    if (nx < 0 || nx >= cols || y < 0 || y >= rows) return;
    if (svc.isWall(nx, y)) return;
    if (seen.add(y * cols + nx)) queue.add((nx, y));
  }

  add(sx, sy);
  while (queue.isNotEmpty) {
    final (x, y) = queue.removeFirst();
    add(x + 1, y);
    add(x - 1, y);
    add(x, y + 1);
    add(x, y - 1);
  }

  final unreached = <String>[];
  for (var y = 1; y < rows - 1; y++) {
    for (var x = 1; x < cols - 1; x++) {
      if (!svc.isWall(x, y) && !seen.contains(y * cols + x)) {
        unreached.add('$x,$y');
      }
    }
  }
  expect(unreached, isEmpty,
      reason: 'unreachable open cells: $unreached');
}

void main() {
  for (final style in MazeStyle.values) {
    for (var seed = 0; seed < 4; seed++) {
      test('${style.name} seed $seed: valid, connected, starts open', () {
        final maze = MazeGenerator(seed: seed, style: style).generate();
        expect(maze.length, GameConstants.mazeRows);
        expect(maze.first.length, GameConstants.mazeCols);

        final svc = MazeService(mazeData: maze);

        // Spawns are open.
        for (final start in GameConstants.starts) {
          expect(svc.isWall(start.x, start.y), isFalse,
              reason: 'start ${start.x},${start.y} is wall');
        }

        // Plenty of collectibles and a single connected region.
        expect(svc.createLogos().length, greaterThan(10));
        expectFullyConnected(svc);
      });
    }
  }
}
