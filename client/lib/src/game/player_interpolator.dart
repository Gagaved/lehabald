import 'dart:math';
import 'dart:ui';

/// Pure, testable smoothing for a single player's rendered position.
///
/// The server is authoritative and sends positions ~60Hz, but the browser
/// delivers them unevenly — bursts after gaps (see the `snapshot-gap` diagnostic
/// log). A naive spring that chases the *latest* position decelerates to a halt
/// during a delivery gap and then lurches forward when the burst lands, which
/// reads as a jerk on every gap.
///
/// Instead we do classic render-delayed snapshot interpolation: every
/// authoritative sample is buffered with its arrival time, and we render a fixed
/// delay *behind* the freshest sample. The two samples bracketing the render
/// time are then almost always already buffered, so linear interpolation between
/// them reproduces constant-velocity motion no matter how bursty the delivery
/// was. The cost is a small, fixed latency ([renderDelayMs]).
///
/// It is deliberately free of Flame / networking dependencies so its behaviour
/// can be unit-tested against realistic delivery patterns (see
/// test/player_interpolator_test.dart).
class PlayerInterpolator {
  PlayerInterpolator(this.position) {
    _samples.add(_Sample(0, position));
  }

  /// A jump larger than this (tiles) is a teleport (respawn, portal) and snaps
  /// instead of sliding.
  static const double snapTiles = 2.2;

  /// Render this far behind the freshest sample so the two snapshots bracketing
  /// the render time are virtually always already buffered, even when the
  /// browser delivers them in a burst after a stall. This is what turns jittery
  /// delivery into constant-velocity motion; the price is this much added
  /// latency. Sized a little above the typical browser delivery gap.
  static const int renderDelayMs = 90;

  /// If delivery stalls for longer than the render delay we briefly extrapolate
  /// along the last known velocity rather than freezing — but never by more than
  /// this, so a genuine stop can't rubber-band far past the player.
  static const double maxExtrapolateTiles = 0.6;

  /// The smoothed position handed to the renderer.
  Offset position;

  bool initialized = false;
  int snapshotVersion = 0;

  final List<_Sample> _samples = [];
  int? _renderTimeMs;

  Offset get target => _samples.isEmpty ? position : _samples.last.pos;

  /// Records a fresh authoritative position received at [receivedMs].
  void acceptSnapshot(Offset target, int receivedMs) {
    if (_samples.isNotEmpty) {
      final last = _samples.last;
      // A big leap is a teleport: drop the history and snap so we don't slide
      // across the whole map.
      final dx = target.dx - last.pos.dx;
      final dy = target.dy - last.pos.dy;
      if (dx * dx + dy * dy > snapTiles * snapTiles) {
        _samples
          ..clear()
          ..add(_Sample(receivedMs, target));
        position = target;
        _renderTimeMs = null;
        return;
      }
      // Out-of-order or same-instant delivery: just refresh the latest sample's
      // position rather than corrupting the timeline.
      if (receivedMs <= last.timeMs) {
        _samples[_samples.length - 1] = _Sample(last.timeMs, target);
        return;
      }
    }
    _samples.add(_Sample(receivedMs, target));
    // Bound the buffer; samples far older than the render window are useless.
    const keepMs = renderDelayMs + 500;
    while (_samples.length > 2 && receivedMs - _samples.first.timeMs > keepMs) {
      _samples.removeAt(0);
    }
  }

  /// Advances the render position one frame. [nowMs] is wall-clock now,
  /// [frameDt] the frame delta in seconds. [isMe] is accepted for API symmetry
  /// but the delay is uniform — the local player is interpolated the same way so
  /// the camera tracks a smooth position.
  void tick(int nowMs, double frameDt, {required bool isMe}) {
    initialized = true;
    if (_samples.isEmpty) return;

    // Render time trails real time by a fixed delay. We advance it by the frame
    // delta (so a burst of arrivals can't make it leap), then gently re-sync to
    // the ideal if we've drifted (long frame, clock jump, tab throttling).
    final ideal = nowMs - renderDelayMs;
    if (_renderTimeMs == null) {
      _renderTimeMs = ideal;
    } else {
      _renderTimeMs = _renderTimeMs! + (frameDt * 1000).round();
      if ((ideal - _renderTimeMs!).abs() > renderDelayMs) _renderTimeMs = ideal;
    }
    final rt = _renderTimeMs!;

    final oldest = _samples.first;
    final newest = _samples.last;

    if (rt <= oldest.timeMs) {
      position = oldest.pos;
      return;
    }
    if (rt >= newest.timeMs) {
      // Stalled past the buffer: extrapolate briefly, capped, then hold.
      position = _extrapolate(rt, newest);
      return;
    }
    // Interpolate within the bracketing pair (search from the newest end —
    // that's where the render time normally sits).
    for (var i = _samples.length - 1; i > 0; i--) {
      final b = _samples[i];
      final a = _samples[i - 1];
      if (rt >= a.timeMs && rt <= b.timeMs) {
        final span = b.timeMs - a.timeMs;
        final f = span <= 0 ? 1.0 : (rt - a.timeMs) / span;
        position = Offset(
          a.pos.dx + (b.pos.dx - a.pos.dx) * f,
          a.pos.dy + (b.pos.dy - a.pos.dy) * f,
        );
        return;
      }
    }
  }

  Offset _extrapolate(int rt, _Sample newest) {
    if (_samples.length < 2) return newest.pos;
    final prev = _samples[_samples.length - 2];
    final span = newest.timeMs - prev.timeMs;
    if (span <= 0) return newest.pos;
    final vx = (newest.pos.dx - prev.pos.dx) / span;
    final vy = (newest.pos.dy - prev.pos.dy) / span;
    final ahead = (rt - newest.timeMs).toDouble();
    var ex = vx * ahead;
    var ey = vy * ahead;
    final dist = sqrt(ex * ex + ey * ey);
    if (dist > maxExtrapolateTiles) {
      final scale = maxExtrapolateTiles / dist;
      ex *= scale;
      ey *= scale;
    }
    return Offset(newest.pos.dx + ex, newest.pos.dy + ey);
  }
}

class _Sample {
  const _Sample(this.timeMs, this.pos);
  final int timeMs;
  final Offset pos;
}
