import 'dart:math';
import 'dart:ui';

/// Pure, testable smoothing for a single player's rendered position.
///
/// The server is authoritative and sends positions ~60Hz, but the browser
/// delivers them unevenly (bursts after gaps). This class turns the discrete
/// snapshot stream into a continuous render position. It is deliberately free of
/// Flame / networking dependencies so its behaviour can be unit-tested against
/// realistic delivery patterns (see test/player_interpolator_test.dart).
class PlayerInterpolator {
  PlayerInterpolator(this.position) : _target = position;

  /// Default tuning — mirrors the values used in the live game.
  static const double meStiffness = 34;
  static const double otherStiffness = 24;
  static const double snapTiles = 2.2;

  /// The smoothed position handed to the renderer.
  Offset position;

  Offset _target;
  bool initialized = false;
  int snapshotVersion = 0;

  Offset get target => _target;

  /// Records a fresh authoritative position received at [receivedMs].
  void acceptSnapshot(Offset target, int _) {
    _target = target;
  }

  /// Advances the render position one frame. [nowMs] is wall-clock now,
  /// [frameDt] the frame delta in seconds, [isMe] selects spring stiffness.
  void tick(int _, double frameDt, {required bool isMe}) {
    final dx = _target.dx - position.dx;
    final dy = _target.dy - position.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist > snapTiles) {
      position = _target;
    } else {
      final stiffness = isMe ? meStiffness : otherStiffness;
      final alpha = (1 - exp(-stiffness * frameDt)).clamp(0.0, 1.0);
      position = Offset(position.dx + dx * alpha, position.dy + dy * alpha);
    }
    initialized = true;
  }
}
