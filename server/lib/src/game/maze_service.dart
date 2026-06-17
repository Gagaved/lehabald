import 'dart:collection';
import 'dart:math';

import '../domain/game_constants.dart';
import 'maze_generator.dart';

class MazeService {
  MazeService({List<String>? mazeData})
      : maze = mazeData ?? GameConstants.maze,
        blockedVoidSpaces = _computeBlockedVoidSpaces(mazeData ?? GameConstants.maze);

  final List<String> maze;
  final Set<String> blockedVoidSpaces;

  int get rows => maze.length;
  int get cols => maze.first.length;

  /// Generate a fresh random map (called at the start of each round).
  static MazeService generate({int? seed}) {
    final data = MazeGenerator(seed: seed).generate();
    return MazeService(mazeData: data);
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

  bool hasLineOfSight(Point<int> a, Point<int> b) {
    if (a.y == b.y) {
      for (var x = min(a.x, b.x) + 1; x < max(a.x, b.x); x += 1) {
        if (isWall(x, a.y)) return false;
      }
      return true;
    }
    if (a.x == b.x) {
      for (var y = min(a.y, b.y) + 1; y < max(a.y, b.y); y += 1) {
        if (isWall(a.x, y)) return false;
      }
      return true;
    }
    return false;
  }

  bool hasXrayVisibility(Point<int> a, Point<int> b) {
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
        if (!startCells.contains(key) && (cell == '.' || GameConstants.superLogoKeys.contains(key))) {
          result.add(key);
        }
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
