import 'dart:math';
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;
import 'package:leha_bald_shared/leha_bald_shared.dart';

import '../net/game_network_client.dart';

class LehaBaldGame extends FlameGame with KeyboardEvents {
  LehaBaldGame({required this.network});

  static const tile = 32.0;
  final GameNetworkClient network;
  final _heldKeys = <LogicalKeyboardKey, MoveDirection>{};

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

  @override
  Future<void> onLoad() async {
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
  }

  Future<Image?> _tryLoad(String name) async {
    try {
      return await images.load(name);
    } catch (_) {
      return null;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final snapshot = network.snapshot;
    if (snapshot == null) {
      _drawEmpty(canvas);
      return;
    }

    final scale = min(size.x / (snapshot.cols * tile), size.y / (snapshot.rows * tile));
    final boardW = snapshot.cols * tile * scale;
    final boardH = snapshot.rows * tile * scale;
    final dx = (size.x - boardW) / 2;
    final dy = (size.y - boardH) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    _drawBoard(canvas, snapshot);
    _drawBushes(canvas, snapshot.bushes);
    _drawTrail(canvas, snapshot.trail);
    _drawWebs(canvas, snapshot.webs);
    _drawLogos(canvas, snapshot.logos);
    _drawPortals(canvas, snapshot.portals);
    _drawTraps(canvas, snapshot.traps);
    _drawBarrels(canvas, snapshot.barrels);
    _drawPlayers(canvas, snapshot.players, snapshot.you.id);
    _drawBlindFog(canvas, snapshot);

    canvas.restore();
  }

  /// When Leha is hit by a barrel his sight collapses to a small radius:
  /// everything outside it is covered by darkness.
  void _drawBlindFog(Canvas canvas, GameSnapshotDto snapshot) {
    final me = snapshot.players.where((p) => p.id == snapshot.you.id).firstOrNull;
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
        final rect = Rect.fromCenter(center: Offset.zero, width: tile * 0.8, height: tile * 0.96);
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

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent && event is! KeyUpEvent) return KeyEventResult.ignored;

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
      return KeyEventResult.handled;
    }

    if ((event.logicalKey == LogicalKeyboardKey.keyE || event.logicalKey == LogicalKeyboardKey.keyQ) && event is KeyDownEvent) {
      network.useAbility();
      return KeyEventResult.handled;
    }

    final direction = _directionForKey(event.logicalKey);
    if (direction == null) return KeyEventResult.ignored;

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
    return KeyEventResult.handled;
  }

  void _drawEmpty(Canvas canvas) {
    canvas.drawColor(const Color(0xff05070d), BlendMode.src);
  }

  void _drawBoard(Canvas canvas, GameSnapshotDto snapshot) {
    final bg = Paint()..color = const Color(0xff090d17);
    canvas.drawRect(Rect.fromLTWH(0, 0, snapshot.cols * tile, snapshot.rows * tile), bg);
    final wallPaint = Paint()..color = const Color(0xff123869);
    final stroke = Paint()
      ..color = const Color(0x5500f2ea)
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

  void _drawBushes(Canvas canvas, List<Vec2i> bushes) {
    for (final b in bushes) {
      final cx = b.x * tile, cy = b.y * tile;
      // Dark green base fills the cell so adjacent bush tiles read as one patch.
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx, cy, tile, tile), const Radius.circular(7)),
        Paint()..color = const Color(0xff184d2b),
      );
      // Deterministic clustered foliage blobs (stable per cell).
      final rnd = Random(b.x * 73856093 ^ b.y * 19349663);
      for (var i = 0; i < 5; i++) {
        final ox = cx + tile * (0.22 + rnd.nextDouble() * 0.56);
        final oy = cy + tile * (0.22 + rnd.nextDouble() * 0.56);
        final r = tile * (0.16 + rnd.nextDouble() * 0.15);
        final shade = const [Color(0xff2f8a4a), Color(0xff37a155), Color(0xff268040)][i % 3];
        canvas.drawCircle(Offset(ox, oy), r, Paint()..color = shade);
      }
      // A couple of bright highlights for depth.
      for (var i = 0; i < 2; i++) {
        final ox = cx + tile * (0.3 + rnd.nextDouble() * 0.4);
        final oy = cy + tile * (0.3 + rnd.nextDouble() * 0.4);
        canvas.drawCircle(Offset(ox, oy), tile * 0.06, Paint()..color = const Color(0x886fe39a));
      }
    }
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

  void _drawLogos(Canvas canvas, List<LogoDto> logos) {
    for (final logo in logos) {
      final size = logo.power ? tile * 0.92 : tile * 0.25;
      final center = Offset(logo.x * tile + tile / 2, logo.y * tile + tile / 2);
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

  void _drawTraps(Canvas canvas, List<TrapDto> traps) {
    for (final trap in traps) {
      final center = Offset(trap.x * tile + tile / 2, trap.y * tile + tile / 2);
      if (trap.triggered) {
        // Triggered: bright expanding flash for Hunter's catch notification.
        canvas.drawCircle(center, tile * 0.55, Paint()..color = const Color(0x55ffaa00));
        canvas.drawCircle(
          center,
          tile * 0.55,
          Paint()
            ..color = const Color(0xffffaa00)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        canvas.drawCircle(center, tile * 0.22, Paint()..color = const Color(0xccffcc44));
      } else if (trapImage != null) {
        // Faint danger ring under the steel trap sprite.
        canvas.drawCircle(center, tile * 0.5, Paint()..color = const Color(0x33ff0050));
        _drawImage(canvas, trapImage!, center, tile * 1.1, 1);
      } else {
        canvas.drawCircle(center, tile * 0.36, Paint()..color = const Color(0x44ff0050));
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
      final rect = Rect.fromLTWH(web.x * tile + 4, web.y * tile + 4, tile - 8, tile - 8);
      canvas.drawRect(rect, fill);
      canvas.drawLine(rect.topLeft, rect.bottomRight, stroke);
      canvas.drawLine(rect.topRight, rect.bottomLeft, stroke);
      canvas.drawRect(rect, stroke);
    }
  }

  void _drawPortals(Canvas canvas, List<PortalDto> portals) {
    final t = DateTime.now().millisecondsSinceEpoch;
    for (final portal in portals) {
      final center = Offset(portal.x * tile + tile / 2, portal.y * tile + tile / 2);
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
      final color = portal.active ? const Color(0xffb56cff) : const Color(0xff6f7890);
      canvas.drawCircle(
        center,
        tile * 0.42,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      canvas.drawCircle(center, tile * 0.18, Paint()..color = color.withValues(alpha: 0.28));
    }
  }

  void _drawPlayers(Canvas canvas, List<PlayerDto> players, String myId) {
    for (final player in players) {
      final center = Offset(player.x * tile, player.y * tile);
      final image = _imageForPlayer(player);
      final size = _sizeForPlayer(player, player.id == myId);
      if (player.femboy) _drawFemboyAura(canvas, center, size);
      _drawImage(canvas, image, center, size, player.ghost ? 0.42 : 1);
      if (player.femboy) _drawHearts(canvas, center, size);
      if (player.facing != null) _drawFacingIndicator(canvas, center, player.facing!);
      if (player.stunned) _drawStun(canvas, center, size);
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
          Offset(cos(ang) * spread + wobble, sin(ang) * spread * 0.5 - size * (0.2 + phase * 1.15));
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
    canvas.drawCircle(c, s * 1.15, Paint()..color = color.withValues(alpha: color.a * 0.3));
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
    if (player.powered) return poweredHead;
    if (player.slot == 1) {
      if (player.hunterKind == HunterKind.sashaYakuza && sashaHead != null) return sashaHead!;
      if (player.hunterKind == HunterKind.sima) {
        if (player.femboy && simaFemboy != null) return simaFemboy!;
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
    if (player.powered) return tile * 1.72;
    if (player.aspect == LehaAspect.spider) return tile * 2.02;
    if (player.aspect == LehaAspect.wizard) return tile * 1.36;
    if (player.slot == 1 && player.hunterKind == HunterKind.sashaYakuza) return tile * 1.7;
    return isMe ? tile * 1.08 : tile * 1.02;
  }

  void _drawStun(Canvas canvas, Offset center, double size) {
    final paint = Paint()
      ..color = const Color(0xfffff06a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center.translate(0, -size * 0.58), size * 0.18, paint);
    canvas.drawCircle(center.translate(size * 0.18, -size * 0.54), size * 0.1, paint);
  }

  void _drawImage(Canvas canvas, Image image, Offset center, double size, double opacity) {
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
    final hasUp    = dirs.contains(MoveDirection.up);
    final hasDown  = dirs.contains(MoveDirection.down);
    final hasLeft  = dirs.contains(MoveDirection.left);
    final hasRight = dirs.contains(MoveDirection.right);
    final up    = hasUp    && !hasDown;
    final down  = hasDown  && !hasUp;
    final left  = hasLeft  && !hasRight;
    final right = hasRight && !hasLeft;
    if (up    && left)  return MoveDirection.upLeft;
    if (up    && right) return MoveDirection.upRight;
    if (down  && left)  return MoveDirection.downLeft;
    if (down  && right) return MoveDirection.downRight;
    if (up)    return MoveDirection.up;
    if (down)  return MoveDirection.down;
    if (left)  return MoveDirection.left;
    if (right) return MoveDirection.right;
    return null;
  }

  HunterKind? _myHunterKind(GameSnapshotDto? snapshot) {
    if (snapshot == null) return null;
    final me = snapshot.players.where((p) => p.id == snapshot.you.id).firstOrNull;
    if (me?.hunterKind != null) return me!.hunterKind;
    return snapshot.lobby.roles
        .where((r) => r.role == PlayerRole.hunter)
        .firstOrNull
        ?.hunterKind;
  }

  MoveDirection? _directionForKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) return MoveDirection.up;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) return MoveDirection.down;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) return MoveDirection.left;
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) return MoveDirection.right;
    return null;
  }
}
