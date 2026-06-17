import 'package:leha_bald_server/src/game/maze_generator.dart';
import 'package:leha_bald_server/src/game/maze_service.dart';
import 'package:test/test.dart';

void main() {
  for (var seed = 0; seed < 3; seed++) {
    test('seed $seed: valid, symmetric, starts open', () {
      final maze = MazeGenerator(seed: seed).generate();
      expect(maze.length, 21);
      expect(maze.first.length, 21);

      // Symmetry
      for (final row in maze) {
        for (var x = 0; x < row.length; x++) {
          expect(row[x], row[row.length - 1 - x],
              reason: 'row not symmetric: $row');
        }
      }

      final svc = MazeService(mazeData: maze);

      // Starts are open
      expect(svc.isWall(10, 16), isFalse, reason: 'Leha start is wall');
      expect(svc.isWall(10, 4), isFalse, reason: 'Bakhirkin start is wall');

      // At least some logos exist
      expect(svc.createLogos().length, greaterThan(10));

      // Print for visual check
      // ignore: avoid_print
      print('\n=== Seed $seed ===');
      for (final row in maze) {
        // ignore: avoid_print
        print(row);
      }
    });
  }
}
