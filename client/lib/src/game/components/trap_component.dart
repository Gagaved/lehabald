part of '../leha_bald_game.dart';

/// Reconciles Bakhirkin's traps. Traps sit on a fixed grid cell, so the cell is
/// their identity across snapshots.
class _TrapLayerComponent extends _ReconciledLayer<TrapDto, _TrapComponent> {
  _TrapLayerComponent({super.priority});

  @override
  Object keyOf(TrapDto dto) => '${dto.x},${dto.y}';

  @override
  _TrapComponent create(TrapDto dto) => _TrapComponent(dto: dto);

  @override
  void updateComponent(_TrapComponent component, TrapDto dto) =>
      component.sync(dto);
}

/// A single trap. The steel-jaw sprite (when the asset is present) is a Flame
/// [SpriteComponent]; the danger ring and the triggered flash are painted by the
/// component itself.
class _TrapComponent extends PositionComponent
    with HasGameReference<LehaBaldGame> {
  _TrapComponent({required TrapDto dto})
      : _triggered = dto.triggered,
        super(
          position: Vector2(
            (dto.x + 0.5) * LehaBaldGame.tile,
            (dto.y + 0.5) * LehaBaldGame.tile,
          ),
          size: Vector2.all(LehaBaldGame.tile),
          anchor: Anchor.center,
        );

  bool _triggered;
  SpriteComponent? _sprite;

  @override
  void onLoad() {
    final image = game.trapImage;
    if (image != null) {
      _sprite = SpriteComponent(
        sprite: Sprite(image),
        size: Vector2.all(LehaBaldGame.tile * 1.1),
        anchor: Anchor.center,
        position: size / 2,
      )..opacity = _triggered ? 0 : 1;
      add(_sprite!);
    }
  }

  void sync(TrapDto dto) {
    _triggered = dto.triggered;
    _sprite?.opacity = _triggered ? 0 : 1;
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    const tile = LehaBaldGame.tile;
    if (_triggered) {
      // Bright expanding flash for the Hunter's catch notification.
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
    } else if (_sprite != null) {
      // Faint danger ring under the steel-trap sprite (drawn by the child).
      canvas.drawCircle(
          center, tile * 0.5, Paint()..color = const Color(0x33ff0050));
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
