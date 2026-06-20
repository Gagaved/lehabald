part of '../leha_bald_game.dart';

/// Reconciles the Spider's webs. A web sits on a fixed grid cell.
class _WebLayerComponent extends _ReconciledLayer<WebDto, _WebComponent> {
  _WebLayerComponent({super.priority});

  @override
  Object keyOf(WebDto dto) => '${dto.x},${dto.y}';

  @override
  _WebComponent create(WebDto dto) => _WebComponent(dto: dto);

  @override
  void updateComponent(_WebComponent component, WebDto dto) {}
}

/// A single web. Uses the `web.png` sprite when present, otherwise a procedural
/// cobweb. Webs never change after spawning, so there is no per-frame sync.
class _WebComponent extends PositionComponent
    with HasGameReference<LehaBaldGame> {
  _WebComponent({required WebDto dto})
      : super(
          position: Vector2(
            (dto.x + 0.5) * LehaBaldGame.tile,
            (dto.y + 0.5) * LehaBaldGame.tile,
          ),
          size: Vector2.all(LehaBaldGame.tile),
          anchor: Anchor.center,
        );

  @override
  void onLoad() {
    final image = game.webImage;
    if (image != null) {
      add(SpriteComponent(
        sprite: Sprite(image),
        size: Vector2.all(LehaBaldGame.tile * 1.02),
        anchor: Anchor.center,
        position: size / 2,
      )..opacity = 0.92);
    }
  }

  @override
  void render(Canvas canvas) {
    if (game.webImage != null) return;
    // Fallback: procedural web in local coordinates.
    const tile = LehaBaldGame.tile;
    final fill = Paint()..color = const Color(0x5588f4ff);
    final stroke = Paint()
      ..color = const Color(0xaae7fbff)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rect = Rect.fromLTWH(4, 4, tile - 8, tile - 8);
    canvas.drawRect(rect, fill);
    canvas.drawLine(rect.topLeft, rect.bottomRight, stroke);
    canvas.drawLine(rect.topRight, rect.bottomLeft, stroke);
    canvas.drawRect(rect, stroke);
  }
}
