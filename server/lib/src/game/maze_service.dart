import 'dart:collection';
import 'dart:math';

import 'package:leha_bald_shared/leha_bald_shared.dart';

import '../domain/game_constants.dart';
import 'maze_generator.dart';

class MazeService {
  MazeService({List<String>? mazeData, Random? rng, Set<CaveBiome>? biomes})
      : maze = mazeData ?? GameConstants.maze {
    final random = rng ?? Random();
    final allowed = (biomes == null || biomes.isEmpty)
        ? CaveBiome.values
        : CaveBiome.values.where(biomes.contains).toList();
    biome = allowed[random.nextInt(allowed.length)];
    stoneSeed = random.nextInt(1 << 31);
    blockedVoidSpaces = _computeBlockedVoidSpaces(maze);
    superLogoKeys = _pickSuperLogoKeys(maze, random);
    crackedWalls = _computeCrackedWalls(random);
    // Special biomes swap ordinary cover for their own entities.
    if (biome == CaveBiome.frost) {
      crystals = _computeCrystals(random);
      bushes = const {};
      sarcophagi = const {};
      quicksand = const {};
      amethystShards = const {};
    } else if (biome == CaveBiome.sandstone) {
      sarcophagi = _computeSarcophagi(random);
      quicksand = _computeQuicksand(random);
      bushes = const {};
      crystals = const {};
      amethystShards = const {};
    } else if (biome == CaveBiome.amethyst) {
      // Amethyst grows a live mushroom colony (dynamic, in round state) instead
      // of static bushes, plus scatter shards that ring out when stepped on.
      amethystShards = _computeAmethystShards(random);
      bushes = const {};
      crystals = const {};
      sarcophagi = const {};
      quicksand = const {};
    } else {
      bushes = _computeBushes(random);
      crystals = const {};
      sarcophagi = const {};
      quicksand = const {};
      amethystShards = const {};
    }
  }

  /// Cosmetic theme + stone-colour seed for this map (sent to clients).
  late final CaveBiome biome;
  late final int stoneSeed;

  /// Ice-biome crystal cells (empty for other biomes).
  late final Set<String> crystals;

  /// Sandstone-biome mummy-lair cells: the sandstone wall blocks a mummy
  /// starts sealed inside (empty for other biomes).
  late final Set<String> sarcophagi;

  /// Sandstone-biome quicksand cells that slow movement (empty otherwise).
  late final Set<String> quicksand;

  /// Amethyst-biome scatter-shard cells (empty otherwise).
  late final Set<String> amethystShards;

  /// Dynamic concealing cells updated each tick by the engine (amethyst spores).
  /// Treated like bushes for line-of-sight and visibility.
  final Set<String> dynamicCover = {};

  final List<String> maze;
  late final Set<String> blockedVoidSpaces;
  late final Set<String> superLogoKeys;
  late final Set<String> bushes;

  /// Wall cells the Spider may web through — the only legal web locations.
  late final Set<String> crackedWalls;

  bool isBush(int x, int y) => bushes.contains('$x,$y');

  bool isQuicksand(int x, int y) => quicksand.contains('$x,$y');

  bool isAmethystShard(int x, int y) => amethystShards.contains('$x,$y');

  /// A dynamic spore/fog cell (amethyst). Slows movement; conceals via [conceals].
  bool isSpore(int x, int y) => dynamicCover.contains('$x,$y');

  /// Any cell that conceals players from sight — static bushes or live spores.
  bool conceals(int x, int y) => isBush(x, y) || isSpore(x, y);

  bool isCrackedWall(int x, int y) => crackedWalls.contains('$x,$y');

  /// Picks a small set of single-thickness interior walls (open floor on two
  /// opposite sides) as the Spider's web-able "cracked" walls.
  Set<String> _computeCrackedWalls(Random rng) {
    final candidates = <String>[];
    for (var y = 1; y < rows - 1; y++) {
      for (var x = 1; x < cols - 1; x++) {
        if (!isWall(x, y)) continue;
        if (GameConstants.tunnelRows.contains(y)) continue;
        final horiz = !isWall(x - 1, y) && !isWall(x + 1, y);
        final vert = !isWall(x, y - 1) && !isWall(x, y + 1);
        // Exactly one axis open keeps it a clean shortcut through a thin wall.
        if (horiz != vert) candidates.add('$x,$y');
      }
    }
    candidates.shuffle(rng);
    return candidates.take(GameConstants.crackedWallCount).toSet();
  }

  int get rows => maze.length;
  int get cols => maze.first.length;

  /// Generate a fresh random map (called at the start of each round).
  /// [biomes], when given, restricts the cosmetic biome to that set.
  static MazeService generate({int? seed, Set<CaveBiome>? biomes}) {
    final rng = seed != null ? Random(seed) : Random();
    final data = MazeGenerator(rng: rng).generate();
    return MazeService(mazeData: data, rng: rng, biomes: biomes);
  }

  /// Scatters [GameConstants.crystalSpots] clusters of 1-2 crystals on open
  /// floor (away from spawns, walls and tunnels).
  Set<String> _computeCrystals(Random rng) {
    final starts = GameConstants.starts.map((s) => '${s.x},${s.y}').toSet();
    final open = <Point<int>>[];
    for (var y = 1; y < rows - 1; y++) {
      if (GameConstants.tunnelRows.contains(y)) continue;
      for (var x = 1; x < cols - 1; x++) {
        if (GameConstants.tunnelCols.contains(x)) continue;
        final key = '$x,$y';
        if (isWall(x, y) || starts.contains(key)) continue;
        open.add(Point(x, y));
      }
    }
    open.shuffle(rng);
    final result = <String>{};
    var spots = 0;
    for (final cell in open) {
      if (spots >= GameConstants.crystalSpots) break;
      final key = '${cell.x},${cell.y}';
      if (result.contains(key)) continue;
      result.add(key);
      spots++;
      // 50% chance of a second crystal in an adjacent open cell.
      if (rng.nextBool()) {
        final dirs = [
          const Point(1, 0),
          const Point(-1, 0),
          const Point(0, 1),
          const Point(0, -1)
        ]..shuffle(rng);
        for (final d in dirs) {
          final nx = cell.x + d.x, ny = cell.y + d.y;
          final nk = '$nx,$ny';
          if (nx > 0 &&
              nx < cols - 1 &&
              ny > 0 &&
              ny < rows - 1 &&
              !isWall(nx, ny) &&
              !result.contains(nk) &&
              !starts.contains(nk)) {
            result.add(nk);
            break;
          }
        }
      }
    }
    return result;
  }

  /// Picks the sandstone wall blocks that start with a mummy sealed inside.
  /// Every block on the desert map is sandstone, so any interior wall cell that
  /// borders open floor (so a player can approach and flush the mummy out) is a
  /// valid lair.
  Set<String> _computeSarcophagi(Random rng) {
    final walls = sandstoneWalls()..shuffle(rng);
    return walls
        .take(GameConstants.sarcophagusCount)
        .map((p) => '${p.x},${p.y}')
        .toSet();
  }

  /// Scatters [GameConstants.amethystShardCount] single shard cells on open
  /// floor, away from spawns and tunnels.
  Set<String> _computeAmethystShards(Random rng) {
    final starts = GameConstants.starts.map((s) => '${s.x},${s.y}').toSet();
    final open = <Point<int>>[];
    for (var y = 1; y < rows - 1; y++) {
      if (GameConstants.tunnelRows.contains(y)) continue;
      for (var x = 1; x < cols - 1; x++) {
        if (GameConstants.tunnelCols.contains(x)) continue;
        final key = '$x,$y';
        if (isWall(x, y) || starts.contains(key)) continue;
        open.add(Point(x, y));
      }
    }
    open.shuffle(rng);
    return open
        .take(GameConstants.amethystShardCount)
        .map((p) => '${p.x},${p.y}')
        .toSet();
  }

  /// Grows [GameConstants.quicksandSpots] small quicksand patches on open floor,
  /// away from spawns and tunnels. Each seed expands into a 2-5 cell blob so the
  /// hazard reads as a pool rather than scattered single tiles.
  Set<String> _computeQuicksand(Random rng) {
    final starts = GameConstants.starts.map((s) => '${s.x},${s.y}').toSet();
    bool open(int x, int y) =>
        !GameConstants.tunnelRows.contains(y) &&
        !GameConstants.tunnelCols.contains(x) &&
        x > 0 &&
        x < cols - 1 &&
        y > 0 &&
        y < rows - 1 &&
        !isWall(x, y);
    bool allowed(int x, int y) => open(x, y) && !starts.contains('$x,$y');

    final seeds = <Point<int>>[];
    for (var y = 1; y < rows - 1; y++) {
      for (var x = 1; x < cols - 1; x++) {
        if (allowed(x, y)) seeds.add(Point(x, y));
      }
    }
    seeds.shuffle(rng);

    final result = <String>{};
    var made = 0;
    for (final seed in seeds) {
      if (made >= GameConstants.quicksandSpots) break;
      if (result.contains('${seed.x},${seed.y}')) continue;
      final target = 2 + rng.nextInt(4); // patch size 2..5
      final patch = <Point<int>>[];
      final queue = <Point<int>>[seed];
      final seen = <String>{'${seed.x},${seed.y}'};
      while (queue.isNotEmpty && patch.length < target) {
        final cell = queue.removeAt(rng.nextInt(queue.length));
        if (!allowed(cell.x, cell.y) || result.contains('${cell.x},${cell.y}')) {
          continue;
        }
        patch.add(cell);
        for (final d in const [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1]
        ]) {
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

  /// Interior sandstone (`#`) wall cells that border at least one open cell —
  /// the blocks a mummy can dive into, and that a player can walk up to in
  /// order to flush a hidden mummy back out.
  List<Point<int>> sandstoneWalls() {
    final result = <Point<int>>[];
    for (var y = 1; y < rows - 1; y++) {
      if (GameConstants.tunnelRows.contains(y)) continue;
      for (var x = 1; x < cols - 1; x++) {
        if (GameConstants.tunnelCols.contains(x)) continue;
        if (maze[y][x] != '#') continue;
        final bordersFloor = !isWall(x - 1, y) ||
            !isWall(x + 1, y) ||
            !isWall(x, y - 1) ||
            !isWall(x, y + 1);
        if (bordersFloor) result.add(Point(x, y));
      }
    }
    return result;
  }

  /// Carves a sandstone block back to open floor: when a mummy climbs out of a
  /// wall, that block is destroyed for the rest of the round.
  void destroyWall(int x, int y) {
    if (y < 0 || y >= rows || x < 0 || x >= cols) return;
    final row = maze[y];
    if (x >= row.length || row[x] != '#') return;
    maze[y] = '${row.substring(0, x)}.${row.substring(x + 1)}';
  }

  bool isWall(int x, int y) {
    final inRow = GameConstants.tunnelRows.contains(y);
    final inCol = GameConstants.tunnelCols.contains(x);
    // Stepping out of a tunnel's far edge is open ground (the player wraps).
    if (inRow && (x < 0 || x >= cols)) return false;
    if (inCol && (y < 0 || y >= rows)) return false;
    final wrappedX = inRow ? (x + cols) % cols : x;
    final wrappedY = inCol ? (y + rows) % rows : y;
    if (wrappedX < 0 || wrappedX >= cols) return true;
    if (wrappedY < 0 || wrappedY >= rows) return true;
    final cell = maze[wrappedY][wrappedX];
    if (cell == '#') return true;
    if (cell == ' ' && blockedVoidSpaces.contains('$wrappedX,$wrappedY')) {
      return true;
    }
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
      final isViewerCell = cellX == a.x.floor() && cellY == a.y.floor();
      // Walls block sight (skip the cell the viewer is standing in).
      if (!isViewerCell && isWall(cellX, cellY)) return false;
      if (cellX == targetCellX && cellY == targetCellY) return true;
      // Cover conceals everything behind it: an intermediate bush or spore patch
      // blocks the ray (the target cell itself is allowed through above, handled
      // by callers).
      if (!isViewerCell && conceals(cellX, cellY)) return false;

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
        !GameConstants.tunnelRows.contains(y) &&
        !GameConstants.tunnelCols.contains(x) &&
        x >= 0 &&
        x < cols &&
        y >= 0 &&
        y < rows &&
        !isWall(x, y);
    bool allowed(int x, int y) {
      final k = '$x,$y';
      return open(x, y) && !starts.contains(k) && !superLogoKeys.contains(k);
    }

    bool nearWall(int x, int y) =>
        isWall(x + 1, y) ||
        isWall(x - 1, y) ||
        isWall(x, y + 1) ||
        isWall(x, y - 1);

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
        if (!allowed(cell.x, cell.y) || result.contains('${cell.x},${cell.y}')) {
          continue;
        }
        patch.add(cell);
        for (final d in const [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1]
        ]) {
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
      if (blocked.contains(key) ||
          GameConstants.tunnelRows.contains(y) ||
          GameConstants.tunnelCols.contains(x) ||
          mazeData[y][x] != ' ') {
        return;
      }
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
