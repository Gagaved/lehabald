import 'dart:collection';
import 'dart:math';

import '../domain/game_constants.dart';
import 'maze_generator.dart';

class MazeService {
  MazeService({List<String>? mazeData, Random? rng}) : maze = mazeData ?? GameConstants.maze {
    final random = rng ?? Random();
    blockedVoidSpaces = _computeBlockedVoidSpaces(maze);
    superLogoKeys = _pickSuperLogoKeys(maze, random);
    bushes = _computeBushes(random);
  }

  final List<String> maze;
  late final Set<String> blockedVoidSpaces;
  late final Set<String> superLogoKeys;
  late final Set<String> bushes;

  bool isBush(int x, int y) => bushes.contains('$x,$y');

  int get rows => maze.length;
  int get cols => maze.first.length;

  /// Generate a fresh random map (called at the start of each round).
  static MazeService generate({int? seed}) {
    final rng = seed != null ? Random(seed) : Random();
    final data = MazeGenerator(rng: rng).generate();
    return MazeService(mazeData: data, rng: rng);
  }

  bool isWall(int x, int y) {
    if (GameConstants.tunnelRows.contains(y) && (x < 0 || x >= cols)) {
      return false;
    }
    final wrappedX = GameConstants.tunnelRows.contains(y) ? (x + cols) % cols : x;
    if (wrappedX < 0 || wrappedX >= cols) return true;
    if (y < 0 || y >= rows) return true;
    final cell = maze[y][wrappedX];
    if (cell == '#') return true;
    if (cell == ' ' && blockedVoidSpaces.contains('$wrappedX,$y')) return true;
    return false;
  }

  /// Ray-cast visibility check using DDA (Digital Differential Analysis).
  /// Works with real-world float positions, not cell centres — so visibility
  /// is accurate in open spaces and isn't limited to axis-aligned corridors.
  ///
  /// The ray steps through every wall-cell boundary it crosses and stops as
  /// soon as it enters a wall tile.  Returns true if the straight line from
  /// [a] to [b] passes through no wall tiles.
  bool hasLineOfSight(Point<double> a, Point<double> b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < 1e-6) return true;

    // Unit step sizes: how far along the ray until we cross the next
    // vertical (tDeltaX) or horizontal (tDeltaY) grid line.
    final tDeltaX = dist / dx.abs().clamp(1e-9, double.infinity);
    final tDeltaY = dist / dy.abs().clamp(1e-9, double.infinity);

    var cellX = a.x.floor();
    var cellY = a.y.floor();
    final stepX = dx >= 0 ? 1 : -1;
    final stepY = dy >= 0 ? 1 : -1;

    // Distance to the first vertical / horizontal crossing.
    var tMaxX = dx == 0
        ? double.infinity
        : (dx > 0 ? (cellX + 1 - a.x) : (a.x - cellX)) * tDeltaX;
    var tMaxY = dy == 0
        ? double.infinity
        : (dy > 0 ? (cellY + 1 - a.y) : (a.y - cellY)) * tDeltaY;

    final targetCellX = b.x.floor();
    final targetCellY = b.y.floor();

    while (true) {
      // Check the current cell (skip the cell the viewer is standing in).
      if ((cellX != a.x.floor() || cellY != a.y.floor()) && isWall(cellX, cellY)) {
        return false;
      }
      if (cellX == targetCellX && cellY == targetCellY) return true;

      if (tMaxX < tMaxY) {
        tMaxX += tDeltaX;
        cellX += stepX;
      } else {
        tMaxY += tDeltaY;
        cellY += stepY;
      }
    }
  }

  /// Small radius around the viewer where everything is always visible
  /// (used as a fallback so players can always see their immediate surroundings).
  bool hasXrayVisibility(Point<double> a, Point<double> b) {
    return (a.x - b.x).abs() <= GameConstants.xrayRadius &&
        (a.y - b.y).abs() <= GameConstants.xrayRadius;
  }

  Set<String> createLogos() {
    final startCells = GameConstants.starts.map((s) => '${s.x},${s.y}').toSet();
    final result = <String>{};
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols; x++) {
        final key = '$x,$y';
        final cell = maze[y][x];
        if (!startCells.contains(key) &&
            !bushes.contains(key) &&
            (cell == '.' || superLogoKeys.contains(key))) {
          result.add(key);
        }
      }
    }
    return result;
  }

  /// Picks 3 open corridor cells to place super logos, spread across the map.
  static Set<String> _pickSuperLogoKeys(List<String> mazeData, Random rng) {
    final h = mazeData.length;
    final w = mazeData.first.length;
    final spawns = GameConstants.starts.map((s) => '${s.x},${s.y}').toSet();

    // Divide map into 3 horizontal thirds; pick one random open cell per third.
    final result = <String>{};
    for (var third = 0; third < 3; third++) {
      final xMin = (w * third / 3).floor();
      final xMax = (w * (third + 1) / 3).floor();
      final candidates = <String>[];
      for (var y = 1; y < h - 1; y++) {
        for (var x = xMin; x < xMax; x++) {
          final key = '$x,$y';
          if (mazeData[y][x] == '.' && !spawns.contains(key)) {
            candidates.add(key);
          }
        }
      }
      if (candidates.isNotEmpty) {
        result.add(candidates[rng.nextInt(candidates.length)]);
      }
    }
    return result;
  }

  /// Grows several small bush patches on open floor, biased to cells next to
  /// walls. Avoids spawn tiles, super-logo tiles and tunnels.
  Set<String> _computeBushes(Random rng) {
    final starts = GameConstants.starts.map((s) => '${s.x},${s.y}').toSet();
    bool open(int x, int y) =>
        !GameConstants.tunnelRows.contains(y) && x >= 0 && x < cols && y >= 0 && y < rows && !isWall(x, y);
    bool allowed(int x, int y) {
      final k = '$x,$y';
      return open(x, y) && !starts.contains(k) && !superLogoKeys.contains(k);
    }
    bool nearWall(int x, int y) => isWall(x + 1, y) || isWall(x - 1, y) || isWall(x, y + 1) || isWall(x, y - 1);

    final seeds = <Point<int>>[];
    for (var y = 1; y < rows - 1; y++) {
      for (var x = 1; x < cols - 1; x++) {
        if (allowed(x, y) && nearWall(x, y)) seeds.add(Point(x, y));
      }
    }
    seeds.shuffle(rng);

    const patchCount = 8;
    final result = <String>{};
    var made = 0;
    for (final seed in seeds) {
      if (made >= patchCount) break;
      if (result.contains('${seed.x},${seed.y}')) continue;
      final target = 2 + rng.nextInt(4); // patch size 2..5
      final patch = <Point<int>>[];
      final queue = <Point<int>>[seed];
      final seen = <String>{'${seed.x},${seed.y}'};
      while (queue.isNotEmpty && patch.length < target) {
        final cell = queue.removeAt(rng.nextInt(queue.length));
        if (!allowed(cell.x, cell.y) || result.contains('${cell.x},${cell.y}')) continue;
        patch.add(cell);
        for (final d in const [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
          final nx = cell.x + d[0], ny = cell.y + d[1];
          if (seen.add('$nx,$ny') && allowed(nx, ny)) queue.add(Point(nx, ny));
        }
      }
      if (patch.isNotEmpty) {
        for (final c in patch) {
          result.add('${c.x},${c.y}');
        }
        made++;
      }
    }
    return result;
  }

  static Set<String> _computeBlockedVoidSpaces(List<String> mazeData) {
    final blocked = <String>{};
    final queue = Queue<Point<int>>();
    final h = mazeData.length;
    final w = mazeData.first.length;

    void enqueue(int x, int y) {
      if (y < 0 || y >= h || x < 0 || x >= w) return;
      final key = '$x,$y';
      if (blocked.contains(key) || GameConstants.tunnelRows.contains(y) || mazeData[y][x] != ' ') return;
      blocked.add(key);
      queue.add(Point(x, y));
    }

    for (var x = 0; x < w; x++) {
      enqueue(x, 0);
      enqueue(x, h - 1);
    }
    for (var y = 0; y < h; y++) {
      enqueue(0, y);
      enqueue(w - 1, y);
    }
    while (queue.isNotEmpty) {
      final p = queue.removeFirst();
      enqueue(p.x, p.y - 1);
      enqueue(p.x, p.y + 1);
      enqueue(p.x - 1, p.y);
      enqueue(p.x + 1, p.y);
    }
    return blocked;
  }
}
