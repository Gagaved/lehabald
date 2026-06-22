import 'package:leha_bald_shared/leha_bald_shared.dart';

class GameConstants {
  const GameConstants();

  static const tickMs = 1000 ~/ 60;
  static const roundDurationMs = 180000;
  static const logoTimerReductionMs = 500;
  static const powerDurationMs = 9000;
  static const trapDurationMs = 10000;
  static const trapCooldownMs = 9000;
  static const trapStunMs = 1500;
  static const hunterStunMs = 3000;
  static const baseSpeed = 3.573; // -10% across the board
  static const collisionRadius = 0.32;
  static const corridorWindow = 0.42;
  static const webPhaseMs =
      450; // safety cap; phase exits early once Spider reaches open cell
  static const webCooldownMs = 10000;
  // A wall web is a temporary shortcut: it vanishes after this long, and if the
  // Spider is still inside that wall when it does, she is ejected to open ground
  // (so she can't camp inside a wall and run out the clock).
  static const wallWebLifetimeMs = 10000;
  static const trapTriggeredDisplayMs = 2500;
  static const webSlowMs = 3000;
  static const trailLifetimeMs = 1500;
  // A footprint left while crossing forest leaf litter is "loud": it lingers
  // longer and the opponent sees it from anywhere on the map.
  static const loudTrailLifetimeMs = 1000;
  static const leafLitterPatchCount = 7;
  static const trailScentRadius = 4; // Hunter's scent reach in cells
  static const trailVisibilityRadius = 4; // Leha's powered trail radius
  // Breaking cover (bush, amethyst spores, sulfur cloud) keeps masking the
  // player's scent for this long after they leave it, shaking the pursuer.
  static const scentMaskGraceMs = 1500;
  static const xrayRadius = 2;
  // Bakhirkin can keep up to this many traps placed on the map at once. There is
  // no cooldown — placing spends a charge, picking a placed trap back up refunds
  // one.
  static const maxTrapCharges = 5;
  static const maxWebCharges = 2;
  // Wizard cooldown is on *laying a pair of portals*, not on passing through.
  // It starts only once the second portal of a pair is placed.
  static const portalCooldownMs = 20000;

  // Wizard: place reusable crystals and close wall-visible polygonal chains.
  static const wizardMaxCrystals = 6;
  static const wizardActivationCooldownMs = 5000;
  static const wizardFailedActivationStunMs = 1000;
  static const wizardChainSlowFactor = 0.3;
  static const wizardChainCollisionRadius = 0.24;
  static const wizardSaturationReferenceArea = 20.0;
  static const wizardSaturationBaseMs = 30000;
  static const wizardSaturationMinMultiplier = 0.05;
  static const wizardSaturationMaxMultiplier = 1.5;
  // How many cracked walls are scattered on the map — the only cells where the
  // Spider may spin a web. Kept small so they're a deliberate, scarce resource.
  static const crackedWallCount = 8;

  // Ice biome crystals: scattered clusters that project mirror illusions on the
  // perpendicular through the crystal relative to the player→crystal ray.
  static const crystalSpots = 8; // clusters
  static const crystalIllusionFadeStart = 3.0; // full opacity within this range
  static const crystalIllusionMaxRange = 5.0; // invisible beyond this
  static const crystalIllusionCullRange = 5.5; // keep zero-opacity edge stable
  // The hunter's scent signal is dampened near ice crystals: trail points
  // within this many cells of any crystal are not shown.
  static const crystalScentDampenRadius = 3.0;

  // Sandstone biome: mummies are sealed inside sandstone wall blocks. A block
  // cracks when a player passes nearby, then releases its mummy (destroying the
  // block) when a player enters the radius again. A fleeing mummy dives into any
  // other sandstone wall to seal a fresh lair.
  static const sarcophagusCount = 10;
  static const sarcophagusTriggerRadius = 1.35;
  static const mummyChaseSpeedMultiplier = 2.0;
  static const mummyFleeSpeedMultiplier = 1.0;
  static const mummyStunMs = 2000;
  static const mummyHitRadius = 0.62;
  static const mummyHideRadius = 0.35;

  // Sandstone biome quicksand: scattered patches of open floor that slow anyone
  // walking through them to a crawl.
  static const quicksandSpots = 6; // patch seeds
  static const quicksandSlowFactor = 0.5;

  // Amethyst biome: permanent crystal wall-nodes seed destructible floor shards.
  // Wall-nodes spawn in groups so each larger colony has several visible roots.
  static const amethystColonyCount = 3;
  static const amethystSourcesPerColonyMin = 2;
  static const amethystSourcesPerColonyMax = 3;
  static const amethystShardCount = 18;
  static const amethystShardMaxCount = 22;
  static const amethystShardSourceRadius = 4;
  static const amethystShardGrowIntervalMs = 6000;
  static const chimeDurationMs = 5000;
  static const chimeMaxRadius = 4.0; // tiles the pulse expands to

  // Amethyst biome mushroom colonies: mushrooms grow through stages, then die
  // and release purple spores in a 3x3 area. The mature warning stage lasts
  // longer; trampling during that stage triggers the same full burst.
  static const mushroomStartCount = 10;
  static const mushroomMaxCount = 18;
  static const mushroomMaxStage = 3; // 0=sprout .. 3=mature (dies next grow)
  static const mushroomGrowIntervalMs = 12000;
  static const mushroomMatureIntervalMs = 18000;
  static const mushroomSporeDurationMs = 8000;
  static const mushroomSporeGrowChance = 0.5;
  static const mushroomSporeMaxBirthsPerTick = 2;
  static const mushroomSporeSlowFactor = 0.7;
  static const mushroomSpreadRadius = 3;

  // Ember biome: rocks surface inside the lava as temporary stepping stones,
  // and sulfur geysers erupt on the floor into drifting clouds.
  // A surfaced rock sinks this long after a player first steps on it.
  static const emberBridgeSinkMs = 1000;
  // A geyser telegraphs this long before it erupts.
  static const geyserWarningMs = 1000;
  static const geyserMinIntervalMs = 4000;
  static const geyserMaxIntervalMs = 7000;
  // How long an erupted sulfur cloud lingers before fading.
  static const sulfurDurationMs = 10000;

  // Spider "Raffaello" mode.
  static const rafaelkiCount = 6; // Raffaellos scattered on the map
  static const rafaelkiNeeded = 5; // how many to eat before laying a clutch
  static const clutchHatchMs =
      20000; // clutch hatches after this if undisturbed

  // Sasha-yakuza barrel ability.
  static const barrelSpeedMultiplier = 1.84; // of baseSpeed
  static const barrelLifetimeMs = 4000;
  static const barrelCooldownMs = 10000;
  static const barrelStunMs = 1000;
  static const barrelBlindMs = 1000;
  static const barrelRadius = SkillTargetRange.barrelRadius;
  static const barrelHitRadius = 0.6; // distance for a barrel to catch Leha
  // Homing barrels (thrown with Leha in sight) bend course by at most this many
  // radians per tick toward him — a nudge, not a guided missile.
  static const barrelHomingTurnPerTick = 0.04;
  static const barrelWebSlowFactor = 0.25; // speed while slowed by Spider's web
  static const barrelWebSlowMs =
      1000; // slow lingers this long after touching a web
  static const lehaBlindRadius = 2.4; // tiles Leha can still see while blinded

  // Sima "Фембой" form: a self-buff aura. While active, a visible non-powered
  // Leha is slowed when moving away from Sima (no more drag). Lasts 3x longer
  // than the old charm (was 1000).
  static const simaFemboyMs = 3000;
  static const simaFemboyCooldownMs = 20000;
  static const simaSlowFactor = 0.5; // fleeing Leha at half speed; pull speed too

  // Sima "Камингаут": charge-based heart projectiles. A heart that hits a
  // non-powered Leha pulls him toward Sima (old femboy drag) for a brief moment.
  static const simaHeartMaxCharges = 3;
  static const simaHeartShotCooldownMs = 300; // gap between consecutive shots
  static const simaHeartRechargeMs = 4000; // one charge refilled this often
  static const simaHeartSpeedMultiplier = 2.0; // of baseSpeed
  static const simaHeartRangeBlocks = 10.0; // travel distance before it fizzles
  static const simaHeartHitRadius = 0.5;
  static const simaHeartPullMs = 300; // how long the hit drags Leha
  static const simaHeartSineAmplitude = 0.275; // lateral sway, cells
  static const simaHeartSineWavelength = 2.2; // cells per full sine wave
  static const simaHeartWallImpactMs = 280;

  static const roles = [PlayerRole.leha, PlayerRole.hunter];

  // Procedurally-generated maze size (both odd; centre axis at mazeCols ~/ 2 = 12).
  static const mazeCols = 25;
  static const mazeRows = 25;
  static const starts = [Vec2i(12, 20), Vec2i(12, 4)];
  // Wrap-around corridors: horizontal tunnel rows (exit left/right) and vertical
  // tunnel columns (exit top/bottom). A player leaving one edge reappears on the
  // opposite one.
  static const tunnelRows = {4, 12, 24};
  static const tunnelCols = {6, 18};
  static const superLogoKeys = {'1,3', '23,20', '12,12'};

  static const maze = [
    '#####################',
    '#.........#.........#',
    '#.###.###.#.###.###.#',
    '#o###.###.#.###.###o#',
    ' ................... ',
    '#.###.#.#####.#.###.#',
    '#.....#...#...#.....#',
    '#####.### # ###.#####',
    '    #.#       #.#    ',
    '#####.# ## ## #.#####',
    '     .  #   #  .     ',
    '#####.# ##### #.#####',
    '    #.#       #.#    ',
    '#####.# ##### #.#####',
    '#.........#.........#',
    '#.###.###.#.###.###.#',
    '#o..#.....P.....#..o#',
    '###.#.#.#####.#.#.###',
    '#.....#...#...#.....#',
    '#.#######.#.#######.#',
    ' ................... ',
    '#####################',
  ];
}
