import 'dart:math';

import '../domain/game_constants.dart';

/// Generates a Pac-Man-style symmetric maze.
///
/// - [cols] × [rows] (both odd), outer border always solid.
/// - Left half (cols 1..centre-1) generated with a recursive-backtracker on a
///   2×2 cell grid; the centre axis and right half are mirrored.
/// - The [GameConstants.tunnelRows] are open side-tunnels (border cells = ' ').
/// - Spawn cells (from [GameConstants.starts]) are forced open.
class MazeGenerator {
  MazeGenerator({int? cols, int? rows, int? seed, Random? rng})
      : cols = cols ?? GameConstants.mazeCols,
        rows = rows ?? GameConstants.mazeRows,
        _rng = rng ?? Random(seed);

  final int cols;
  final int rows;
  final Random _rng;

  Set<int> get _tunnelRows => GameConstants.tunnelRows;
  int get _centre => cols ~/ 2;

  /// Cells that must stay open (spawns) plus a symmetric cross around each.
  List<(int, int)> get _forceOpen =>
      GameConstants.starts.map((s) => (s.x, s.y)).toList();

  List<String> generate() {
    // Internal grid as a 2-D list of chars; (x, y).
    final g = List.generate(rows, (_) => List.filled(cols, '#'));

    _carvePacmanMaze(g);
    _mirrorHorizontally(g);
    _applyTunnelRows(g);
    _applyBorder(g);
    _forceOpenSpawns(g);

    return g.map((row) => row.join()).toList();
  }

  // ── Carving ────────────────────────────────────────────────────────────────

  void _carvePacmanMaze(List<List<String>> g) {
    // Left half: cols 1..centre-1 (col 0 = border, col centre = mirror axis).
    // Cell grid: step 2 starting at (1,1).
    const leftEdge = 1; // first carveable col
    final rightEdge = _centre - 1; // last carveable col on left half
    const topEdge = 1;
    final bottomEdge = rows - 2;

    final cellW = ((rightEdge - leftEdge) ~/ 2) + 1;
    final cellH = ((bottomEdge - topEdge) ~/ 2) + 1;

    final visited = List.generate(cellH, (_) => List.filled(cellW, false));

    void open(int x, int y) {
      if (x >= leftEdge && x <= rightEdge && y >= topEdge && y <= bottomEdge) {
        g[y][x] = '.';
      }
    }

    void carve(int cx, int cy) {
      visited[cy][cx] = true;
      final mx = leftEdge + cx * 2;
      final my = topEdge + cy * 2;
      open(mx, my);

      final dirs = [0, 1, 2, 3]..shuffle(_rng);
      for (final d in dirs) {
        final dx = const [0, 0, -1, 1][d];
        final dy = const [-1, 1, 0, 0][d];
        final nx = cx + dx, ny = cy + dy;
        if (nx < 0 || nx >= cellW || ny < 0 || ny >= cellH) continue;
        if (visited[ny][nx]) continue;
        // Carve the wall between the two cells.
        open(mx + dx, my + dy);
        carve(nx, ny);
      }
    }

    carve(0, 0);

    // Extra passages to reduce dead-ends (pac-man feel).
    for (var cy = 0; cy < cellH; cy++) {
      for (var cx = 0; cx < cellW; cx++) {
        final mx = leftEdge + cx * 2;
        final my = topEdge + cy * 2;
        // Knock wall right.
        if (cx + 1 < cellW && _rng.nextDouble() < 0.30) open(mx + 1, my);
        // Knock wall down.
        if (cy + 1 < cellH && _rng.nextDouble() < 0.30) open(mx, my + 1);
      }
    }

    // Centre column: open wherever the neighbouring left column is open.
    for (var y = topEdge; y <= bottomEdge; y++) {
      if (g[y][_centre - 1] == '.') g[y][_centre] = '.';
    }
  }

  // ── Mirror ─────────────────────────────────────────────────────────────────

  void _mirrorHorizontally(List<List<String>> g) {
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols ~/ 2; x++) {
        g[y][cols - 1 - x] = g[y][x];
      }
    }
  }

  // ── Tunnel rows ─────────────────────────────────────────────────────────────

  void _applyTunnelRows(List<List<String>> g) {
    for (final row in _tunnelRows) {
      if (row < 0 || row >= rows) continue;
      for (var x = 0; x < cols; x++) {
        g[row][x] = (x == 0 || x == cols - 1) ? ' ' : '.';
      }
    }
  }

  // ── Border ──────────────────────────────────────────────────────────────────

  void _applyBorder(List<List<String>> g) {
    for (var x = 0; x < cols; x++) {
      g[0][x] = '#';
      g[rows - 1][x] = '#';
    }
    for (var y = 1; y < rows - 1; y++) {
      if (_tunnelRows.contains(y)) continue; // tunnel exits stay ' '
      g[y][0] = '#';
      g[y][cols - 1] = '#';
    }
  }

  // ── Force-open spawns ────────────────────────────────────────────────────────

  void _forceOpenSpawns(List<List<String>> g) {
    for (final (x, y) in _forceOpen) {
      if (x >= 0 && x < cols && y >= 0 && y < rows) g[y][x] = '.';
      // Carve a small cross so the player is never enclosed.
      for (final (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final nx = x + dx, ny = y + dy;
        if (nx > 0 && nx < cols - 1 && ny > 0 && ny < rows - 1 &&
            !_tunnelRows.contains(ny)) {
          g[ny][nx] = '.';
        }
      }
    }
    // Re-mirror so forced-open cells stay symmetric.
    _mirrorHorizontally(g);

    // Re-apply tunnel border exits (mirroring may have overwritten ' ').
    for (final row in _tunnelRows) {
      if (row < 0 || row >= rows) continue;
      g[row][0] = ' ';
      g[row][cols - 1] = ' ';
    }

    // Re-apply border walls over the mirrored result.
    _applyBorder(g);
  }
}
