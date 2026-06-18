import 'package:leha_bald_shared/leha_bald_shared.dart';

class GameConstants {
  const GameConstants();

  static const tickMs = 1000 ~/ 60;
  static const roundDurationMs = 120000;
  static const powerDurationMs = 9000;
  static const trapDurationMs = 10000;
  static const trapCooldownMs = 9000;
  static const trapStunMs = 1000;
  static const hunterStunMs = 3000;
  static const baseSpeed = 3.97;
  static const collisionRadius = 0.32;
  static const corridorWindow = 0.42;
  static const webPhaseMs = 450; // safety cap; phase exits early once Spider reaches open cell
  static const webDurationMs = 10000;
  static const trapTriggeredDisplayMs = 2500;
  static const webSlowMs = 3000;
  static const trailLifetimeMs = 3000;
  static const trailScentRadius = 4;     // Hunter's scent reach in cells
  static const trailVisibilityRadius = 4; // Leha's powered trail radius
  static const xrayRadius = 2;
  static const maxTrapCharges = 2;
  static const maxWebCharges = 2;
  static const portalCooldownMs = 15000;

  // Sasha-yakuza barrel ability.
  static const barrelSpeedMultiplier = 1.6; // of baseSpeed
  static const barrelLifetimeMs = 3000;
  static const barrelCooldownMs = 20000;
  static const barrelStunMs = 1000;
  static const barrelBlindMs = 1000;
  static const barrelRadius = 0.34;
  static const barrelHitRadius = 0.6; // distance for a barrel to catch Leha
  static const barrelWebSlowFactor = 0.25; // speed while slowed by Spider's web
  static const barrelWebSlowMs = 1000; // slow lingers this long after touching a web
  static const lehaBlindRadius = 2.4; // tiles Leha can still see while blinded

  // Sima femboy (charm) ability.
  static const simaFemboyMs = 3000;
  static const simaFemboyCooldownMs = 20000;
  static const simaSlowFactor = 0.5; // both Sima and a charmed Leha move at half speed

  static const roles = [PlayerRole.leha, PlayerRole.hunter];
  static const starts = [Vec2i(10, 16), Vec2i(10, 4)];
  static const tunnelRows = {4, 10, 20};
  static const superLogoKeys = {'1,3', '19,16', '10,20'};

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
