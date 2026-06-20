part of '../leha_bald_game.dart';

/// Reconciles server portal DTOs with long-lived Flame components.
class _PortalLayerComponent extends Component {
  final Map<String, _PortalComponent> _portals = {};

  void sync(List<PortalDto> portals) {
    final seen = <String>{};
    for (final dto in portals) {
      final key = '${dto.x},${dto.y}';
      seen.add(key);
      final current = _portals[key];
      if (current == null) {
        final portal = _PortalComponent(
          dto: dto,
          onClosed: (component) {
            if (identical(_portals[key], component)) _portals.remove(key);
          },
        );
        _portals[key] = portal;
        add(portal);
      } else {
        current.sync(dto);
      }
    }
    for (final entry in _portals.entries.toList()) {
      if (!seen.contains(entry.key)) entry.value.close();
    }
  }
}

/// A portal is now a real FCS entity: position, scale animation, lifecycle and
/// rendering are encapsulated instead of being branches in the game painter.
class _PortalComponent extends PositionComponent
    with HasGameReference<LehaBaldGame> {
  _PortalComponent({
    required PortalDto dto,
    required this.onClosed,
  })  : _index = dto.index,
        _active = dto.active,
        super(
          position: Vector2(
            (dto.x + 0.5) * LehaBaldGame.tile,
            (dto.y + 0.5) * LehaBaldGame.tile,
          ),
          size: Vector2.all(LehaBaldGame.tile),
          anchor: Anchor.center,
        );

  final void Function(_PortalComponent component) onClosed;
  int _index;
  bool _active;
  bool _closing = false;

  static final _stoneFill = Paint();
  static final _stoneStroke = Paint()
    ..color = const Color(0xff0a0911)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  static final _aperturePaint = Paint()..color = const Color(0xff030207);

  @override
  void onLoad() {
    scale.setZero();
    add(
      ScaleEffect.to(
        Vector2.all(1),
        EffectController(duration: 0.38, curve: Curves.easeOutBack),
      ),
    );
  }

  void sync(PortalDto dto) {
    _index = dto.index;
    _active = dto.active;
    if (_closing) {
      _closing = false;
      removeAll(children.whereType<ScaleEffect>().toList());
      add(
        ScaleEffect.to(
          Vector2.all(1),
          EffectController(duration: 0.2, curve: Curves.easeOut),
        ),
      );
    }
  }

  void close() {
    if (_closing) return;
    _closing = true;
    removeAll(children.whereType<ScaleEffect>().toList());
    add(
      ScaleEffect.to(
        Vector2.zero(),
        EffectController(duration: 0.28, curve: Curves.easeInBack),
        onComplete: () {
          onClosed(this);
          removeFromParent();
        },
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final direction = _index.isEven ? 1.0 : -1.0;
    final time = game._visualTime;
    final spin = time * (_active ? 1.9 : 0.55) * direction;
    final hue = (time * 42) % 360;
    final primary = HSVColor.fromAHSV(1, hue, 0.76, 1).toColor();
    final secondary =
        HSVColor.fromAHSV(1, (hue + 115) % 360, 0.82, 1).toColor();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    _drawStoneRim(canvas, spin);
    canvas.drawCircle(Offset.zero, LehaBaldGame.tile * 0.32, _aperturePaint);
    canvas.drawCircle(
      Offset.zero,
      LehaBaldGame.tile * 0.335,
      Paint()
        ..color =
            _active ? primary.withValues(alpha: 0.8) : const Color(0xff77758a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );

    if (_active) {
      _drawTunnel(canvas, spin, direction, primary, secondary);
    } else {
      _drawWaitingPortal(canvas, spin, time);
    }
    canvas.restore();
  }

  void _drawStoneRim(Canvas canvas, double spin) {
    for (var i = 0; i < 10; i++) {
      final angle = i * pi * 2 / 10 + spin * 0.08;
      final radial = Offset(cos(angle), sin(angle));
      final tangent = Offset(-radial.dy, radial.dx);
      final center = radial * LehaBaldGame.tile * 0.39;
      final halfWidth = LehaBaldGame.tile * 0.105;
      final halfHeight = LehaBaldGame.tile * 0.075;
      final a = center + tangent * halfWidth - radial * halfHeight;
      final b = center - tangent * halfWidth - radial * halfHeight;
      final c = center - tangent * halfWidth + radial * halfHeight;
      final d = center + tangent * halfWidth + radial * halfHeight;
      final stone = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(c.dx, c.dy)
        ..lineTo(d.dx, d.dy)
        ..close();
      _stoneFill.color = Color.lerp(
        const Color(0xff252338),
        const Color(0xff51456a),
        i / 18,
      )!;
      canvas.drawPath(stone, _stoneFill);
      canvas.drawPath(stone, _stoneStroke);
    }
  }

  void _drawTunnel(
    Canvas canvas,
    double spin,
    double direction,
    Color primary,
    Color secondary,
  ) {
    for (var ring = 0; ring < 3; ring++) {
      final radius = LehaBaldGame.tile * (0.25 - ring * 0.055);
      final phase = spin * (1 + ring * 0.32) + ring * 1.7;
      final paint = Paint()
        ..color = (ring.isEven ? primary : secondary)
            .withValues(alpha: 0.88 - ring * 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3 - ring * 0.4
        ..strokeCap = StrokeCap.round;
      for (var segment = 0; segment < 3; segment++) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: radius),
          phase + segment * pi * 2 / 3,
          pi * 0.33,
          false,
          paint,
        );
      }
    }
    for (var i = 0; i < 6; i++) {
      final travel = (game._visualTime * 0.9 + i / 6) % 1.0;
      final radius = LehaBaldGame.tile * (0.29 * (1 - travel));
      final angle = spin + i * pi * 2 / 6 + travel * 1.6 * direction;
      canvas.drawCircle(
        Offset(cos(angle), sin(angle)) * radius,
        LehaBaldGame.tile * (0.045 - travel * 0.025),
        Paint()
          ..color = Color.lerp(primary, secondary, travel)!
              .withValues(alpha: 1 - travel * 0.45),
      );
    }
    canvas.drawCircle(
      Offset.zero,
      LehaBaldGame.tile * 0.055,
      Paint()..color = const Color(0xfff4f2ff),
    );
  }

  void _drawWaitingPortal(Canvas canvas, double spin, double time) {
    final pulse = 0.5 + 0.5 * sin(time * 3.2);
    canvas.drawArc(
      Rect.fromCircle(center: Offset.zero, radius: LehaBaldGame.tile * 0.24),
      spin,
      pi * 1.35,
      false,
      Paint()
        ..color = const Color(0xff8f8aa3).withValues(alpha: 0.55 + pulse * 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset.zero,
      LehaBaldGame.tile * (0.11 + pulse * 0.025),
      Paint()
        ..color = const Color(0xff77758a).withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}
