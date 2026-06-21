import 'package:leha_bald_shared/leha_bald_shared.dart';

/// Tracks round totals separately from the two-win cross-role streak that
/// actually decides a match.
class MatchSeries {
  final Map<String, int> roundWins = {};
  String? streakOwnerId;
  PlayerRole? streakRole;

  void reset(Iterable<String> playerIds) {
    roundWins
      ..clear()
      ..addEntries(playerIds.map((id) => MapEntry(id, 0)));
    streakOwnerId = null;
    streakRole = null;
  }

  /// Returns true only when [playerId] won consecutively on the opposite role.
  bool recordWin(String playerId, PlayerRole role) {
    roundWins[playerId] = (roundWins[playerId] ?? 0) + 1;
    final completed = streakOwnerId == playerId && streakRole != role;
    streakOwnerId = playerId;
    streakRole = role;
    return completed;
  }
}
