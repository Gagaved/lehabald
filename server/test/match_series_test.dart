import 'package:leha_bald_server/src/domain/match_series.dart';
import 'package:leha_bald_server/src/game/game_logger.dart';
import 'package:leha_bald_server/src/game/stats_store.dart';
import 'package:leha_bald_server/src/net/session_manager.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';
import 'package:test/test.dart';

void main() {
  test('alternating winners never complete the match streak', () {
    final series = MatchSeries()..reset(['a', 'b']);
    for (var round = 0; round < 20; round++) {
      final player = round.isEven ? 'a' : 'b';
      final role = round.isEven ? PlayerRole.leha : PlayerRole.hunter;
      expect(series.recordWin(player, role), isFalse);
    }
    expect(series.roundWins, {'a': 10, 'b': 10});
  });

  test('same player wins match after consecutive wins on opposite roles', () {
    final series = MatchSeries()..reset(['a', 'b']);
    expect(series.recordWin('a', PlayerRole.leha), isFalse);
    expect(series.recordWin('a', PlayerRole.hunter), isTrue);
    expect(series.roundWins['a'], 2);
  });

  test('opponent win transfers and resets the active streak', () {
    final series = MatchSeries()..reset(['a', 'b']);
    series.recordWin('a', PlayerRole.leha);
    expect(series.recordWin('b', PlayerRole.leha), isFalse);
    expect(series.streakOwnerId, 'b');
    expect(series.recordWin('b', PlayerRole.hunter), isTrue);
  });

  test('two wins on the same role do not satisfy cross-role requirement', () {
    final series = MatchSeries()..reset(['a', 'b']);
    series.recordWin('a', PlayerRole.leha);
    expect(series.recordWin('a', PlayerRole.leha), isFalse);
  });

  test('public sessions own isolated engines and settings', () {
    final stats = StatsStore(path: 'build/test-session-stats.json');
    final logger = GameLogger(path: 'build/test-session-games.log');
    final first =
        MatchSession(id: 'one', name: 'One', stats: stats, logger: logger);
    final second =
        MatchSession(id: 'two', name: 'Two', stats: stats, logger: logger);

    first.engine.sandboxMode = true;
    first.engine.enabledBiomes = {CaveBiome.frost};

    expect(identical(first.engine, second.engine), isFalse);
    expect(second.engine.sandboxMode, isFalse);
    expect(second.engine.enabledBiomes, isNot({CaveBiome.frost}));
  });
}
