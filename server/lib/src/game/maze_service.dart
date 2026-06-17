import 'dart:collection';
import 'dart:math';

import '../domain/game_constants.dart';

class MazeService {
  MazeService() : blockedVoidSpaces = _createBlockedVoidSpaces();

  final Set<String> blockedVoidSpaces;

  int get rows => GameConstants.maze.length;
  int get cols => GameConstants.maze.first.length;

  bool isWall(int x, int y) {
    if (GameConstants.tunnelRows.contains(y) && (x < 0 || x >= cols)) {
      return false;
    }
    final wrappedX = GameConstants.tunnelRows.contains(y) ? (x + cols) % cols : x;
    if (wrappedX < 0 || wrappedX >= cols) return true;
    if (y < 0 || y >= rows) return true;
    final cell = GameConstants.maze[y][wrappedX];
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
    final startCells = GameConstants.starts.map((start) => '${start.x},${start.y}').toSet();
    final result = <String>{};
    for (var y = 0; y < rows; y += 1) {
      for (var x = 0; x < cols; x += 1) {
        final key = '$x,$y';
        final cell = GameConstants.maze[y][x];
        if (!startCells.contains(key) && (cell == '.' || GameConstants.superLogoKeys.contains(key))) {
          result.add(key);
        }
      }
    }
    return result;
  }

  static Set<String> _createBlockedVoidSpaces() {
    final blocked = <String>{};
    final queue = Queue<Point<int>>();

    void enqueue(int x, int y) {
      if (y < 0 || y >= GameConstants.maze.length) return;
      if (x < 0 || x >= GameConstants.maze.first.length) return;
      final key = '$x,$y';
      if (blocked.contains(key) || GameConstants.tunnelRows.contains(y) || GameConstants.maze[y][x] != ' ') {
        return;
      }
      blocked.add(key);
      queue.add(Point(x, y));
    }

    for (var x = 0; x < GameConstants.maze.first.length; x += 1) {
      enqueue(x, 0);
      enqueue(x, GameConstants.maze.length - 1);
    }
    for (var y = 0; y < GameConstants.maze.length; y += 1) {
      enqueue(0, y);
      enqueue(GameConstants.maze.first.length - 1, y);
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
