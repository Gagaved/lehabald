import 'dart:convert';
import 'dart:io';

/// Appends one JSON object per line to a games log file (and echoes to stdout).
/// Used for match-level events: round start and round end.
class GameLogger {
  GameLogger({String? path})
      : _file = File(path ?? Platform.environment['GAME_LOG'] ?? 'games.log');

  final File _file;

  void log(Map<String, Object?> event) {
    final line = jsonEncode({'ts': DateTime.now().toIso8601String(), ...event});
    stdout.writeln('[game] $line');
    try {
      _file.writeAsStringSync('$line\n', mode: FileMode.append);
    } catch (_) {
      // Best-effort logging; never let it break the game loop.
    }
  }
}
