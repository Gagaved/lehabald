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

  @override
  Future<void> onLoad() async {
    playerHead = await images.load('player-head.png');
    chaserHead = await images.load('chaser-head.png');
    poweredHead = await images.load('leha-powered.png');
    spiderHead = await images.load('leha-spider.png');
    wizardHead = await images.load('leha-wizard.png');
    logoImage = await images.load('tiktok-logo.png');
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
    _drawTrail(canvas, snapshot.trail);
    _drawWebs(canvas, snapshot.webs);
    _drawLogos(canvas, snapshot.logos);
    _drawPortals(canvas, snapshot.portals);
    _drawTraps(canvas, snapshot.traps);
    _drawPlayers(canvas, snapshot.players, snapshot.you.id);

    canvas.restore();
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent && event is! KeyUpEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.space && event is KeyDownEvent) {
      final snapshot = network.snapshot;
      if (snapshot?.you.role == PlayerRole.bakhirkin) {
        network.placeTrap();
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
      final size = logo.power ? tile * 0.92 : tile * 0.5;
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
        // Triggered: bright expanding flash for Bakhirkin's catch notification.
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
    for (final portal in portals) {
      final center = Offset(portal.x * tile + tile / 2, portal.y * tile + tile / 2);
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
      _drawImage(canvas, image, center, size, player.ghost ? 0.42 : 1);
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

  void _drawFacingIndicator(Canvas canvas, Offset center, MoveDirection dir) {
    const r = tile * 0.52;
    const dotR = tile * 0.10;
    final dot = center + Offset(dir.dx * r, dir.dy * r);
    canvas.drawCircle(dot, dotR, Paint()..color = const Color(0xccffffff));
  }

  Image _imageForPlayer(PlayerDto player) {
    if (player.powered) return poweredHead;
    if (player.slot == 1) return chaserHead;
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

  MoveDirection? _directionForKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) return MoveDirection.up;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) return MoveDirection.down;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) return MoveDirection.left;
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) return MoveDirection.right;
    return null;
  }
}
