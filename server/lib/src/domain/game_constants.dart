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
  static const baseSpeed = 4.41;
  static const collisionRadius = 0.32;
  static const corridorWindow = 0.42;
  static const webPhaseMs = 1200;
  static const trailLifetimeMs = 2600;
  static const trailVisibilityRadius = 4;
  static const xrayRadius = 2;
  static const maxTrapCharges = 2;
  static const maxWebCharges = 2;
  static const portalCooldownMs = 15000;

  static const roles = [PlayerRole.leha, PlayerRole.bakhirkin];
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
