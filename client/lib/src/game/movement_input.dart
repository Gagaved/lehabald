import 'package:flutter/services.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';

/// A movement command the input layer wants to send to the server.
enum MoveCommandKind { move, stop }

class MoveCommand {
  const MoveCommand.move(MoveDirection this.direction)
      : kind = MoveCommandKind.move;
  const MoveCommand.stop()
      : kind = MoveCommandKind.stop,
        direction = null;

  final MoveCommandKind kind;
  final MoveDirection? direction;

  @override
  bool operator ==(Object other) =>
      other is MoveCommand &&
      other.kind == kind &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(kind, direction);

  @override
  String toString() =>
      kind == MoveCommandKind.stop ? 'stop' : 'move(${direction!.name})';
}

/// Pure, time-driven translation of the *currently pressed keys* into movement
/// commands. Kept free of Flame so it can be unit-tested (see
/// test/movement_input_test.dart). It is hardened against the two ways the
/// browser quietly breaks held-key movement in a web build:
///
///  * **Phantom key-up from OS auto-repeat.** Some browsers/platforms emit a
///    `keyup` immediately followed by a `keydown` for each repeat of a held key.
///    Acting on the `keyup` at once would send a `stop` and flicker the player to
///    a halt. So a stop is *debounced* by [graceMs]; a re-press inside that
///    window cancels it.
///  * **Server-side clearing of held intent.** The server drops `nextDirection`
///    on a stun / web phase / charm, after which a still-held key produces no new
///    event to re-arm it — the player just stays stopped. A dropped auto-repeat
///    causes the same silence. So while a direction is held we re-assert it every
///    [heartbeatMs], which the server happily treats as the same input.
class MovementInput {
  MovementInput({this.graceMs = 60, this.heartbeatMs = 100});

  /// How long to wait before honouring a release, absorbing auto-repeat's
  /// up/down churn.
  final int graceMs;

  /// How often to re-send the held direction so a server-side clear or a dropped
  /// repeat can't strand the player.
  final int heartbeatMs;

  MoveDirection? _held;
  int? _stopPendingAt;
  bool _stopOutstanding = false; // a move was sent and not yet cancelled
  int _lastSentAt = 0;

  /// The direction currently considered held (null == none). Exposed for tests.
  MoveDirection? get held => _held;

  /// Maps a single key to its cardinal direction, or null if it isn't a
  /// movement key. WASD and arrows are equivalent.
  static MoveDirection? directionForKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      return MoveDirection.up;
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      return MoveDirection.down;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      return MoveDirection.left;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      return MoveDirection.right;
    }
    return null;
  }

  /// Resolves the set of pressed keys into one of the 8 directions, with
  /// opposing keys cancelling out (W+S or A+D → that axis is neutral).
  static MoveDirection? combine(Iterable<LogicalKeyboardKey> keysPressed) {
    final dirs = <MoveDirection>{};
    for (final key in keysPressed) {
      final dir = directionForKey(key);
      if (dir != null) dirs.add(dir);
    }
    final up = dirs.contains(MoveDirection.up) &&
        !dirs.contains(MoveDirection.down);
    final down = dirs.contains(MoveDirection.down) &&
        !dirs.contains(MoveDirection.up);
    final left = dirs.contains(MoveDirection.left) &&
        !dirs.contains(MoveDirection.right);
    final right = dirs.contains(MoveDirection.right) &&
        !dirs.contains(MoveDirection.left);
    if (up && left) return MoveDirection.upLeft;
    if (up && right) return MoveDirection.upRight;
    if (down && left) return MoveDirection.downLeft;
    if (down && right) return MoveDirection.downRight;
    if (up) return MoveDirection.up;
    if (down) return MoveDirection.down;
    if (left) return MoveDirection.left;
    if (right) return MoveDirection.right;
    return null;
  }

  /// Feed the authoritative pressed-key snapshot from a key event. Returns a
  /// command to send immediately, or null (a pending stop is decided later in
  /// [tick], and unchanged holds ride the heartbeat).
  MoveCommand? onKeys(Set<LogicalKeyboardKey> keysPressed, int nowMs) {
    final dir = combine(keysPressed);
    if (dir != null) {
      _stopPendingAt = null;
      final changed = dir != _held || !_stopOutstanding;
      _held = dir;
      if (changed) return _emitMove(dir, nowMs);
      return null;
    }
    // Nothing held now — but defer the stop in case this is auto-repeat churn.
    _stopPendingAt ??= nowMs;
    return null;
  }

  /// Call every frame with the current time. Emits a deferred stop once the
  /// grace window elapses, or re-asserts the held direction on the heartbeat.
  MoveCommand? tick(int nowMs) {
    final pendingAt = _stopPendingAt;
    if (pendingAt != null && nowMs - pendingAt >= graceMs) {
      _stopPendingAt = null;
      _held = null;
      if (_stopOutstanding) {
        _stopOutstanding = false;
        _lastSentAt = nowMs;
        return const MoveCommand.stop();
      }
      return null;
    }
    // Don't re-assert while a release is being debounced — otherwise the
    // heartbeat would fight the pending stop and the player could never halt.
    if (_stopPendingAt == null &&
        _held != null &&
        nowMs - _lastSentAt >= heartbeatMs) {
      return _emitMove(_held!, nowMs);
    }
    return null;
  }

  MoveCommand _emitMove(MoveDirection dir, int nowMs) {
    _lastSentAt = nowMs;
    _stopOutstanding = true;
    return MoveCommand.move(dir);
  }
}
