import 'dart:math';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/painting.dart' show HSVColor;
import 'package:flutter/services.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';

import '../net/game_network_client.dart';

class LehaBaldGame extends FlameGame {
  LehaBaldGame({required this.network});

  static const tile = 32.0;
  final GameNetworkClient network;
  final _heldKeys = <LogicalKeyboardKey, MoveDirection>{};

  /// The active cave palette, rebuilt only when the biome or stone seed changes.
  _BiomePalette _palette = _BiomePalette.build(CaveBiome.forest, 0);
  CaveBiome? _paletteBiome;
  int? _paletteSeed;
  final Map<String, _PlayerRenderState> _renderPlayers = {};
  int _renderFrameCount = 0;
  double _renderDtEwmaMs = 0;
  double _renderDtMaxMs = 0;
  double _visualTime = 0;

  late Image playerHead;
  late Image chaserHead;
  late Image poweredHead;
  late Image spiderHead;
  late Image wizardHead;
  late Image logoImage;
  // Optional Sasha-yakuza assets — null until the PNGs are added; we fall back
  // to procedural drawing / the default chaser head so the game still runs.
  Image? sashaHead;
  Image? barrelImage;
  Image? simaHead;
  Image? simaFemboy;
  Image? trapImage;
  Image? portalActiveImage;
  Image? portalInactiveImage;
  Image? webImage;
  Image? rafaelkaImage;
  Image? clutchImage;

  // Single keyboard path: the HardwareKeyboard handler receives every key
  // regardless of which widget holds focus. We intentionally do NOT use Flame's
  // KeyboardEvents mixin too — that would deliver each press twice and fire
  // one-shot actions (place portal / trap / ability) twice per keystroke.
  bool _hardwareKeyHandler(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyUpEvent) return false;
    _handleKey(event);
    return false; // don't consume — let other handlers see it too
  }

  @override
  Future<void> onLoad() async {
    HardwareKeyboard.instance.addHandler(_hardwareKeyHandler);
    playerHead = await images.load('player-head.png');
    chaserHead = await images.load('chaser-head.png');
    poweredHead = await images.load('leha-powered.png');
    spiderHead = await images.load('leha-spider.png');
    wizardHead = await images.load('leha-wizard.png');
    logoImage = await images.load('tiktok-logo.png');
    sashaHead = await _tryLoad('sasha-head.png');
    barrelImage = await _tryLoad('barrel.png');
    simaHead = await _tryLoad('sima-head.png');
    simaFemboy = await _tryLoad('sima-femboy.png');
    trapImage = await _tryLoad('trap.png');
    portalActiveImage = await _tryLoad('portal-active.png');
    portalInactiveImage = await _tryLoad('portal-inactive.png');
    webImage = await _tryLoad('web.png');
    rafaelkaImage = await _tryLoad('rafaelka.png');
    clutchImage = await _tryLoad('clutch.png');
  }

  @override
  void onRemove() {
    HardwareKeyboard.instance.removeHandler(_hardwareKeyHandler);
    super.onRemove();
  }

  Future<Image?> _tryLoad(String name) async {
    try {
      return await images.load(name);
    } catch (_) {
      return null;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _visualTime += dt;
    _recordRenderTiming(dt);
    _updatePlayerSmoothing(dt);
  }

  void _recordRenderTiming(double dt) {
    final dtMs = dt * 1000;
    _renderFrameCount += 1;
    _renderDtEwmaMs =
        _renderDtEwmaMs == 0 ? dtMs : _renderDtEwmaMs * 0.95 + dtMs * 0.05;
    _renderDtMaxMs = max(_renderDtMaxMs, dtMs);
    if (_renderFrameCount % 300 == 0) {
      network.addClientLog('render-stats', {
        'frame': _renderFrameCount,
        'dtAvgMs': _renderDtEwmaMs.toStringAsFixed(1),
        'dtMaxMs': _renderDtMaxMs.toStringAsFixed(1),
        'smoothedPlayers': _renderPlayers.length,
      });
      _renderDtMaxMs = 0;
    }
  }

  void _updatePlayerSmoothing(double dt) {
    final snapshot = network.snapshot;
    if (snapshot == null) {
      _renderPlayers.clear();
      return;
    }
    final snapshotVersion = network.snapshotVersion;
    final snapshotReceivedMs = network.snapshotReceivedMs;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final seen = <String>{};
    for (final player in snapshot.players) {
      seen.add(player.id);
      final target = Offset(player.x, player.y);
      final state = _renderPlayers.putIfAbsent(
        player.id,
        () => _PlayerRenderState(position: target),
      );
      if (state.snapshotVersion != snapshotVersion) {
        state.acceptSnapshot(target, snapshotVersion, snapshotReceivedMs);
      }
      final extrapolateSeconds =
          ((nowMs - state.sampleMs).clamp(0, 120)) / 1000.0;
      final desired = state.target +
          Offset(
            state.velocity.dx * extrapolateSeconds,
            state.velocity.dy * extrapolateSeconds,
          );
      final dx = desired.dx - state.position.dx;
      final dy = desired.dy - state.position.dy;
      final dist = sqrt(dx * dx + dy * dy);
      // A genuine teleport, tunnel wrap, reconnect, or visibility re-entry
      // should snap. Normal movement is smoothed between 60Hz snapshots.
      if (dist > 2.2) {
        if (state.initialized) {
          network.addClientLog('pos-jump', {
            'id': player.id,
            'slot': player.slot,
            'dist': dist.toStringAsFixed(2),
            'from':
                '${state.position.dx.toStringAsFixed(2)},${state.position.dy.toStringAsFixed(2)}',
            'to':
                '${desired.dx.toStringAsFixed(2)},${desired.dy.toStringAsFixed(2)}',
          });
        }
        state.position = desired;
      } else {
        final isMe = player.id == snapshot.you.id;
        final stiffness = isMe ? 34.0 : 24.0;
        final alpha = (1 - exp(-stiffness * dt)).clamp(0.0, 1.0);
        state.position = Offset(
          state.position.dx + dx * alpha,
          state.position.dy + dy * alpha,
        );
      }
      state.initialized = true;
    }
    _renderPlayers.removeWhere((id, _) => !seen.contains(id));
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final snapshot = network.snapshot;
    if (snapshot == null) {
      _drawEmpty(canvas);
      return;
    }

    // Reserve a strip at the top for the HUD overlay so it never covers the
    // map; the board is centred within the remaining area.
    const topInset = 88.0;
    final availH = (size.y - topInset).clamp(1.0, size.y);
    final scale =
        min(size.x / (snapshot.cols * tile), availH / (snapshot.rows * tile));
    final boardW = snapshot.cols * tile * scale;
    final boardH = snapshot.rows * tile * scale;
    final dx = (size.x - boardW) / 2;
    final dy = topInset + (availH - boardH) / 2;

    // Rebuild the palette only when the map's theme actually changes.
    if (snapshot.biome != _paletteBiome || snapshot.stoneSeed != _paletteSeed) {
      _palette = _BiomePalette.build(snapshot.biome, snapshot.stoneSeed);
      _paletteBiome = snapshot.biome;
      _paletteSeed = snapshot.stoneSeed;
    }

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    _drawBoard(canvas, snapshot);
    _drawAmethystWalls(canvas, snapshot.amethystWalls);
    _drawQuicksand(canvas, snapshot.quicksand);
    _drawSpores(canvas, snapshot.spores);
    _drawAmethystShards(canvas, snapshot.amethystShards);
    _drawCrackedWalls(canvas, snapshot.crackedWalls);
    _drawBushes(canvas, snapshot.bushes);
    _drawMushroomColony(canvas, snapshot.mushrooms);
    _drawMagicChains(canvas, snapshot.magicCrystals, snapshot.magicChains);
    _drawCrystalEntities(canvas, snapshot.crystals);
    _drawCrystalLinks(
        canvas, snapshot.players, snapshot.illusions, snapshot.crystals);
    _drawSarcophagi(canvas, snapshot.sarcophagi);
    _drawTrail(canvas, snapshot.trail);
    _drawWebs(canvas, snapshot.webs);
    _drawLogos(canvas, snapshot.logos, snapshot.game.spiderMode);
    _drawClutch(canvas, snapshot.clutch);
    _drawPortals(canvas, snapshot.portals);
    _drawTraps(canvas, snapshot.traps);
    _drawBarrels(canvas, snapshot.barrels);
    _drawMummies(canvas, snapshot.mummies);
    _drawIllusions(canvas, snapshot.illusions);
    _drawPlayers(canvas, snapshot.players, snapshot.you.id, snapshot.crystals);
    _drawChimes(canvas, snapshot.chimes);
    _drawBlindFog(canvas, snapshot);

    canvas.restore();
  }

  /// When Leha is hit by a barrel his sight collapses to a small radius:
  /// everything outside it is covered by darkness.
  void _drawBlindFog(Canvas canvas, GameSnapshotDto snapshot) {
    final me =
        snapshot.players.where((p) => p.id == snapshot.you.id).firstOrNull;
    if (me == null || !me.blinded) return;
    final center = Offset(me.x * tile, me.y * tile);
    const radius = tile * 2.4;
    final shroud = Paint()
      ..shader = Gradient.radial(
        center,
        radius * 1.5,
        const [Color(0x00000000), Color(0xcc05070d), Color(0xf205070d)],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, snapshot.cols * tile, snapshot.rows * tile),
      shroud,
    );
  }

  void _drawBarrels(Canvas canvas, List<BarrelDto> barrels) {
    for (final barrel in barrels) {
      final center = Offset(barrel.x * tile, barrel.y * tile);
      // Rotate the barrel to align with its travel direction.
      final hasDir = barrel.dirX != 0 || barrel.dirY != 0;
      final angle = hasDir ? atan2(barrel.dirY, barrel.dirX) : 0.0;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final image = barrelImage;
      if (image != null) {
        _drawImage(canvas, image, Offset.zero, tile * 1.2, 1);
      } else {
        // Procedural barrel: brown body with two darker hoops.
        final rect = Rect.fromCenter(
            center: Offset.zero, width: tile * 0.8, height: tile * 0.96);
        final body = RRect.fromRectAndRadius(rect, const Radius.circular(6));
        canvas.drawRRect(body, Paint()..color = const Color(0xff7a4a22));
        canvas.drawRRect(
          body,
          Paint()
            ..color = const Color(0xff3a2410)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        final hoop = Paint()
          ..color = const Color(0xff2c2c30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawLine(
          rect.topLeft.translate(0, rect.height * 0.3),
          rect.topRight.translate(0, rect.height * 0.3),
          hoop,
        );
        canvas.drawLine(
          rect.bottomLeft.translate(0, -rect.height * 0.3),
          rect.bottomRight.translate(0, -rect.height * 0.3),
          hoop,
        );
      }
      canvas.restore();
    }
  }

  void _handleKey(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.space && event is KeyDownEvent) {
      final snapshot = network.snapshot;
      if (snapshot?.you.role == PlayerRole.hunter) {
        // Only Bakhirkin places a trap; Sasha/Sima use their active ability.
        if (_myHunterKind(snapshot) == HunterKind.bakhirkin) {
          network.placeTrap();
        } else {
          network.useAbility();
        }
      } else if (snapshot?.you.role == PlayerRole.leha) {
        network.useAbility();
      }
      return;
    }

    if ((event.logicalKey == LogicalKeyboardKey.keyE ||
            event.logicalKey == LogicalKeyboardKey.keyQ) &&
        event is KeyDownEvent) {
      network.useAbility();
      return;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyC && event is KeyDownEvent) {
      final snapshot = network.snapshot;
      final me = snapshot?.players
          .where((player) => player.id == snapshot.you.id)
          .firstOrNull;
      if (me?.aspect == LehaAspect.wizard) network.placeMagicCrystal();
      return;
    }

    // Spider lays a clutch; Wizard closes a crystal chain.
    if (event.logicalKey == LogicalKeyboardKey.keyF && event is KeyDownEvent) {
      final snapshot = network.snapshot;
      final me = snapshot?.players
          .where((player) => player.id == snapshot.you.id)
          .firstOrNull;
      if (me?.aspect == LehaAspect.wizard) {
        network.activateMagicChain();
      } else {
        network.layClutch();
      }
      return;
    }

    final direction = _directionForKey(event.logicalKey);
    if (direction == null) return;

    if (event is KeyDownEvent) {
      _heldKeys[event.logicalKey] = direction;
    } else {
      _heldKeys.remove(event.logicalKey);
    }

    final combined = _combinedDirection();
    if (combined == null) {
      network.stop();
    } else {
      network.input(combined);
    }
  }

  void _drawEmpty(Canvas canvas) {
    canvas.drawColor(const Color(0xff05070d), BlendMode.src);
  }

  void _drawBoard(Canvas canvas, GameSnapshotDto snapshot) {
    final bg = Paint()..color = _palette.background;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, snapshot.cols * tile, snapshot.rows * tile), bg);
    final wallPaint = Paint()..color = _palette.wall;
    final stroke = Paint()
      ..color = _palette.wallEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var y = 0; y < snapshot.maze.length; y += 1) {
      for (var x = 0; x < snapshot.maze[y].length; x += 1) {
        if (snapshot.maze[y][x] != '#') continue;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x * tile + 2, y * tile + 2, tile - 4, tile - 4),
          const Radius.circular(7),
        );
        canvas.drawRRect(rect, wallPaint);
        canvas.drawRRect(rect, stroke);
      }
    }
  }

  /// Cracked walls keep the normal wall look from [_drawBoard]; we just etch a
  /// jagged fracture (with a few branches) onto them so the Spider can tell
  /// where she may web, without making them garishly stand out.
  void _drawCrackedWalls(Canvas canvas, List<Vec2i> crackedWalls) {
    for (final w in crackedWalls) {
      final left = w.x * tile, top = w.y * tile;

      final cx = left + tile / 2;
      final rnd = Random(w.x * 2654435761 ^ w.y * 40503);
      // Main jagged fracture down the middle, with a couple of branches.
      final crack = Path()..moveTo(cx, top + 3);
      final joints = <Offset>[Offset(cx, top + 3)];
      var py = top + 3.0;
      while (py < top + tile - 3) {
        py += tile * (0.18 + rnd.nextDouble() * 0.12);
        final jx = cx + tile * (rnd.nextDouble() - 0.5) * 0.6;
        final p = Offset(jx, py.clamp(top + 3, top + tile - 3));
        crack.lineTo(p.dx, p.dy);
        joints.add(p);
      }
      // Branch fractures off random joints.
      for (final j in joints.skip(1)) {
        if (rnd.nextBool()) continue;
        final dir = rnd.nextBool() ? 1 : -1;
        crack.moveTo(j.dx, j.dy);
        crack.lineTo(
          (j.dx + dir * tile * (0.2 + rnd.nextDouble() * 0.25))
              .clamp(left + 3, left + tile - 3),
          (j.dy + tile * (rnd.nextDouble() - 0.5) * 0.3)
              .clamp(top + 3, top + tile - 3),
        );
      }
      // Dark fissure with a biome-accent highlight so it reads as a crack in
      // the cave stone.
      canvas.drawPath(
        crack,
        Paint()
          ..color = _palette.crackDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(
        crack,
        Paint()
          ..color = _palette.accent.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// Concealment cover. The motif is themed per biome (leafy bushes, glowing
  /// mushrooms, ice crystals, ember fungus, cacti) but all share the same
  /// footprint and a tinted base so a patch still reads as one shape.
  void _drawQuicksand(Canvas canvas, List<Vec2i> quicksand) {
    // No background fill — only a warm wavy ripple pattern drawn on the floor,
    // like the ridges of sinking sand, so the patch reads by texture not colour.
    final stroke = Paint()
      ..color = const Color(0x66caa765)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    for (final q in quicksand) {
      final cx = q.x * tile, cy = q.y * tile;
      final rnd = Random(q.x * 73856093 ^ q.y * 83492791);
      // 3 horizontal sand ripples per cell, each a gentle wave with a random
      // vertical offset and phase so the patch looks organic and continuous.
      const lines = 3;
      for (var i = 0; i < lines; i++) {
        final baseY =
            cy + tile * (0.22 + i * 0.28) + tile * 0.06 * rnd.nextDouble();
        final amp = tile * (0.05 + rnd.nextDouble() * 0.05);
        final dir = rnd.nextBool() ? 1 : -1;
        final path = Path()..moveTo(cx, baseY);
        path.cubicTo(
          cx + tile * 0.33,
          baseY - amp * dir,
          cx + tile * 0.66,
          baseY + amp * dir,
          cx + tile,
          baseY,
        );
        canvas.drawPath(path, stroke);
      }
    }
  }

  void _drawSpores(Canvas canvas, List<Vec2i> spores) {
    final paint = Paint();
    for (final s in spores) {
      final center = Offset((s.x + 0.5) * tile, (s.y + 0.5) * tile);
      final cellPhase = s.x * 1.731 + s.y * 2.417;

      // Persistent overlapping lobes form one readable cloud without a blur
      // filter. Each lobe drifts and breathes slowly; neighbouring cells overlap
      // naturally instead of exposing square tile boundaries.
      for (var i = 0; i < 7; i++) {
        final phase = cellPhase + i * 2.193;
        final angle = phase + sin(_visualTime * 0.31 + phase) * 0.22;
        final spread = tile * (0.12 + (i % 3) * 0.055);
        final drift = Offset(
          cos(angle) * spread + sin(_visualTime * 0.48 + phase) * tile * 0.035,
          sin(angle) * spread * 0.72 +
              cos(_visualTime * 0.39 + phase) * tile * 0.03,
        );
        final breathe = 0.92 + 0.12 * sin(_visualTime * 0.72 + phase);
        final radius = tile * (0.24 + (i % 4) * 0.025) * breathe;
        final alpha = 0.105 + (i % 3) * 0.018;
        paint.color = const Color(0xffb06bdd).withValues(alpha: alpha);
        canvas.drawCircle(center + drift, radius, paint);
      }

      // Short-lived satellite puffs continuously appear, expand and dissolve.
      // Staggered phases keep the whole cloud from pulsing in sync.
      for (var i = 0; i < 3; i++) {
        final phase = (cellPhase * 0.37 + i * 0.34) % 1.0;
        final life = (_visualTime * 0.18 + phase) % 1.0;
        final angle = cellPhase + i * 2.1 + life * 0.8;
        final drift = Offset(cos(angle), sin(angle) * 0.7) * tile * 0.24;
        final radius = tile * (0.08 + life * 0.25);
        final alpha = sin(life * pi) * 0.13;
        paint.color = const Color(0xffd9a8ff).withValues(alpha: alpha);
        canvas.drawCircle(center + drift, radius, paint);
      }
    }
  }

  void _drawMagicChains(
    Canvas canvas,
    List<MagicCrystalDto> crystals,
    List<MagicChainDto> chains,
  ) {
    if (crystals.isEmpty) return;
    final byId = {for (final crystal in crystals) crystal.id: crystal};
    final activeIds = <int>{};
    final drawnEdges = <String>{};
    final under = Paint()
      ..color = const Color(0xdd09000f)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final halo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final energy = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.65
      ..strokeCap = StrokeCap.round;
    for (final chain in chains) {
      for (final contour in chain.contours) {
        activeIds.addAll(contour);
        for (var edgeIndex = 0; edgeIndex < contour.length; edgeIndex++) {
          final a = byId[contour[edgeIndex]];
          final b = byId[contour[(edgeIndex + 1) % contour.length]];
          if (a == null || b == null || a.fallen || b.fallen) continue;
          final edgeKey = a.id < b.id ? '${a.id}:${b.id}' : '${b.id}:${a.id}';
          if (!drawnEdges.add(edgeKey)) continue;
          final start = Offset((a.x + 0.5) * tile, (a.y + 0.5) * tile);
          final end = Offset((b.x + 0.5) * tile, (b.y + 0.5) * tile);
          final delta = end - start;
          final length = delta.distance;
          if (length <= 0.1) continue;
          final normal = Offset(-delta.dy / length, delta.dx / length);
          final path = Path()..moveTo(start.dx, start.dy);
          const segments = 10;
          for (var i = 1; i < segments; i++) {
            final t = i / segments;
            final phase = chain.id * 1.7 + edgeIndex * 2.3 + i * 3.1;
            final jitter = sin(_visualTime * 8 + phase) * tile * 0.055;
            final point = start + delta * t + normal * jitter;
            path.lineTo(point.dx, point.dy);
          }
          path.lineTo(end.dx, end.dy);
          final hue = (_visualTime * 95 + a.id * 43 + b.id * 67) % 360;
          final colors = [
            HSVColor.fromAHSV(1, hue, 0.88, 1).toColor(),
            HSVColor.fromAHSV(1, (hue + 105) % 360, 0.82, 1).toColor(),
            HSVColor.fromAHSV(1, (hue + 215) % 360, 0.9, 1).toColor(),
          ];
          canvas.drawPath(path, under);
          halo.shader = Gradient.linear(
            start,
            end,
            colors.map((color) => color.withValues(alpha: 0.65)).toList(),
            const [0, 0.5, 1],
          );
          canvas.drawPath(path, halo);
          energy.shader = Gradient.linear(start, end, [
            const Color(0xffffffff),
            colors[1],
            const Color(0xffffffff),
          ], const [
            0,
            0.5,
            1
          ]);
          canvas.drawPath(path, energy);
        }
      }
    }

    for (final crystal in crystals) {
      final center = Offset((crystal.x + 0.5) * tile, (crystal.y + 0.5) * tile);
      if (crystal.burstProgress < 1) {
        final progress = crystal.burstProgress;
        final burstPaint = Paint()
          ..color =
              const Color(0xffe8adff).withValues(alpha: (1 - progress) * 0.9)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 8; i++) {
          final angle = i * pi / 4 + crystal.id * 0.37;
          final inner = Offset(cos(angle), sin(angle)) * tile * progress * 0.18;
          final outer =
              Offset(cos(angle), sin(angle)) * tile * (0.18 + progress * 0.48);
          canvas.drawLine(center + inner, center + outer, burstPaint);
        }
      }
      if (crystal.fallen) {
        final fallen = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: center, width: tile * 0.65, height: tile * 0.2),
          const Radius.circular(3),
        );
        final fallenHue = (_visualTime * 70 + crystal.id * 53) % 360;
        canvas.drawRRect(
          fallen,
          Paint()
            ..shader = Gradient.linear(
                fallen.outerRect.topLeft, fallen.outerRect.bottomRight, [
              HSVColor.fromAHSV(1, fallenHue, 0.85, 1).toColor(),
              HSVColor.fromAHSV(1, (fallenHue + 140) % 360, 0.8, 1).toColor(),
            ]),
        );
        canvas.drawRRect(
          fallen,
          Paint()
            ..color = const Color(0xffffffff)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        continue;
      }
      final active = activeIds.contains(crystal.id);
      final height = tile * 0.38;
      final width = tile * 0.22;
      final gem = Path()
        ..moveTo(center.dx, center.dy - height)
        ..lineTo(center.dx + width, center.dy - height * 0.1)
        ..lineTo(center.dx + width * 0.55, center.dy + height * 0.75)
        ..lineTo(center.dx - width * 0.55, center.dy + height * 0.75)
        ..lineTo(center.dx - width, center.dy - height * 0.1)
        ..close();
      final hue = (_visualTime * (active ? 85 : 55) + crystal.id * 47) % 360;
      final pulse = 0.5 + 0.5 * sin(_visualTime * 5 + crystal.id * 1.3);
      final gemColors = [
        HSVColor.fromAHSV(1, hue, 0.86, 1).toColor(),
        HSVColor.fromAHSV(1, (hue + 115) % 360, 0.72, 1).toColor(),
        HSVColor.fromAHSV(1, (hue + 235) % 360, 0.9, 1).toColor(),
      ];
      canvas.drawCircle(
        center,
        tile * (active ? 0.38 + pulse * 0.035 : 0.3 + pulse * 0.02),
        Paint()
          ..color = const Color(0xcc05000a)
          ..style = PaintingStyle.stroke
          ..strokeWidth = active ? 4 : 3,
      );
      canvas.drawCircle(
        center,
        tile * (active ? 0.33 + pulse * 0.03 : 0.26 + pulse * 0.02),
        Paint()
          ..color = gemColors[1].withValues(alpha: active ? 0.75 : 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = active ? 2.5 : 1.5,
      );
      canvas.drawPath(
        gem,
        Paint()
          ..shader = Gradient.linear(
            Offset(center.dx - width, center.dy - height),
            Offset(center.dx + width, center.dy + height),
            gemColors,
            const [0, 0.5, 1],
          ),
      );
      canvas.drawPath(
        gem,
        Paint()
          ..color = const Color(0xffffffff)
          ..style = PaintingStyle.stroke
          ..strokeWidth = active ? 2.2 : 1.4,
      );
    }
  }

  void _drawAmethystWalls(Canvas canvas, List<Vec2i> walls) {
    for (final w in walls) {
      final left = w.x * tile, top = w.y * tile;
      final center = Offset(left + tile / 2, top + tile / 2);
      canvas.drawCircle(
        center,
        tile * 0.42,
        Paint()
          ..color = const Color(0x449d4edd)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      final rnd = Random(w.x * 92837111 ^ w.y * 689287499);
      for (var i = 0; i < 5; i++) {
        final x = left + tile * (0.18 + rnd.nextDouble() * 0.64);
        final baseY = top + tile * (0.76 + rnd.nextDouble() * 0.10);
        final height = tile * (0.28 + rnd.nextDouble() * 0.38);
        final width = tile * (0.10 + rnd.nextDouble() * 0.09);
        final crystal = Path()
          ..moveTo(x, baseY - height)
          ..lineTo(x + width, baseY - height * 0.28)
          ..lineTo(x + width * 0.65, baseY)
          ..lineTo(x - width * 0.65, baseY)
          ..lineTo(x - width, baseY - height * 0.28)
          ..close();
        canvas.drawPath(crystal, Paint()..color = const Color(0xff7b3fb4));
        canvas.drawPath(
          crystal,
          Paint()
            ..color = const Color(0xffd9a8ff)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }
  }

  void _drawAmethystShards(Canvas canvas, List<Vec2i> shards) {
    for (final s in shards) {
      final cx = s.x * tile + tile / 2, cy = s.y * tile + tile / 2;
      final rnd = Random(s.x * 83492791 ^ s.y * 19349663);
      // A small cluster of faceted purple gems sitting on the floor.
      for (var i = 0; i < 3; i++) {
        final ox = cx + tile * (rnd.nextDouble() - 0.5) * 0.5;
        final oy = cy + tile * (rnd.nextDouble() - 0.5) * 0.5;
        final r = tile * (0.10 + rnd.nextDouble() * 0.06);
        final gem = Path()
          ..moveTo(ox, oy - r)
          ..lineTo(ox + r * 0.7, oy)
          ..lineTo(ox, oy + r)
          ..lineTo(ox - r * 0.7, oy)
          ..close();
        canvas.drawPath(gem, Paint()..color = const Color(0xcc9d4edd));
        canvas.drawPath(
          gem,
          Paint()
            ..color = const Color(0x88e0aaff)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
      canvas.drawCircle(Offset(cx, cy), tile * 0.22,
          Paint()..color = const Color(0x22c77dff));
    }
  }

  void _drawMushroomColony(Canvas canvas, List<MushroomDto> mushrooms) {
    for (final m in mushrooms) {
      final cx = m.x * tile, cy = m.y * tile;
      final rnd = Random(m.x * 73856093 ^ m.y * 83492791);
      // Scale the cap by growth stage: sprout (small) → mature (full).
      final t = (m.stage + 1) / 4.0;
      final count = 2 + m.stage;
      for (var i = 0; i < count; i++) {
        final mx = cx + tile * (0.22 + rnd.nextDouble() * 0.56);
        final my = cy + tile * (0.34 + rnd.nextDouble() * 0.40);
        final capR = tile * (0.10 + rnd.nextDouble() * 0.12) * t;
        // Stem.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(mx - capR * 0.28, my, capR * 0.56, capR * 1.2),
            Radius.circular(capR * 0.3),
          ),
          Paint()..color = const Color(0xffe7d3ff).withValues(alpha: 0.85),
        );
        // Glow + cap (brighter as it matures).
        canvas.drawCircle(
            Offset(mx, my),
            capR * 1.6,
            Paint()
              ..color = const Color(0xff9d4edd).withValues(alpha: 0.12 * t));
        canvas.drawArc(
          Rect.fromCircle(center: Offset(mx, my), radius: capR),
          pi,
          pi,
          true,
          Paint()
            ..color = Color.lerp(
                const Color(0xff7b4bbd), const Color(0xffc77dff), t)!,
        );
        canvas.drawCircle(Offset(mx - capR * 0.3, my - capR * 0.25),
            capR * 0.16, Paint()..color = const Color(0xffeccbff));
      }
      // A mature mushroom about to burst gets a faint warning halo.
      if (m.stage >= 3) {
        canvas.drawCircle(Offset(cx + tile / 2, cy + tile / 2), tile * 0.42,
            Paint()..color = const Color(0x22d9a8ff));
      }
    }
  }

  void _drawChimes(Canvas canvas, List<ChimeDto> chimes) {
    for (final c in chimes) {
      final center = Offset(c.x * tile, c.y * tile);
      final radius = c.progress * 4.0 * tile; // chimeMaxRadius (tiles)
      final fade = (1.0 - c.progress).clamp(0.0, 1.0);
      // Expanding ring.
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xffc77dff).withValues(alpha: 0.55 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      // Lingering marker pinning the spot where someone stepped.
      canvas.drawCircle(
          center,
          tile * 0.3,
          Paint()
            ..color = const Color(0xff9d4edd).withValues(alpha: 0.6 * fade));
      canvas.drawCircle(
          center,
          tile * 0.14,
          Paint()
            ..color = const Color(0xffe7d3ff).withValues(alpha: 0.8 * fade));
    }
  }

  void _drawBushes(Canvas canvas, List<Vec2i> bushes) {
    final p = _palette;
    for (final b in bushes) {
      final cx = b.x * tile, cy = b.y * tile;
      // Tinted base fills the cell so adjacent cover tiles merge into one patch.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(cx, cy, tile, tile), const Radius.circular(7)),
        Paint()..color = p.bushBase,
      );
      final rnd = Random(b.x * 73856093 ^ b.y * 19349663);
      switch (p.bushKind) {
        case _BushKind.leaves:
          _drawLeafyBush(canvas, cx, cy, rnd, p);
        case _BushKind.mushrooms:
          _drawMushrooms(canvas, cx, cy, rnd, p);
        case _BushKind.embers:
          _drawEmberFungus(canvas, cx, cy, rnd, p);
        case _BushKind.cactus:
          _drawCactus(canvas, cx, cy, rnd, p);
      }
    }
  }

  void _drawLeafyBush(
      Canvas canvas, double cx, double cy, Random rnd, _BiomePalette p) {
    for (var i = 0; i < 7; i++) {
      final ox = cx + tile * (0.16 + rnd.nextDouble() * 0.68);
      final oy = cy + tile * (0.16 + rnd.nextDouble() * 0.68);
      final r = tile * (0.20 + rnd.nextDouble() * 0.16);
      final shade = [p.bushMid, p.bushLite, p.bushDark][i % 3];
      canvas.drawCircle(Offset(ox, oy), r, Paint()..color = shade);
    }
    for (var i = 0; i < 3; i++) {
      final ox = cx + tile * (0.3 + rnd.nextDouble() * 0.4);
      final oy = cy + tile * (0.3 + rnd.nextDouble() * 0.4);
      canvas.drawCircle(Offset(ox, oy), tile * 0.06,
          Paint()..color = p.bushLite.withValues(alpha: 0.6));
    }
  }

  void _drawMushrooms(
      Canvas canvas, double cx, double cy, Random rnd, _BiomePalette p) {
    for (var i = 0; i < 5; i++) {
      final mx = cx + tile * (0.16 + rnd.nextDouble() * 0.68);
      final my = cy + tile * (0.30 + rnd.nextDouble() * 0.50);
      final capR = tile * (0.20 + rnd.nextDouble() * 0.12);
      // Stem.
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(mx - capR * 0.28, my, capR * 0.56, capR * 1.1),
          Radius.circular(capR * 0.3),
        ),
        Paint()..color = p.bushLite.withValues(alpha: 0.85),
      );
      // Cap (half-dome) with a glow and pale spots.
      canvas.drawCircle(Offset(mx, my), capR * 1.5,
          Paint()..color = p.accent.withValues(alpha: 0.10));
      canvas.drawArc(
        Rect.fromCircle(center: Offset(mx, my), radius: capR),
        pi,
        pi,
        true,
        Paint()..color = p.bushMid,
      );
      canvas.drawCircle(Offset(mx - capR * 0.3, my - capR * 0.25), capR * 0.16,
          Paint()..color = p.bushLite);
      canvas.drawCircle(Offset(mx + capR * 0.35, my - capR * 0.1), capR * 0.12,
          Paint()..color = p.bushLite);
    }
  }

  void _drawEmberFungus(
      Canvas canvas, double cx, double cy, Random rnd, _BiomePalette p) {
    // Dark clustered fungus dotted with glowing embers.
    for (var i = 0; i < 6; i++) {
      final ox = cx + tile * (0.16 + rnd.nextDouble() * 0.68);
      final oy = cy + tile * (0.18 + rnd.nextDouble() * 0.64);
      canvas.drawCircle(Offset(ox, oy), tile * (0.16 + rnd.nextDouble() * 0.10),
          Paint()..color = p.bushDark);
    }
    for (var i = 0; i < 6; i++) {
      final ox = cx + tile * (0.18 + rnd.nextDouble() * 0.64);
      final oy = cy + tile * (0.18 + rnd.nextDouble() * 0.64);
      canvas.drawCircle(Offset(ox, oy), tile * 0.18,
          Paint()..color = p.accent.withValues(alpha: 0.18));
      canvas.drawCircle(Offset(ox, oy), tile * 0.07, Paint()..color = p.accent);
    }
  }

  void _drawCactus(
      Canvas canvas, double cx, double cy, Random rnd, _BiomePalette p) {
    final body = Paint()..color = p.bushMid;
    RRect stem(double x, double y, double w, double h) =>
        RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w, h), Radius.circular(w / 2));
    // Two or three cacti of varying height filling the cell.
    final count = 2 + rnd.nextInt(2);
    for (var i = 0; i < count; i++) {
      final mx = cx + tile * (0.22 + rnd.nextDouble() * 0.56);
      final baseY = cy + tile * (0.82 + rnd.nextDouble() * 0.12);
      final bodyH = tile * (0.52 + rnd.nextDouble() * 0.26);
      final bodyW = tile * (0.22 + rnd.nextDouble() * 0.08);
      canvas.drawRRect(stem(mx - bodyW / 2, baseY - bodyH, bodyW, bodyH), body);
      // One or two arms.
      if (rnd.nextBool()) {
        canvas.drawRRect(
            stem(mx - bodyW * 1.1, baseY - bodyH * 0.7, bodyW * 0.7,
                bodyH * 0.5),
            body);
      }
      if (rnd.nextBool()) {
        canvas.drawRRect(
            stem(mx + bodyW * 0.4, baseY - bodyH * 0.85, bodyW * 0.7,
                bodyH * 0.55),
            body);
      }
      // Subtle highlight ridge.
      canvas.drawRRect(
        stem(
            mx - bodyW * 0.18, baseY - bodyH * 0.95, bodyW * 0.16, bodyH * 0.8),
        Paint()..color = p.bushLite.withValues(alpha: 0.5),
      );
    }
  }

  /// Ice-biome crystals — standalone entities (not cover) that project player
  /// illusions. Drawn as a small upright cluster of glowing shards.
  void _drawCrystalEntities(Canvas canvas, List<Vec2i> crystals) {
    if (crystals.isEmpty) return;
    final p = _palette;
    for (final c in crystals) {
      final cx = c.x * tile, cy = c.y * tile;
      final rnd = Random(c.x * 92837111 ^ c.y * 689287499);
      // Soft ground glow.
      canvas.drawCircle(
        Offset(cx + tile / 2, cy + tile * 0.66),
        tile * 0.5,
        Paint()
          ..color = p.accent.withValues(alpha: 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      for (var i = 0; i < 3; i++) {
        final bx = cx + tile * (0.30 + rnd.nextDouble() * 0.40);
        final by = cy + tile * (0.80 + rnd.nextDouble() * 0.08);
        final h = tile * (0.50 + rnd.nextDouble() * 0.30);
        final w = h * (0.30 + rnd.nextDouble() * 0.12);
        final shard = Path()
          ..moveTo(bx, by - h)
          ..lineTo(bx + w, by - h * 0.4)
          ..lineTo(bx + w * 0.5, by)
          ..lineTo(bx - w * 0.5, by)
          ..lineTo(bx - w, by - h * 0.4)
          ..close();
        canvas.drawPath(
            shard, Paint()..color = (i.isOdd ? p.bushLite : p.bushMid));
        canvas.drawPath(
          shard,
          Paint()
            ..color = p.accent.withValues(alpha: 0.75)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
        canvas.drawLine(
          Offset(bx, by - h * 0.9),
          Offset(bx, by - h * 0.1),
          Paint()
            ..color = const Color(0x66ffffff)
            ..strokeWidth = 1,
        );
      }
    }
  }

  static const _crystalGlowFadeStart = 3.0;
  static const _crystalGlowMaxRange = 5.0;

  void _drawCrystalLinks(Canvas canvas, List<PlayerDto> players,
      List<IllusionDto> illusions, List<Vec2i> crystals) {
    if (crystals.isEmpty) return;
    for (final player in players) {
      final renderPos =
          _renderPlayers[player.id]?.position ?? Offset(player.x, player.y);
      final influence =
          _crystalInfluenceFor(renderPos.dx, renderPos.dy, crystals);
      if (influence == null) continue;
      _drawCrystalLink(canvas, Offset(renderPos.dx * tile, renderPos.dy * tile),
          influence.center, influence.opacity);
    }
    for (final illusion in illusions) {
      final influence = _crystalInfluenceFor(illusion.x, illusion.y, crystals);
      if (influence == null) continue;
      final opacity = influence.opacity * illusion.opacity.clamp(0.0, 1.0);
      _drawCrystalLink(canvas, Offset(illusion.x * tile, illusion.y * tile),
          influence.center, opacity);
    }
  }

  void _drawCrystalLink(Canvas canvas, Offset entityCenter,
      Offset crystalCenter, double opacity) {
    if (opacity <= 0.01) return;
    final start = entityCenter;
    final end = Offset(crystalCenter.dx * tile, crystalCenter.dy * tile);
    final line = Paint()
      ..color = const Color(0xff8fe6ff).withValues(alpha: 0.04 * opacity)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final core = Paint()
      ..color = const Color(0xffb9f4ff).withValues(alpha: 0.09 * opacity)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, line);
    canvas.drawLine(start, end, core);
  }

  void _drawSarcophagi(Canvas canvas, List<SarcophagusDto> sarcophagi) {
    for (final s in sarcophagi) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(s.x * tile + 3, s.y * tile + 3, tile - 6, tile - 6),
        const Radius.circular(5),
      );
      final base =
          s.hasMummy ? const Color(0xffa98048) : const Color(0xff6f5b3b);
      canvas.drawRRect(rect, Paint()..color = base);
      canvas.drawRRect(
        rect,
        Paint()
          ..color = const Color(0xffe5c47a).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final cx = s.x * tile;
      final cy = s.y * tile;
      final crack = Paint()
        ..color = const Color(0xff3a2817).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx + tile * 0.28, cy + tile * 0.16),
          Offset(cx + tile * 0.42, cy + tile * 0.55), crack);
      canvas.drawLine(Offset(cx + tile * 0.42, cy + tile * 0.55),
          Offset(cx + tile * 0.34, cy + tile * 0.84), crack);
      canvas.drawLine(Offset(cx + tile * 0.60, cy + tile * 0.18),
          Offset(cx + tile * 0.52, cy + tile * 0.48), crack);
      if (s.cracked && s.hasMummy) {
        _drawSkullSilhouette(canvas, Offset(cx + tile / 2, cy + tile / 2));
      }
      if (!s.hasMummy) {
        canvas.drawCircle(
          Offset(cx + tile / 2, cy + tile / 2),
          tile * 0.34,
          Paint()..color = const Color(0x66251610),
        );
      }
    }
  }

  void _drawSkullSilhouette(Canvas canvas, Offset center) {
    final paint = Paint()..color = const Color(0xcc24170f);
    canvas.drawCircle(center.translate(0, -tile * 0.08), tile * 0.22, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, tile * 0.12),
          width: tile * 0.28,
          height: tile * 0.24,
        ),
        const Radius.circular(3),
      ),
      paint,
    );
    final eye = Paint()..color = const Color(0xffd8b872);
    canvas.drawCircle(
        center.translate(-tile * 0.08, -tile * 0.08), tile * 0.04, eye);
    canvas.drawCircle(
        center.translate(tile * 0.08, -tile * 0.08), tile * 0.04, eye);
  }

  void _drawMummies(Canvas canvas, List<MummyDto> mummies) {
    for (final mummy in mummies) {
      final center = Offset(mummy.x * tile, mummy.y * tile);
      final aura =
          mummy.fleeing ? const Color(0x335dd8ff) : const Color(0x55ff4f38);
      canvas.drawCircle(
        center,
        tile * 0.55,
        Paint()
          ..color = aura
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawOval(
        Rect.fromCenter(
            center: center, width: tile * 0.72, height: tile * 0.92),
        Paint()..color = const Color(0xffc8b07a),
      );
      final wrap = Paint()
        ..color = const Color(0xfff0dfb0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (final off in const [-0.24, -0.08, 0.08, 0.24]) {
        canvas.drawLine(center.translate(-tile * 0.28, tile * off),
            center.translate(tile * 0.28, tile * (off + 0.10)), wrap);
      }
      final eye = Paint()..color = const Color(0xff25160c);
      canvas.drawCircle(
          center.translate(-tile * 0.10, -tile * 0.20), tile * 0.04, eye);
      canvas.drawCircle(
          center.translate(tile * 0.10, -tile * 0.20), tile * 0.04, eye);
    }
  }

  /// Crystal-projected illusions of players. At close range they must be
  /// indistinguishable from the real player; farther out the server fades them.
  void _drawIllusions(Canvas canvas, List<IllusionDto> illusions) {
    for (final ill in illusions) {
      final op = ill.opacity.clamp(0.0, 1.0);
      final fake = PlayerDto(
        id: 'illusion',
        slot: ill.slot,
        role: ill.slot == 1 ? PlayerRole.hunter : PlayerRole.leha,
        x: ill.x,
        y: ill.y,
        score: 0,
        powered: ill.powered,
        ghost: false,
        stunned: false,
        invulnerable: false,
        hp: 100,
        aspect: ill.aspect,
        hunterKind: ill.hunterKind,
        femboy: ill.femboy,
      );
      final center = Offset(ill.x * tile, ill.y * tile);
      final image = _imageForPlayer(fake);
      final size = _sizeForPlayer(fake, false);
      _drawCrystalGlow(canvas, center, size, op);
      _drawImage(canvas, image, center, size, op);
    }
  }

  void _drawCrystalGlow(
      Canvas canvas, Offset center, double size, double opacity) {
    if (opacity <= 0.02) return;
    canvas.drawCircle(
      center,
      size * 0.5,
      Paint()
        ..color = const Color(0xff8fe6ff).withValues(alpha: 0.14 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  _CrystalInfluence? _crystalInfluenceFor(
      double x, double y, List<Vec2i> crystals) {
    var best = double.infinity;
    Offset? center;
    for (final crystal in crystals) {
      final cx = crystal.x + 0.5;
      final cy = crystal.y + 0.5;
      final dx = x - cx;
      final dy = y - cy;
      final d = sqrt(dx * dx + dy * dy);
      if (d < best) {
        best = d;
        center = Offset(cx, cy);
      }
    }
    if (best == double.infinity || best < 0.5 || best >= _crystalGlowMaxRange) {
      return null;
    }
    final opacity = best <= _crystalGlowFadeStart
        ? 1.0
        : 1 -
            (best - _crystalGlowFadeStart) /
                (_crystalGlowMaxRange - _crystalGlowFadeStart);
    return _CrystalInfluence(center: center!, opacity: opacity.clamp(0.0, 1.0));
  }

  void _drawTrail(Canvas canvas, List<TrailPointDto> trail) {
    for (final point in trail) {
      final a = point.alpha.clamp(0.0, 1.0);
      final center = Offset(point.x * tile, point.y * tile);
      // Outer soft glow
      canvas.drawCircle(
        center,
        tile * (0.18 + a * 0.14),
        Paint()..color = Color.fromRGBO(255, 30, 90, a * 0.22),
      );
      // Core dot — brighter and smaller
      canvas.drawCircle(
        center,
        tile * (0.07 + a * 0.07),
        Paint()..color = Color.fromRGBO(255, 70, 130, a * 0.85),
      );
    }
  }

  void _drawLogos(Canvas canvas, List<LogoDto> logos, bool spiderMode) {
    for (final logo in logos) {
      final center = Offset(logo.x * tile + tile / 2, logo.y * tile + tile / 2);
      // Spider mode: the collectibles are Raffaellos, not TikTok logos.
      if (spiderMode) {
        final rafaelka = rafaelkaImage;
        if (rafaelka != null) {
          _drawImage(canvas, rafaelka, center, tile * 0.82, 1);
        } else {
          canvas.drawCircle(
              center, tile * 0.3, Paint()..color = const Color(0xfffff3e0));
          canvas.drawCircle(
              center,
              tile * 0.3,
              Paint()
                ..color = const Color(0x55cc2222)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2);
        }
        continue;
      }
      final size = logo.power ? tile * 0.92 : tile * 0.25;
      if (logo.power) {
        canvas.drawCircle(
          center,
          tile * 0.68,
          Paint()
            ..color = const Color(0x6600f2ea)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      _drawImage(canvas, logoImage, center, size, 1);
    }
  }

  /// The Spider's egg clutch — grows as it nears hatching. Uses clutch.png if
  /// present, otherwise a procedural nest of eggs.
  void _drawClutch(Canvas canvas, ClutchDto? clutch) {
    if (clutch == null) return;
    final center =
        Offset(clutch.x * tile + tile / 2, clutch.y * tile + tile / 2);
    // hatchMs counts down from 20000 → 0; grow from 55% to full as it ripens.
    final ripeness = (1.0 - (clutch.hatchMs / 20000)).clamp(0.0, 1.0);
    final scale = 0.55 + 0.45 * ripeness;
    // Pulsing aura so it's noticeable.
    canvas.drawCircle(center, tile * (0.55 + 0.1 * ripeness),
        Paint()..color = Color.fromRGBO(120, 230, 150, 0.18 + 0.12 * ripeness));
    final img = clutchImage;
    if (img != null) {
      _drawImage(canvas, img, center, tile * scale, 1);
      return;
    }
    // Procedural nest: a brown nest with three white eggs.
    canvas.drawCircle(
        center, tile * 0.42 * scale, Paint()..color = const Color(0xff6b4a2b));
    canvas.drawCircle(
        center, tile * 0.34 * scale, Paint()..color = const Color(0xff8a6239));
    final eggPaint = Paint()..color = const Color(0xfff5f0e6);
    for (final off in [
      const Offset(-0.16, 0.04),
      const Offset(0.16, 0.04),
      const Offset(0, -0.16)
    ]) {
      final c = center + Offset(off.dx * tile * scale, off.dy * tile * scale);
      canvas.drawOval(
        Rect.fromCenter(
            center: c, width: tile * 0.22 * scale, height: tile * 0.3 * scale),
        eggPaint,
      );
    }
  }

  void _drawTraps(Canvas canvas, List<TrapDto> traps) {
    for (final trap in traps) {
      final center = Offset(trap.x * tile + tile / 2, trap.y * tile + tile / 2);
      if (trap.triggered) {
        // Triggered: bright expanding flash for Hunter's catch notification.
        canvas.drawCircle(
            center, tile * 0.55, Paint()..color = const Color(0x55ffaa00));
        canvas.drawCircle(
          center,
          tile * 0.55,
          Paint()
            ..color = const Color(0xffffaa00)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        canvas.drawCircle(
            center, tile * 0.22, Paint()..color = const Color(0xccffcc44));
      } else if (trapImage != null) {
        // Faint danger ring under the steel trap sprite.
        canvas.drawCircle(
            center, tile * 0.5, Paint()..color = const Color(0x33ff0050));
        _drawImage(canvas, trapImage!, center, tile * 1.1, 1);
      } else {
        canvas.drawCircle(
            center, tile * 0.36, Paint()..color = const Color(0x44ff0050));
        canvas.drawCircle(
          center,
          tile * 0.36,
          Paint()
            ..color = const Color(0xccff0050)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
    }
  }

  void _drawWebs(Canvas canvas, List<WebDto> webs) {
    final image = webImage;
    if (image != null) {
      for (final web in webs) {
        final center = Offset(web.x * tile + tile / 2, web.y * tile + tile / 2);
        _drawImage(canvas, image, center, tile * 1.02, 0.92);
      }
      return;
    }
    // Fallback: procedural web.
    final fill = Paint()..color = const Color(0x5588f4ff);
    final stroke = Paint()
      ..color = const Color(0xaae7fbff)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final web in webs) {
      final rect =
          Rect.fromLTWH(web.x * tile + 4, web.y * tile + 4, tile - 8, tile - 8);
      canvas.drawRect(rect, fill);
      canvas.drawLine(rect.topLeft, rect.bottomRight, stroke);
      canvas.drawLine(rect.topRight, rect.bottomLeft, stroke);
      canvas.drawRect(rect, stroke);
    }
  }

  void _drawPortals(Canvas canvas, List<PortalDto> portals) {
    final t = DateTime.now().millisecondsSinceEpoch;
    for (final portal in portals) {
      final center =
          Offset(portal.x * tile + tile / 2, portal.y * tile + tile / 2);
      final image = portal.active ? portalActiveImage : portalInactiveImage;
      if (image != null) {
        if (portal.active) {
          // Active: pulsing violet glow + slow spin.
          final pulse = 0.5 + 0.5 * sin(t / 300.0);
          canvas.drawCircle(
            center,
            tile * (0.5 + 0.08 * pulse),
            Paint()
              ..color = Color.fromRGBO(181, 108, 255, 0.22 + 0.16 * pulse)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
          );
          canvas.save();
          canvas.translate(center.dx, center.dy);
          canvas.rotate(t / 1300.0);
          _drawImage(canvas, image, Offset.zero, tile * 1.05, 1);
          canvas.restore();
        } else {
          // Inactive: dim, static, slightly transparent.
          _drawImage(canvas, image, center, tile * 0.92, 0.7);
        }
        continue;
      }
      // Fallback: procedural rings.
      final color =
          portal.active ? const Color(0xffb56cff) : const Color(0xff6f7890);
      canvas.drawCircle(
        center,
        tile * 0.42,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      canvas.drawCircle(
          center, tile * 0.18, Paint()..color = color.withValues(alpha: 0.28));
    }
  }

  void _drawPlayers(Canvas canvas, List<PlayerDto> players, String myId,
      List<Vec2i> crystals) {
    for (final player in players) {
      final renderPos =
          _renderPlayers[player.id]?.position ?? Offset(player.x, player.y);
      final center = Offset(renderPos.dx * tile, renderPos.dy * tile);
      final image = _imageForPlayer(player);
      final size = _sizeForPlayer(player, player.id == myId);
      _drawCrystalGlow(
        canvas,
        center,
        size,
        _crystalInfluenceFor(renderPos.dx, renderPos.dy, crystals)?.opacity ??
            0,
      );
      if (player.femboy) {
        _drawFemboyAura(canvas, center, size);
      }
      _drawImage(canvas, image, center, size, player.ghost ? 0.42 : 1);
      if (player.femboy) {
        _drawHearts(canvas, center, size);
      }
      if (player.facing != null) {
        _drawFacingIndicator(canvas, center, player.facing!);
      }
      if (player.stunned) {
        _drawStun(canvas, center, size);
      }
      if (player.invulnerable) {
        canvas.drawCircle(
          center,
          size * 0.58,
          Paint()
            ..color = const Color(0x99ffffff)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  /// Soft pulsing pink aura under Sima while in femboy form.
  void _drawFemboyAura(Canvas canvas, Offset center, double size) {
    final t = DateTime.now().millisecondsSinceEpoch;
    final pulse = 0.5 + 0.5 * sin(t / 260.0);
    final r = size * (0.55 + 0.12 * pulse);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = Color.fromRGBO(255, 90, 160, 0.18 + 0.12 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  /// Lots of little hearts swirling up around Sima while in femboy form.
  void _drawHearts(Canvas canvas, Offset center, double size) {
    final t = DateTime.now().millisecondsSinceEpoch;
    const count = 16;
    const periodMs = 1700;
    for (var i = 0; i < count; i++) {
      final phase = ((t / periodMs) + i / count) % 1.0;
      final ang = i * (2 * pi / count) + t / 1400.0;
      final spread = size * (0.30 + 0.45 * phase);
      final wobble = sin(t / 300.0 + i) * size * 0.04;
      final p = center +
          Offset(cos(ang) * spread + wobble,
              sin(ang) * spread * 0.5 - size * (0.2 + phase * 1.15));
      final a = sin(phase * pi); // fade in then out
      if (a <= 0.02) continue;
      final s = size * (0.11 + 0.05 * a);
      final color = switch (i % 3) {
        0 => const Color(0xffff5fa2),
        1 => const Color(0xffff2d55),
        _ => const Color(0xffff8fc0),
      };
      _drawHeart(canvas, p, s, color.withValues(alpha: a));
    }
  }

  void _drawHeart(Canvas canvas, Offset c, double s, Color color) {
    final paint = Paint()..color = color;
    // soft glow
    canvas.drawCircle(
        c, s * 1.15, Paint()..color = color.withValues(alpha: color.a * 0.3));
    final r = s * 0.5;
    canvas.drawCircle(c + Offset(-r * 0.55, -r * 0.25), r * 0.62, paint);
    canvas.drawCircle(c + Offset(r * 0.55, -r * 0.25), r * 0.62, paint);
    final path = Path()
      ..moveTo(c.dx - r * 1.05, c.dy - r * 0.12)
      ..lineTo(c.dx, c.dy + r * 1.15)
      ..lineTo(c.dx + r * 1.05, c.dy - r * 0.12)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _drawFacingIndicator(Canvas canvas, Offset center, MoveDirection dir) {
    const r = tile * 0.52;
    const dotR = tile * 0.10;
    final dot = center + Offset(dir.dx * r, dir.dy * r);
    canvas.drawCircle(dot, dotR, Paint()..color = const Color(0xccffffff));
  }

  Image _imageForPlayer(PlayerDto player) {
    if (player.powered) {
      return poweredHead;
    }
    if (player.slot == 1) {
      if (player.hunterKind == HunterKind.sashaYakuza && sashaHead != null) {
        return sashaHead!;
      }
      if (player.hunterKind == HunterKind.sima) {
        if (player.femboy && simaFemboy != null) {
          return simaFemboy!;
        }
        return simaHead ?? chaserHead;
      }
      return chaserHead;
    }
    return switch (player.aspect) {
      LehaAspect.spider => spiderHead,
      LehaAspect.wizard => wizardHead,
      _ => playerHead,
    };
  }

  double _sizeForPlayer(PlayerDto player, bool isMe) {
    if (player.powered) {
      return tile * 1.72;
    }
    if (player.aspect == LehaAspect.spider) {
      return tile * 2.02;
    }
    if (player.aspect == LehaAspect.wizard) {
      return tile * 1.36;
    }
    if (player.slot == 1 && player.hunterKind == HunterKind.sashaYakuza) {
      return tile * 1.7;
    }
    // Sima reads small at default scale — bump her up in both forms.
    if (player.slot == 1 && player.hunterKind == HunterKind.sima) {
      return tile * 1.7;
    }
    return isMe ? tile * 1.08 : tile * 1.02;
  }

  void _drawStun(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = const Color(0xfffff06a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center.translate(0, -size * 0.58), size * 0.18, paint);
    canvas.drawCircle(
        center.translate(size * 0.18, -size * 0.54), size * 0.1, paint);
  }

  void _drawImage(
      Canvas canvas, Image image, Offset center, double size, double opacity) {
    final paint = Paint()..color = Color.fromRGBO(255, 255, 255, opacity);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromCenter(center: center, width: size, height: size),
      paint,
    );
  }

  /// Combines currently held axis keys into a single direction (incl. diagonals).
  MoveDirection? _combinedDirection() {
    final dirs = _heldKeys.values.toSet();
    final hasUp = dirs.contains(MoveDirection.up);
    final hasDown = dirs.contains(MoveDirection.down);
    final hasLeft = dirs.contains(MoveDirection.left);
    final hasRight = dirs.contains(MoveDirection.right);
    final up = hasUp && !hasDown;
    final down = hasDown && !hasUp;
    final left = hasLeft && !hasRight;
    final right = hasRight && !hasLeft;
    if (up && left) {
      return MoveDirection.upLeft;
    }
    if (up && right) {
      return MoveDirection.upRight;
    }
    if (down && left) {
      return MoveDirection.downLeft;
    }
    if (down && right) {
      return MoveDirection.downRight;
    }
    if (up) {
      return MoveDirection.up;
    }
    if (down) {
      return MoveDirection.down;
    }
    if (left) {
      return MoveDirection.left;
    }
    if (right) {
      return MoveDirection.right;
    }
    return null;
  }

  HunterKind? _myHunterKind(GameSnapshotDto? snapshot) {
    if (snapshot == null) {
      return null;
    }
    final me =
        snapshot.players.where((p) => p.id == snapshot.you.id).firstOrNull;
    if (me?.hunterKind != null) return me!.hunterKind;
    return snapshot.lobby.roles
        .where((r) => r.role == PlayerRole.hunter)
        .firstOrNull
        ?.hunterKind;
  }

  MoveDirection? _directionForKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      return MoveDirection.up;
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      return MoveDirection.down;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      return MoveDirection.left;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      return MoveDirection.right;
    }
    return null;
  }
}

/// The cover motif drawn for a biome's bushes.
enum _BushKind { leaves, mushrooms, embers, cactus }

class _PlayerRenderState {
  _PlayerRenderState({required this.position}) : target = position;

  Offset position;
  Offset target;
  Offset velocity = Offset.zero;
  int snapshotVersion = 0;
  int sampleMs = 0;
  bool initialized = false;

  void acceptSnapshot(Offset nextTarget, int version, int receivedMs) {
    if (sampleMs > 0 && receivedMs > sampleMs) {
      final dt = (receivedMs - sampleMs) / 1000.0;
      final measured = Offset(
        (nextTarget.dx - target.dx) / dt,
        (nextTarget.dy - target.dy) / dt,
      );
      final speed = measured.distance;
      // Teleports, tunnel wraps, and visibility re-entry should not poison the
      // predictor with a huge velocity.
      velocity = speed > 12 ? Offset.zero : measured;
    } else {
      velocity = Offset.zero;
    }
    target = nextTarget;
    snapshotVersion = version;
    sampleMs = receivedMs;
  }
}

class _CrystalInfluence {
  const _CrystalInfluence({required this.center, required this.opacity});

  final Offset center;
  final double opacity;
}

/// Resolved colours for a cave theme. Stone hue is jittered by a per-map seed so
/// two caves of the same biome still look distinct, while staying within a
/// tasteful, muted range.
class _BiomePalette {
  const _BiomePalette({
    required this.background,
    required this.wall,
    required this.wallEdge,
    required this.crackDark,
    required this.accent,
    required this.bushKind,
    required this.bushBase,
    required this.bushDark,
    required this.bushMid,
    required this.bushLite,
  });

  final Color background;
  final Color wall;
  final Color wallEdge;
  final Color crackDark;
  final Color accent;
  final _BushKind bushKind;
  final Color bushBase;
  final Color bushDark;
  final Color bushMid;
  final Color bushLite;

  static Color _hsv(double h, double s, double v) =>
      HSVColor.fromAHSV(1, h % 360, s.clamp(0.0, 1.0), v.clamp(0.0, 1.0))
          .toColor();

  factory _BiomePalette.build(CaveBiome biome, int seed) {
    final rnd = Random(seed);
    double jitter(double deg) => (rnd.nextDouble() * 2 - 1) * deg;

    // Per-biome: stone hue + saturation/value, an accent colour, the bush motif
    // and the bush's own hue/saturation.
    late double stoneHue, stoneSat, stoneVal, bushHue, bushSat;
    late Color accent;
    late _BushKind kind;
    switch (biome) {
      case CaveBiome.forest:
        stoneHue = 145;
        stoneSat = 0.26;
        stoneVal = 0.34;
        accent = const Color(0xff6fe3a0);
        kind = _BushKind.leaves;
        bushHue = 135;
        bushSat = 0.55;
      case CaveBiome.amethyst:
        stoneHue = 278;
        stoneSat = 0.34;
        stoneVal = 0.33;
        accent = const Color(0xffc77dff);
        kind = _BushKind.mushrooms;
        bushHue = 290;
        bushSat = 0.52;
      case CaveBiome.ember:
        stoneHue = 16;
        stoneSat = 0.34;
        stoneVal = 0.29;
        accent = const Color(0xffff9d4d);
        kind = _BushKind.embers;
        bushHue = 24;
        bushSat = 0.70;
      case CaveBiome.frost:
        stoneHue = 202;
        stoneSat = 0.26;
        stoneVal = 0.42;
        accent = const Color(0xff8fe6ff);
        // Frost has crystal *entities* instead of bushes; this kind is unused
        // (no bushes spawn) but bushMid/bushLite still colour the crystals.
        kind = _BushKind.leaves;
        bushHue = 198;
        bushSat = 0.42;
      case CaveBiome.sandstone:
        stoneHue = 38;
        stoneSat = 0.34;
        stoneVal = 0.44;
        accent = const Color(0xffe6c270);
        kind = _BushKind.cactus;
        bushHue = 96;
        bushSat = 0.42;
    }

    final h = (stoneHue + jitter(14)) % 360;
    final v = (stoneVal + jitter(0.04)).clamp(0.2, 0.6);
    final wall = _hsv(h, stoneSat, v);
    final background = _hsv(h, (stoneSat * 0.85).clamp(0.0, 1.0), 0.09);
    final wallEdge = accent.withValues(alpha: 0.30);
    final crackDark =
        _hsv(h, (stoneSat + 0.1).clamp(0.0, 1.0), (v * 0.32).clamp(0.05, 0.2))
            .withValues(alpha: 0.87);

    // Bush shades share the bush hue, jittered slightly so patches feel organic.
    final bh = (bushHue + jitter(10)) % 360;
    final bushBase = _hsv(bh, (bushSat * 0.9).clamp(0.0, 1.0), 0.22);
    final bushDark = _hsv(bh, bushSat, 0.32);
    final bushMid = _hsv(bh, bushSat, 0.50);
    final bushLite = _hsv(bh, (bushSat * 0.85).clamp(0.0, 1.0), 0.68);

    return _BiomePalette(
      background: background,
      wall: wall,
      wallEdge: wallEdge,
      crackDark: crackDark,
      accent: accent,
      bushKind: kind,
      bushBase: bushBase,
      bushDark: bushDark,
      bushMid: bushMid,
      bushLite: bushLite,
    );
  }
}
