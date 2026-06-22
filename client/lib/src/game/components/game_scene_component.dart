part of '../leha_bald_game.dart';

/// Screen-space root for the game board.
///
/// The server owns gameplay state; this component turns each snapshot into a
/// Flame component tree. Keeping the board transform here means children use
/// world-sized coordinates and never need to know about phone aspect ratios or
/// the Flutter HUD inset.
class _GameSceneComponent extends PositionComponent
    with
        HasGameReference<LehaBaldGame>,
        HasVisibility,
        PointerMoveCallbacks,
        DragCallbacks,
        TapCallbacks {
  _GameSceneComponent() : super(priority: 10);

  late final _PortalLayerComponent portalLayer;
  late final _TrapLayerComponent trapLayer;
  late final _WebLayerComponent webLayer;
  late final _TargetingPreviewComponent targetingPreview;
  bool _comingOutPointerHeld = false;
  double _comingOutShotTimer = 0;
  static const _comingOutShotInterval = 0.32;

  @override
  void onLoad() {
    portalLayer = _PortalLayerComponent();
    trapLayer = _TrapLayerComponent(priority: 15);
    webLayer = _WebLayerComponent(priority: 5);
    targetingPreview = _TargetingPreviewComponent(priority: 30);
    addAll([
      _LegacyTerrainComponent(priority: 0),
      webLayer,
      portalLayer..priority = 10,
      trapLayer,
      _LegacyActorsComponent(priority: 20),
      targetingPreview,
    ]);
  }

  @override
  void onPointerMove(PointerMoveEvent event) {
    final point = event.localPosition;
    game.network.updateAim(
      point.x / LehaBaldGame.tile,
      point.y / LehaBaldGame.tile,
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    final point = event.localPosition;
    final x = point.x / LehaBaldGame.tile;
    final y = point.y / LehaBaldGame.tile;
    if (game.network.targetingSkill == TargetingSkill.comingOut) {
      game.network.updateAim(x, y);
      if (targetingPreview.validAt(x, y)) {
        // A plain mobile tap must always produce one shot. Route it through the
        // same targeting action as the other skills; applyTarget deliberately
        // keeps Coming Out selected for subsequent taps.
        game.network.applyTarget(x, y);
        _comingOutPointerHeld = true;
        _comingOutShotTimer = _comingOutShotInterval;
      }
      return;
    }
    if (targetingPreview.validAt(x, y)) game.network.applyTarget(x, y);
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (game.network.targetingSkill == TargetingSkill.comingOut) {
      final point = event.localPosition;
      final x = point.x / LehaBaldGame.tile;
      final y = point.y / LehaBaldGame.tile;
      game.network.updateAim(x, y);
      if (targetingPreview.validAt(x, y)) {
        // TapUp is the gesture arena's confirmed click/tap. Some platforms do
        // not deliver the initial TapDown to the scene when drag recognition is
        // also installed, so always confirm one shot here. The server cooldown
        // safely deduplicates it if TapDown already fired.
        game.network.applyTarget(x, y);
      }
    }
    _stopComingOut();
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final point = event.localPosition;
    _startComingOut(
      point.x / LehaBaldGame.tile,
      point.y / LehaBaldGame.tile,
    );
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (game.network.targetingSkill != TargetingSkill.comingOut) return;
    final point = event.localEndPosition;
    if (point.x.isNaN || point.y.isNaN) return;
    game.network.updateAim(
      point.x / LehaBaldGame.tile,
      point.y / LehaBaldGame.tile,
    );
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _stopComingOut();
  }

  @override
  void update(double dt) {
    if (game.network.targetingSkill != TargetingSkill.comingOut) {
      _comingOutPointerHeld = false;
    } else if (_comingOutPointerHeld) {
      _comingOutShotTimer -= dt;
      if (_comingOutShotTimer <= 0) _fireComingOut();
    }
    final snapshot = game.network.snapshot;
    isVisible = snapshot != null;
    if (snapshot != null) {
      _layout(snapshot);
      _syncPalette(snapshot);
      portalLayer.sync(snapshot.portals);
      trapLayer.sync(snapshot.traps);
      webLayer.sync(snapshot.webs);
    } else {
      portalLayer.sync(const []);
      trapLayer.sync(const []);
      webLayer.sync(const []);
    }
    super.update(dt);
  }

  void _fireComingOut() {
    final x = game.network.aimX;
    final y = game.network.aimY;
    if (x == null || y == null || !targetingPreview.validAt(x, y)) return;
    game.network.comingOut(targetX: x, targetY: y);
    _comingOutShotTimer = _comingOutShotInterval;
  }

  void _startComingOut(double x, double y) {
    if (game.network.targetingSkill != TargetingSkill.comingOut) return;
    game.network.updateAim(x, y);
    if (!targetingPreview.validAt(x, y)) return;
    if (_comingOutPointerHeld) return;
    _comingOutPointerHeld = true;
    _comingOutShotTimer = 0;
    _fireComingOut();
  }

  void _stopComingOut() {
    _comingOutPointerHeld = false;
    _comingOutShotTimer = 0;
  }

  void _layout(GameSnapshotDto snapshot) {
    // The camera owns the view transform now (a fixed 20×20-block window that
    // follows the player); the scene sits at the world origin at 1:1 scale.
    // We still track the board size so taps land in the right cells.
    size.setValues(
      snapshot.cols * LehaBaldGame.tile,
      snapshot.rows * LehaBaldGame.tile,
    );
  }

  void _syncPalette(GameSnapshotDto snapshot) {
    if (snapshot.biome == game._paletteBiome &&
        snapshot.stoneSeed == game._paletteSeed) {
      return;
    }
    game._palette = _BiomePalette.build(snapshot.biome, snapshot.stoneSeed);
    game._paletteBiome = snapshot.biome;
    game._paletteSeed = snapshot.stoneSeed;
  }
}

class _TargetingPreviewComponent extends Component
    with HasGameReference<LehaBaldGame> {
  _TargetingPreviewComponent({required super.priority});

  bool validAt(double x, double y) {
    final skill = game.network.targetingSkill;
    final snapshot = game.network.snapshot;
    if (skill == null || snapshot == null) return false;
    final me = snapshot.players
        .where((player) => player.id == snapshot.you.id)
        .firstOrNull;
    if (me == null) return false;
    return _valid(
        snapshot, skill, Offset(me.x, me.y), Offset(x, y), _range(skill));
  }

  @override
  void render(Canvas canvas) {
    final skill = game.network.targetingSkill;
    final snapshot = game.network.snapshot;
    if (skill == null || snapshot == null) return;
    final me = snapshot.players
        .where((player) => player.id == snapshot.you.id)
        .firstOrNull;
    if (me == null) return;
    final aim = Offset(
      game.network.aimX ?? me.x + (me.facing?.dx ?? 1),
      game.network.aimY ?? me.y + (me.facing?.dy ?? 0),
    );
    final origin = Offset(me.x, me.y);
    final range = _range(skill);
    final valid = _valid(snapshot, skill, origin, aim, range);
    final color = valid ? const Color(0xff55ef9f) : const Color(0xffff5d6c);
    final tile = LehaBaldGame.tile;

    if (skill != TargetingSkill.barrel && skill != TargetingSkill.comingOut) {
      canvas.drawCircle(
        origin * tile,
        range * tile,
        Paint()
          ..color = color.withValues(alpha: 0.13)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    if (skill == TargetingSkill.barrel) {
      _drawBarrelPath(canvas, snapshot, origin, aim);
      return;
    }


    if (skill == TargetingSkill.comingOut) {
      _drawComingOutPath(canvas, snapshot, origin, aim, valid);
      return;
    }

    if (skill == TargetingSkill.femboy) {
      canvas.drawLine(
        origin * tile,
        aim * tile,
        Paint()
          ..color = color.withValues(alpha: 0.8)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    final cell = Offset(aim.dx.floorToDouble(), aim.dy.floorToDouble());
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            cell.dx * tile + 2, cell.dy * tile + 2, tile - 4, tile - 4),
        const Radius.circular(6),
      ),
      Paint()..color = color.withValues(alpha: 0.48),
    );
  }

  double _range(TargetingSkill skill) => switch (skill) {
        TargetingSkill.trap => SkillTargetRange.trap,
        TargetingSkill.barrel => SkillTargetRange.barrelPreview,
        TargetingSkill.femboy => SkillTargetRange.femboy,
        TargetingSkill.comingOut => SkillTargetRange.comingOut,
        TargetingSkill.web => SkillTargetRange.web,
        TargetingSkill.portal => SkillTargetRange.portal,
        TargetingSkill.crystal => SkillTargetRange.crystal,
        TargetingSkill.chain => SkillTargetRange.chain,
        TargetingSkill.clutch => SkillTargetRange.clutch,
      };

  bool _valid(GameSnapshotDto s, TargetingSkill skill, Offset from, Offset aim,
      double range) {
    if (skill == TargetingSkill.barrel) {
      return (aim - from).distance > 0.1;
    }
    if (skill == TargetingSkill.comingOut) {
      return (aim - from).distance > 0.1;
    }
    if ((aim - from).distance > range ||
        aim.dx < 0 ||
        aim.dy < 0 ||
        aim.dx >= s.cols ||
        aim.dy >= s.rows) {
      return false;
    }
    if (skill == TargetingSkill.femboy) {
      return _lineClear(s, from, aim);
    }
    final x = aim.dx.floor(), y = aim.dy.floor();
    final wall = _wall(s, x, y);
    final emberBlocked = s.lava.any((cell) => cell.x == x && cell.y == y) ||
        s.emberRocks.any((rock) => rock.x == x && rock.y == y);
    return switch (skill) {
      TargetingSkill.trap => !wall &&
          !emberBlocked &&
          !s.bushes.any((cell) => cell.x == x && cell.y == y),
      TargetingSkill.web => (s.crackedWalls
                  .any((cell) => cell.x == x && cell.y == y) ||
              (!wall &&
                  !emberBlocked &&
                  !s.quicksand.any((cell) => cell.x == x && cell.y == y) &&
                  !s.amethystWalls.any((cell) => cell.x == x && cell.y == y) &&
                  !s.amethystShards.any((cell) => cell.x == x && cell.y == y) &&
                  !s.mushrooms.any(
                      (mushroom) => mushroom.x == x && mushroom.y == y))) &&
          !s.webs.any((web) => web.x == x && web.y == y),
      TargetingSkill.portal => !wall &&
          !emberBlocked &&
          !s.bushes.any((cell) => cell.x == x && cell.y == y),
      TargetingSkill.crystal => !wall &&
          !emberBlocked &&
          (!s.magicCrystals
                  .any((crystal) => crystal.x == x && crystal.y == y) ||
              s.magicCrystals.any((crystal) =>
                  (crystal.x + 0.5 - aim.dx).abs() < 0.85 &&
                  (crystal.y + 0.5 - aim.dy).abs() < 0.85)),
      TargetingSkill.chain => s.magicCrystals.any((crystal) =>
          !crystal.fallen &&
          (Offset(crystal.x + 0.5, crystal.y + 0.5) - aim).distance <= 0.85),
      TargetingSkill.clutch => !wall &&
          !emberBlocked &&
          !s.webs.any((web) => web.x == x && web.y == y),
      _ => false,
    };
  }

  bool _wall(GameSnapshotDto s, int x, int y) =>
      x < 0 || y < 0 || x >= s.cols || y >= s.rows || s.maze[y][x] == '#';

  bool _lineClear(GameSnapshotDto s, Offset a, Offset b) {
    final delta = b - a;
    final steps = max(1, (delta.distance * 8).ceil());
    for (var i = 1; i <= steps; i++) {
      final p = a + delta * (i / steps);
      if (_wall(s, p.dx.floor(), p.dy.floor())) return false;
    }
    return true;
  }

  void _drawBarrelPath(
      Canvas canvas, GameSnapshotDto s, Offset origin, Offset aim) {
    var direction = aim - origin;
    if (direction.distance < 0.01) return;
    direction = direction / direction.distance;
    var point = origin;
    var bounces = 0;
    final path = Path()
      ..moveTo(point.dx * LehaBaldGame.tile, point.dy * LehaBaldGame.tile);
    for (var i = 0;
        i < SkillTargetRange.barrelPreviewTicks && bounces < 3;
        i++) {
      final result = _advancePreviewBarrel(s, point, direction);
      point = result.point;
      direction = result.direction;
      if (result.bounced) bounces++;
      if (result.wrapped) {
        path.moveTo(point.dx * LehaBaldGame.tile, point.dy * LehaBaldGame.tile);
      } else {
        path.lineTo(point.dx * LehaBaldGame.tile, point.dy * LehaBaldGame.tile);
      }
    }
    const trajectory = Color(0xffa8e6a3);
    canvas.drawPath(
      path,
      Paint()
        ..color = trajectory.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = trajectory.withValues(alpha: 0.58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _drawComingOutPath(Canvas canvas, GameSnapshotDto s, Offset origin,
      Offset aim, bool valid) {
    var delta = aim - origin;
    if (delta.distance < 0.01) return;
    final direction = delta / delta.distance;
    final distance = min(delta.distance, SkillTargetRange.comingOut);
    var end = origin;
    const step = 0.08;
    for (var traveled = step; traveled <= distance; traveled += step) {
      final next = origin + direction * traveled;
      if (_wall(s, next.dx.floor(), next.dy.floor())) break;
      end = next;
    }
    final color = valid ? const Color(0xffff8fcf) : const Color(0xffff5d6c);
    final path = Path()
      ..moveTo(origin.dx * LehaBaldGame.tile, origin.dy * LehaBaldGame.tile)
      ..lineTo(end.dx * LehaBaldGame.tile, end.dy * LehaBaldGame.tile);
    canvas.drawPath(path, Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round);
    canvas.drawPath(path, Paint()
      ..color = color.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round);
  }

  ({Offset point, Offset direction, bool bounced, bool wrapped})
      _advancePreviewBarrel(GameSnapshotDto s, Offset point, Offset direction) {
    final step = direction * SkillTargetRange.barrelStep;
    var next = point + step;
    var bounced = false;
    if (_barrelBlocked(s, next.dx, next.dy)) {
      bounced = true;
      final blockedX = _barrelBlocked(s, point.dx + step.dx, point.dy);
      final blockedY = _barrelBlocked(s, point.dx, point.dy + step.dy);
      if (blockedX) direction = Offset(-direction.dx, direction.dy);
      if (blockedY) direction = Offset(direction.dx, -direction.dy);
      if (!blockedX && !blockedY) direction = -direction;
      next = point + direction * SkillTargetRange.barrelStep;
      if (_barrelBlocked(s, next.dx, next.dy)) {
        var x = point.dx;
        var y = point.dy;
        if (!_barrelBlocked(
            s, point.dx + direction.dx * SkillTargetRange.barrelStep, y)) {
          x += direction.dx * SkillTargetRange.barrelStep;
        }
        if (!_barrelBlocked(
            s, x, point.dy + direction.dy * SkillTargetRange.barrelStep)) {
          y += direction.dy * SkillTargetRange.barrelStep;
        }
        next = Offset(x, y);
      }
    }

    var wrapped = false;
    if (_isTunnelRow(s, next.dy.floor())) {
      if (next.dx < -0.35) {
        next = Offset(s.cols + 0.35, next.dy);
        wrapped = true;
      } else if (next.dx > s.cols + 0.35) {
        next = Offset(-0.35, next.dy);
        wrapped = true;
      }
    }
    if (_isTunnelColumn(s, next.dx.floor())) {
      if (next.dy < -0.35) {
        next = Offset(next.dx, s.rows + 0.35);
        wrapped = true;
      } else if (next.dy > s.rows + 0.35) {
        next = Offset(next.dx, -0.35);
        wrapped = true;
      }
    }
    return (
      point: next,
      direction: direction,
      bounced: bounced,
      wrapped: wrapped,
    );
  }

  bool _barrelBlocked(GameSnapshotDto s, double x, double y) {
    if (_isTunnelRow(s, y.floor()) && (x < 0 || x >= s.cols)) return false;
    if (_isTunnelColumn(s, x.floor()) && (y < 0 || y >= s.rows)) {
      return false;
    }
    const r = SkillTargetRange.barrelRadius;
    for (var cy = (y - r).floor(); cy <= (y + r).ceil(); cy++) {
      for (var cx = (x - r).floor(); cx <= (x + r).ceil(); cx++) {
        if (!_wall(s, cx, cy)) continue;
        final closestX = x.clamp(cx.toDouble(), cx + 1.0);
        final closestY = y.clamp(cy.toDouble(), cy + 1.0);
        final dx = x - closestX;
        final dy = y - closestY;
        if (dx * dx + dy * dy < r * r) return true;
      }
    }
    return false;
  }

  bool _isTunnelRow(GameSnapshotDto s, int y) =>
      y >= 0 &&
      y < s.rows &&
      s.maze[y][0] != '#' &&
      s.maze[y][s.cols - 1] != '#';

  bool _isTunnelColumn(GameSnapshotDto s, int x) =>
      s.biome != CaveBiome.ember &&
      x >= 0 &&
      x < s.cols &&
      s.maze[0][x] != '#' &&
      s.maze[s.rows - 1][x] != '#';
}

/// Temporary compatibility layer. Terrain renderers move out of this class in
/// follow-up slices, while their ordering is already managed by FCS priority.
class _LegacyTerrainComponent extends Component
    with HasGameReference<LehaBaldGame> {
  _LegacyTerrainComponent({required super.priority});

  @override
  void render(Canvas canvas) {
    final snapshot = game.network.snapshot;
    if (snapshot == null) return;
    game._drawVoidBeyondMap(canvas, snapshot);
    game._drawBoard(canvas, snapshot);
    game._drawLava(canvas, snapshot.lava);
    game._drawGeysers(canvas, snapshot.geysers);
    game._drawEmberRocks(canvas, snapshot.emberRocks);
    game._drawSulfur(canvas, snapshot.sulfur);
    game._drawAmethystWalls(canvas, snapshot.amethystWalls);
    game._drawQuicksand(canvas, snapshot.quicksand);
    game._drawSpores(canvas, snapshot.spores);
    game._drawAmethystShards(canvas, snapshot.amethystShards);
    game._drawCrackedWalls(canvas, snapshot.crackedWalls);
    game._drawLeaves(canvas, snapshot.leaves);
    game._drawBushes(canvas, snapshot.bushes);
    game._drawMushroomColony(canvas, snapshot.mushrooms);
    game._drawMagicChains(canvas, snapshot.magicCrystals, snapshot.magicChains);
    game._drawCrystalEntities(canvas, snapshot.crystals);
    game._drawCrystalLinks(
      canvas,
      snapshot.players,
      snapshot.illusions,
      snapshot.crystals,
    );
    game._drawSarcophagi(canvas, snapshot.sarcophagi);
    game._drawTrail(canvas, snapshot.trail);
    game._drawLogos(canvas, snapshot.logos, snapshot.game.spiderMode);
    game._drawClutch(canvas, snapshot.clutch);
    // Rim the cave on top of the perimeter walls so the world's edge reads as a
    // lit ledge above the surrounding abyss.
    game._drawMapEdge(canvas, snapshot);
  }
}

class _LegacyActorsComponent extends Component
    with HasGameReference<LehaBaldGame> {
  _LegacyActorsComponent({required super.priority});

  @override
  void render(Canvas canvas) {
    final snapshot = game.network.snapshot;
    if (snapshot == null) return;
    game._drawBarrels(canvas, snapshot.barrels);
    game._drawHeartProjectiles(canvas, snapshot.hearts);
    game._drawMummies(canvas, snapshot.mummies);
    game._drawIllusions(canvas, snapshot.illusions);
    game._drawPlayers(
      canvas,
      snapshot.players,
      snapshot.you.id,
      snapshot.crystals,
    );
    game._drawChimes(canvas, snapshot.chimes);
    game._drawBlindFog(canvas, snapshot);
  }
}
