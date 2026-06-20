part of '../leha_bald_game.dart';

/// Screen-space root for the game board.
///
/// The server owns gameplay state; this component turns each snapshot into a
/// Flame component tree. Keeping the board transform here means children use
/// world-sized coordinates and never need to know about phone aspect ratios or
/// the Flutter HUD inset.
class _GameSceneComponent extends PositionComponent
    with HasGameReference<LehaBaldGame>, HasVisibility {
  _GameSceneComponent() : super(priority: 10);

  static const _hudInset = 88.0;

  late final _PortalLayerComponent portalLayer;
  late final _TrapLayerComponent trapLayer;
  late final _WebLayerComponent webLayer;

  @override
  void onLoad() {
    portalLayer = _PortalLayerComponent();
    trapLayer = _TrapLayerComponent(priority: 15);
    webLayer = _WebLayerComponent(priority: 5);
    addAll([
      _LegacyTerrainComponent(priority: 0),
      webLayer,
      portalLayer..priority = 10,
      trapLayer,
      _LegacyActorsComponent(priority: 20),
    ]);
  }

  @override
  void update(double dt) {
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

  void _layout(GameSnapshotDto snapshot) {
    size.setValues(
      snapshot.cols * LehaBaldGame.tile,
      snapshot.rows * LehaBaldGame.tile,
    );
    final availableHeight = (game.size.y - _hudInset).clamp(1.0, game.size.y);
    final fit = min(
      game.size.x / size.x,
      availableHeight / size.y,
    );
    scale.setAll(fit);
    position.setValues(
      (game.size.x - size.x * fit) / 2,
      _hudInset + (availableHeight - size.y * fit) / 2,
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

/// Temporary compatibility layer. Terrain renderers move out of this class in
/// follow-up slices, while their ordering is already managed by FCS priority.
class _LegacyTerrainComponent extends Component
    with HasGameReference<LehaBaldGame> {
  _LegacyTerrainComponent({required super.priority});

  @override
  void render(Canvas canvas) {
    final snapshot = game.network.snapshot;
    if (snapshot == null) return;
    game._drawBoard(canvas, snapshot);
    game._drawAmethystWalls(canvas, snapshot.amethystWalls);
    game._drawQuicksand(canvas, snapshot.quicksand);
    game._drawSpores(canvas, snapshot.spores);
    game._drawAmethystShards(canvas, snapshot.amethystShards);
    game._drawCrackedWalls(canvas, snapshot.crackedWalls);
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
