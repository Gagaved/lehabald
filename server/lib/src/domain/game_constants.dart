import 'package:leha_bald_shared/leha_bald_shared.dart';

class GameConstants {
  const GameConstants();

  static const tickMs = 1000 ~/ 60;
  static const roundDurationMs = 180000;
  static const logoTimerReductionMs = 500;
  static const readyTimeoutMs = 30000;
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
  static const trailLifetimeMs = 2500;
  static const trailScentRadius = 4; // Hunter's scent reach in cells
  static const trailVisibilityRadius = 4; // Leha's powered trail radius
  static const xrayRadius = 2;
  // Bakhirkin can keep up to this many traps placed on the map at once. There is
  // no cooldown — placing spends a charge, picking a placed trap back up refunds
  // one.
  static const maxTrapCharges = 5;
  static const maxWebCharges = 2;
  // Wizard cooldown is on *laying a pair of portals*, not on passing through.
  // It starts only once the second portal of a pair is placed.
  static const portalCooldownMs = 10000;
  // How many cracked walls are scattered on the map — the only cells where the
  // Spider may spin a web. Kept small so they're a deliberate, scarce resource.
  static const crackedWallCount = 8;

  // Spider "Raffaello" mode.
  static const rafaelkiCount = 6; // Raffaellos scattered on the map
  static const rafaelkiNeeded = 5; // how many to eat before laying a clutch
  static const clutchHatchMs = 20000; // clutch hatches after this if undisturbed

  // Sasha-yakuza barrel ability.
  static const barrelSpeedMultiplier = 1.84; // of baseSpeed
  static const barrelLifetimeMs = 4000;
  static const barrelCooldownMs = 10000;
  static const barrelStunMs = 1000;
  static const barrelBlindMs = 1000;
  static const barrelRadius = 0.34;
  static const barrelHitRadius = 0.6; // distance for a barrel to catch Leha
  // Homing barrels (thrown with Leha in sight) bend course by at most this many
  // radians per tick toward him — a nudge, not a guided missile.
  static const barrelHomingTurnPerTick = 0.04;
  static const barrelWebSlowFactor = 0.25; // speed while slowed by Spider's web
  static const barrelWebSlowMs =
      1000; // slow lingers this long after touching a web
  static const lehaBlindRadius = 2.4; // tiles Leha can still see while blinded

  // Sima femboy (charm) ability.
  static const simaFemboyMs = 1000;
  static const simaFemboyCooldownMs = 20000;
  static const simaSlowFactor = 0.5; // charmed Leha is dragged at half speed

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
