import 'dart:collection';
import 'dart:math';

import '../domain/game_constants.dart';

/// The available map layouts. One is picked at random each round so games don't
/// always feel the same.
enum MazeStyle { pacman, spiral, waves, rooms, lattice }

/// Generates a maze in one of several styles (see [MazeStyle]).
///
/// Whatever the style carves, the generator always:
/// - keeps the outer border solid and the [GameConstants.tunnelRows] open,
/// - forces the spawn cells (from [GameConstants.starts]) open, and
/// - runs a connectivity pass so every open cell is reachable — patterns may be
///   asymmetric or organic without risking an unplayable, split map.
class MazeGenerator {
  MazeGenerator({int? cols, int? rows, int? seed, Random? rng, this.style})
      : cols = cols ?? GameConstants.mazeCols,
        rows = rows ?? GameConstants.mazeRows,
        _rng = rng ?? Random(seed);

  final int cols;
  final int rows;
  final Random _rng;

  /// Force a particular style (handy for tests); null = pick at random.
  final MazeStyle? style;

  Set<int> get _tunnelRows => GameConstants.tunnelRows;
  Set<int> get _tunnelCols => GameConstants.tunnelCols;
  int get _centre => cols ~/ 2;

  List<(int, int)> get _forceOpen =>
      GameConstants.starts.map((s) => (s.x, s.y)).toList();

  List<List<String>> _g = const [];

  bool _interior(int x, int y) =>
      x >= 1 && x < cols - 1 && y >= 1 && y < rows - 1;

  void _open(int x, int y) {
    if (_interior(x, y)) _g[y][x] = '.';
  }

  List<String> generate() {
    _g = List.generate(rows, (_) => List.filled(cols, '#'));
    final chosen =
        style ?? MazeStyle.values[_rng.nextInt(MazeStyle.values.length)];

    switch (chosen) {
      case MazeStyle.pacman:
        _carvePacman();
      case MazeStyle.spiral:
        _carveSpiral();
      case MazeStyle.waves:
        _carveWaves();
      case MazeStyle.rooms:
        _carveRooms();
      case MazeStyle.lattice:
        _carveLattice();
    }

    _applyTunnelRows();
    _applyTunnelCols();
    _forceOpenSpawns();
    _thickenOpenAreas(); // break wide-open plazas into corridors
    _removeLonePillars(); // clear most scattered single-cell rocks
    _addLoops(); // braid in a few extra passages so it isn't all dead-ends
    _connectAll(); // guarantee every open cell is reachable
    _applyBorder();
    _reopenTunnelExits();

    return _g.map((row) => row.join()).toList();
  }

  // ── Style: Pac-Man (symmetric recursive backtracker) ────────────────────────

  void _carvePacman() {
    const leftEdge = 1;
    final rightEdge = _centre - 1;
    const topEdge = 1;
    final bottomEdge = rows - 2;

    final cellW = ((rightEdge - leftEdge) ~/ 2) + 1;
    final cellH = ((bottomEdge - topEdge) ~/ 2) + 1;
    final visited = List.generate(cellH, (_) => List.filled(cellW, false));

    void carve(int cx, int cy) {
      visited[cy][cx] = true;
      final mx = leftEdge + cx * 2;
      final my = topEdge + cy * 2;
      _open(mx, my);
      final dirs = [0, 1, 2, 3]..shuffle(_rng);
      for (final d in dirs) {
        final dx = const [0, 0, -1, 1][d];
        final dy = const [-1, 1, 0, 0][d];
        final nx = cx + dx, ny = cy + dy;
        if (nx < 0 || nx >= cellW || ny < 0 || ny >= cellH) continue;
        if (visited[ny][nx]) continue;
        _open(mx + dx, my + dy);
        carve(nx, ny);
      }
    }

    carve(0, 0);

    for (var cy = 0; cy < cellH; cy++) {
      for (var cx = 0; cx < cellW; cx++) {
        final mx = leftEdge + cx * 2;
        final my = topEdge + cy * 2;
        if (cx + 1 < cellW && _rng.nextDouble() < 0.30) _open(mx + 1, my);
        if (cy + 1 < cellH && _rng.nextDouble() < 0.30) _open(mx, my + 1);
      }
    }
    for (var y = topEdge; y <= bottomEdge; y++) {
      if (_g[y][_centre - 1] == '.') _g[y][_centre] = '.';
    }
    // Mirror the carved left half onto the right.
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < cols ~/ 2; x++) {
        _g[y][cols - 1 - x] = _g[y][x];
      }
    }
  }

  // ── Style: Spiral (concentric rings linked into one inward spiral) ───────────

  void _carveSpiral() {
    var t = 1, l = 1, b = rows - 2, r = cols - 2;
    var ring = 0;
    while (l <= r && t <= b) {
      for (var x = l; x <= r; x++) {
        _open(x, t);
        _open(x, b);
      }
      for (var y = t; y <= b; y++) {
        _open(l, y);
        _open(r, y);
      }
      // Doorway to the next inner ring; the side rotates so the path spirals.
      final hasInner = (l + 2 <= r - 2) && (t + 2 <= b - 2);
      if (hasInner) {
        final midX = (l + r) ~/ 2;
        final midY = (t + b) ~/ 2;
        switch (ring % 4) {
          case 0:
            _open(l + 1, midY); // link to inner ring through the left wall
          case 1:
            _open(midX, t + 1); // through the top wall
          case 2:
            _open(r - 1, midY); // through the right wall
          case 3:
            _open(midX, b - 1); // through the bottom wall
        }
      }
      t += 2;
      l += 2;
      b -= 2;
      r -= 2;
      ring++;
    }
  }

  // ── Style: Waves (sine corridors crossed by vertical streets) ────────────────

  void _carveWaves() {
    final freq = 0.40 + _rng.nextDouble() * 0.35;
    final amp = 1.5 + _rng.nextDouble() * 2.0;
    final phase = _rng.nextDouble() * pi * 2;

    for (var base = 3; base < rows - 2; base += 4) {
      var prevY = -1;
      for (var x = 1; x < cols - 1; x++) {
        final y = (base + amp * sin(x * freq + phase))
            .round()
            .clamp(1, rows - 2);
        // Fill the vertical gap to the previous column so the wave stays one
        // continuous corridor even where it climbs or dips quickly.
        if (prevY != -1) {
          final lo = min(prevY, y), hi = max(prevY, y);
          for (var yy = lo; yy <= hi; yy++) {
            _open(x, yy);
          }
        }
        _open(x, y);
        prevY = y;
      }
    }
    // Vertical streets stitch the wave bands together.
    final firstStreet = 2 + _rng.nextInt(2);
    for (var x = firstStreet; x < cols - 1; x += 4 + _rng.nextInt(2)) {
      for (var y = 1; y < rows - 1; y++) {
        _open(x, y);
      }
    }
  }

  // ── Style: Rooms (random rectangular rooms joined by corridors) ──────────────

  void _carveRooms() {
    final centres = <Point<int>>[];
    final count = 7 + _rng.nextInt(4);
    var attempts = 0;
    while (centres.length < count && attempts < 80) {
      attempts++;
      final w = 2 + _rng.nextInt(3);
      final h = 2 + _rng.nextInt(3);
      final x = 1 + _rng.nextInt(max(1, cols - 2 - w));
      final y = 1 + _rng.nextInt(max(1, rows - 2 - h));
      for (var yy = y; yy < y + h && yy < rows - 1; yy++) {
        for (var xx = x; xx < x + w && xx < cols - 1; xx++) {
          _open(xx, yy);
        }
      }
      centres.add(Point(x + w ~/ 2, y + h ~/ 2));
    }
    // Connect each room to the previous one, plus an extra link to a random
    // earlier room so the layout loops instead of being a single chain.
    for (var i = 1; i < centres.length; i++) {
      _carveCorridor(centres[i - 1], centres[i]);
      if (i >= 2 && _rng.nextBool()) {
        _carveCorridor(centres[i], centres[_rng.nextInt(i - 1)]);
      }
    }
    // Also tie the spawns into the nearest room so nobody starts boxed in.
    for (final (sx, sy) in _forceOpen) {
      if (centres.isEmpty) break;
      centres.sort((a, b) =>
          ((a.x - sx).abs() + (a.y - sy).abs()) -
          ((b.x - sx).abs() + (b.y - sy).abs()));
      _carveCorridor(Point(sx, sy), centres.first);
    }
  }

  void _carveCorridor(Point<int> a, Point<int> b) {
    final hFirst = _rng.nextBool();
    if (hFirst) {
      for (var x = min(a.x, b.x); x <= max(a.x, b.x); x++) {
        _open(x, a.y);
      }
      for (var y = min(a.y, b.y); y <= max(a.y, b.y); y++) {
        _open(b.x, y);
      }
    } else {
      for (var y = min(a.y, b.y); y <= max(a.y, b.y); y++) {
        _open(a.x, y);
      }
      for (var x = min(a.x, b.x); x <= max(a.x, b.x); x++) {
        _open(x, b.y);
      }
    }
  }

  // ── Style: Lattice (woven diagonal corridors around diamond pillars) ─────────

  void _carveLattice() {
    // Two families of *2-wide* diagonal bands cross to weave an argyle grid:
    // open, navigable corridors with diamond-shaped wall pillars between them.
    // Wider than the old 1-cell weave so Leha isn't boxed in.
    final period = 4 + _rng.nextInt(2); // 4 or 5
    const bandWidth = 2;
    for (var y = 1; y < rows - 1; y++) {
      for (var x = 1; x < cols - 1; x++) {
        final down = (x + y) % period; // ╲ bands
        final up = (x - y) % period + period; // ╱ bands (kept non-negative)
        if (down < bandWidth || up % period < bandWidth) _open(x, y);
      }
    }
  }

  // ── Shared finishing passes ─────────────────────────────────────────────────

  void _applyTunnelRows() {
    for (final row in _tunnelRows) {
      if (row < 0 || row >= rows) continue;
      for (var x = 0; x < cols; x++) {
        _g[row][x] = (x == 0 || x == cols - 1) ? ' ' : '.';
      }
    }
  }

  void _applyTunnelCols() {
    for (final col in _tunnelCols) {
      if (col < 0 || col >= cols) continue;
      for (var y = 0; y < rows; y++) {
        _g[y][col] = (y == 0 || y == rows - 1) ? ' ' : '.';
      }
    }
  }

  void _forceOpenSpawns() {
    for (final (x, y) in _forceOpen) {
      if (x >= 0 && x < cols && y >= 0 && y < rows) _g[y][x] = '.';
      for (final (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        _open(x + dx, y + dy);
      }
    }
  }

  /// Breaks up wide-open plazas: any interior open cell whose entire 3x3
  /// neighbourhood is open gets re-walled with a moderate chance, carving big
  /// rooms into more deliberate corridors. [_connectAll] later repairs any split.
  void _thickenOpenAreas() {
    for (var y = 2; y < rows - 2; y++) {
      if (_tunnelRows.contains(y)) continue;
      for (var x = 2; x < cols - 2; x++) {
        if (_tunnelCols.contains(x)) continue;
        if (_g[y][x] != '.') continue;
        if (_forceOpen.any((s) => s.$1 == x && s.$2 == y)) continue;
        var allOpen = true;
        for (var dy = -1; dy <= 1 && allOpen; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            if (_g[y + dy][x + dx] != '.') {
              allOpen = false;
              break;
            }
          }
        }
        if (allOpen && _rng.nextDouble() < 0.40) _g[y][x] = '#';
      }
    }
  }

  /// Clears most lone pillars — single wall cells open on all four sides — which
  /// otherwise read as scattered rocks. A few are kept for variety.
  void _removeLonePillars() {
    for (var y = 1; y < rows - 1; y++) {
      if (_tunnelRows.contains(y)) continue;
      for (var x = 1; x < cols - 1; x++) {
        if (_tunnelCols.contains(x)) continue;
        if (_g[y][x] != '#') continue;
        final lone = _g[y][x - 1] == '.' &&
            _g[y][x + 1] == '.' &&
            _g[y - 1][x] == '.' &&
            _g[y + 1][x] == '.';
        if (lone && _rng.nextDouble() < 0.60) _g[y][x] = '.';
      }
    }
  }

  /// Opens up the map so Leha always has escape routes: knocks down a good
  /// fraction of interior walls that sit between two open cells (creating loops
  /// and through-passages), then drills out the worst dead-end pockets.
  void _addLoops() {
    for (var y = 1; y < rows - 1; y++) {
      if (_tunnelRows.contains(y)) continue;
      for (var x = 1; x < cols - 1; x++) {
        if (_g[y][x] != '#') continue;
        final horiz = _g[y][x - 1] == '.' && _g[y][x + 1] == '.';
        final vert = _g[y - 1][x] == '.' && _g[y + 1][x] == '.';
        // Lighter braiding keeps corridors longer and narrower.
        if ((horiz || vert) && _rng.nextDouble() < 0.12) _g[y][x] = '.';
      }
    }
    _breakDeadEnds();
  }

  /// A dead-end (open cell with a single open neighbour) is a death trap for
  /// Leha. Punch a second exit so most pockets become through-corridors.
  void _breakDeadEnds() {
    for (var y = 1; y < rows - 1; y++) {
      if (_tunnelRows.contains(y)) continue;
      for (var x = 1; x < cols - 1; x++) {
        if (_g[y][x] != '.' || _tunnelCols.contains(x)) continue;
        final dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];
        final openNbrs = dirs.where((d) => _g[y + d.$2][x + d.$1] == '.').length;
        if (openNbrs > 1) continue; // not a dead-end
        if (_rng.nextDouble() > 0.75) continue; // leave a few for variety
        // Punch through a wall neighbour that leads to another open cell.
        final candidates = dirs.where((d) {
          final wx = x + d.$1, wy = y + d.$2;
          if (_g[wy][wx] != '#' || !_interior(wx, wy)) return false;
          final fx = wx + d.$1, fy = wy + d.$2;
          return _interior(fx, fy) && _g[fy][fx] == '.';
        }).toList();
        if (candidates.isEmpty) continue;
        final d = candidates[_rng.nextInt(candidates.length)];
        _g[y + d.$2][x + d.$1] = '.';
      }
    }
  }

  /// Guarantees one connected open region: floods from a spawn, then drills the
  /// shortest wall path from any stranded open cell back to the reachable set,
  /// repeating until nothing is left isolated.
  void _connectAll() {
    final (seedX, seedY) = _forceOpen.first;
    while (true) {
      final reachable = _flood(seedX, seedY);
      Point<int>? stranded;
      outer:
      for (var y = 1; y < rows - 1; y++) {
        for (var x = 1; x < cols - 1; x++) {
          if (_g[y][x] == '.' && !reachable.contains(y * cols + x)) {
            stranded = Point(x, y);
            break outer;
          }
        }
      }
      if (stranded == null) break;
      _drillToReachable(stranded, reachable);
    }
  }

  Set<int> _flood(int sx, int sy) {
    final seen = <int>{};
    final queue = Queue<Point<int>>();
    void add(int x, int y) {
      if (!_interior(x, y) || _g[y][x] != '.') return;
      if (seen.add(y * cols + x)) queue.add(Point(x, y));
    }

    add(sx, sy);
    while (queue.isNotEmpty) {
      final p = queue.removeFirst();
      add(p.x + 1, p.y);
      add(p.x - 1, p.y);
      add(p.x, p.y + 1);
      add(p.x, p.y - 1);
    }
    return seen;
  }

  /// BFS through *all* interior cells from [from] until it hits a cell already
  /// in [reachable]; carves every cell on that shortest path open.
  void _drillToReachable(Point<int> from, Set<int> reachable) {
    final prev = <int, int>{};
    final seen = <int>{from.y * cols + from.x};
    final queue = Queue<Point<int>>()..add(from);
    Point<int>? hit;
    while (queue.isNotEmpty) {
      final p = queue.removeFirst();
      if (reachable.contains(p.y * cols + p.x)) {
        hit = p;
        break;
      }
      for (final (dx, dy) in [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final nx = p.x + dx, ny = p.y + dy;
        if (!_interior(nx, ny)) continue;
        final id = ny * cols + nx;
        if (seen.add(id)) {
          prev[id] = p.y * cols + p.x;
          queue.add(Point(nx, ny));
        }
      }
    }
    if (hit == null) return;
    var cur = hit.y * cols + hit.x;
    while (true) {
      _g[cur ~/ cols][cur % cols] = '.';
      final p = prev[cur];
      if (p == null) break;
      cur = p;
    }
  }

  void _applyBorder() {
    for (var x = 0; x < cols; x++) {
      if (_tunnelCols.contains(x)) continue; // vertical tunnel exits stay ' '
      _g[0][x] = '#';
      _g[rows - 1][x] = '#';
    }
    for (var y = 1; y < rows - 1; y++) {
      if (_tunnelRows.contains(y)) continue;
      _g[y][0] = '#';
      _g[y][cols - 1] = '#';
    }
  }

  void _reopenTunnelExits() {
    for (final row in _tunnelRows) {
      if (row < 0 || row >= rows) continue;
      _g[row][0] = ' ';
      _g[row][cols - 1] = ' ';
    }
    for (final col in _tunnelCols) {
      if (col < 0 || col >= cols) continue;
      _g[0][col] = ' ';
      _g[rows - 1][col] = ' ';
    }
  }
}
