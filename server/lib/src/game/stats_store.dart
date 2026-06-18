import 'dart:convert';
import 'dart:io';

/// Persistent per-nickname win/loss store, backed by a small JSON file.
/// Stats are keyed by the user's nickname (case preserved, trimmed by callers).
class StatsStore {
  StatsStore({String? path})
      : _file = File(path ?? Platform.environment['STATS_FILE'] ?? 'leha_stats.json') {
    _load();
  }

  final File _file;
  final Map<String, _Record> _records = {};

  void _load() {
    try {
      if (!_file.existsSync()) return;
      final data = jsonDecode(_file.readAsStringSync());
      if (data is! Map) return;
      data.forEach((key, value) {
        if (key is String && value is Map) {
          _records[key] = _Record(
            wins: (value['wins'] as num?)?.toInt() ?? 0,
            losses: (value['losses'] as num?)?.toInt() ?? 0,
          );
        }
      });
    } catch (_) {
      // Corrupt/unreadable file: start empty rather than crash the server.
    }
  }

  void _save() {
    try {
      _file.writeAsStringSync(jsonEncode({
        for (final e in _records.entries)
          e.key: {'wins': e.value.wins, 'losses': e.value.losses},
      }));
    } catch (_) {
      // Best-effort persistence; ignore write failures.
    }
  }

  _Record _recordFor(String name) => _records.putIfAbsent(name, _Record.new);

  /// Credits a finished round: +1 win for [winner], +1 loss for [loser].
  /// Either may be null/empty (an unregistered player) and is skipped.
  void recordResult({String? winner, String? loser}) {
    var changed = false;
    if (winner != null && winner.isNotEmpty) {
      _recordFor(winner).wins += 1;
      changed = true;
    }
    if (loser != null && loser.isNotEmpty) {
      _recordFor(loser).losses += 1;
      changed = true;
    }
    if (changed) _save();
  }

  ({int wins, int losses})? statsFor(String name) {
    final record = _records[name];
    return record == null ? null : (wins: record.wins, losses: record.losses);
  }

  /// Top entries sorted by wins desc, then fewest losses.
  List<({String name, int wins, int losses})> leaderboard({int limit = 10}) {
    final list = _records.entries
        .map((e) => (name: e.key, wins: e.value.wins, losses: e.value.losses))
        .toList()
      ..sort((a, b) {
        final byWins = b.wins.compareTo(a.wins);
        return byWins != 0 ? byWins : a.losses.compareTo(b.losses);
      });
    return list.take(limit).toList();
  }
}

class _Record {
  _Record({this.wins = 0, this.losses = 0});
  int wins;
  int losses;
}
