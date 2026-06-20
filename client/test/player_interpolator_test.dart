import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:leha_bald_client/src/game/player_interpolator.dart';

/// Result of running a delivery scenario through the interpolator.
class _Run {
  _Run(this.xs);
  final List<double> xs;

  /// Largest backward step in a forward-only run (0 == perfectly monotonic).
  double get maxBackstep {
    var worst = 0.0;
    for (var i = 1; i < xs.length; i++) {
      final back = xs[i - 1] - xs[i];
      if (back > worst) worst = back;
    }
    return worst;
  }

  /// How many frames stepped backward by more than [eps] tiles.
  int reversals([double eps = 0.002]) {
    var count = 0;
    for (var i = 1; i < xs.length; i++) {
      if (xs[i - 1] - xs[i] > eps) count++;
    }
    return count;
  }

  /// Per-frame movement deltas while the player is actually moving (|step| over
  /// [moveEps]). Visual smoothness == these being roughly constant.
  List<double> movingSteps([double moveEps = 0.001]) {
    final steps = <double>[];
    for (var i = 1; i < xs.length; i++) {
      final d = xs[i] - xs[i - 1];
      if (d.abs() > moveEps) steps.add(d);
    }
    return steps;
  }

  /// Ratio of the largest to the median moving step. ~1 is buttery; a big number
  /// means the player lurches (fast frame, slow frame) even if monotonic.
  double get stepLurchRatio {
    final steps = movingSteps().map((s) => s.abs()).toList()..sort();
    if (steps.length < 4) return 1;
    final median = steps[steps.length ~/ 2];
    final maxStep = steps.last;
    return median <= 0 ? double.infinity : maxStep / median;
  }
}

/// Simulates the server emitting a constant grid step at (optionally jittery)
/// real intervals, the browser delivering snapshots at [deliver] times, and a
/// 60fps client frame loop sampling the interpolator. Returns the rendered x.
_Run _simulate({
  required List<int> tickGapsMs, // real interval between server ticks
  List<double>? steps, // signed tiles per tick; defaults to constant forward
  double step = 0.0572, // constant tiles per tick (baseSpeed * 16ms)
  int frameMs = 16,
}) {
  const startX = 5.0;
  const y = 10.0;
  final perTick = steps ?? List.filled(tickGapsMs.length, step);

  // Server emissions: jittery emission times, signed per-tick step.
  final emitMs = <int>[];
  final emitX = <double>[];
  var t = 0;
  var x = startX;
  for (var i = 0; i < tickGapsMs.length; i++) {
    t += tickGapsMs[i];
    x += perTick[i];
    emitMs.add(t);
    emitX.add(x);
  }

  final interp = PlayerInterpolator(const Offset(startX, y));
  final xs = <double>[];
  var nextEmit = 0;
  final endMs = emitMs.last + 50;
  for (var now = 0; now <= endMs; now += frameMs) {
    // Deliver every snapshot whose emission time has passed (localhost: receive
    // time == emission time). A burst delivers several in one frame.
    while (nextEmit < emitMs.length && emitMs[nextEmit] <= now) {
      interp.acceptSnapshot(Offset(emitX[nextEmit], y), emitMs[nextEmit]);
      nextEmit++;
    }
    interp.tick(now, frameMs / 1000.0, isMe: true);
    if (interp.initialized) xs.add(interp.position.dx);
  }
  return _Run(xs);
}

void main() {
  test('smooth delivery: forward motion never steps backward', () {
    // Perfectly even 16ms ticks — the ideal case.
    final run = _simulate(tickGapsMs: List.filled(120, 16));
    expect(run.reversals(), 0,
        reason: 'even delivery should be monotonic; got ${run.maxBackstep}');
  });

  // The cadence observed in pos.log: ~15ms ticks with periodic 30ms stalls and
  // ~1ms catch-ups (Windows 15.6ms timer quantisation).
  List<int> windowsCadence(int n) {
    final rng = Random(7);
    final gaps = <int>[];
    for (var i = 0; i < n; i++) {
      if (i % 4 == 3) {
        gaps
          ..add(30)
          ..add(1);
      } else {
        gaps.add(15 + rng.nextInt(3));
      }
    }
    return gaps;
  }

  test('jittery delivery, constant forward: monotonic but lurchy?', () {
    final gaps = windowsCadence(200);
    final run = _simulate(tickGapsMs: gaps);
    // ignore: avoid_print
    print('FORWARD: reversals=${run.reversals()} '
        'maxBackstep=${run.maxBackstep.toStringAsFixed(4)} '
        'stepLurchRatio=${run.stepLurchRatio.toStringAsFixed(2)}');
    expect(run.reversals(), 0);
  });

  test('late snapshot never pulls a forward-moving render position backwards',
      () {
    final interp = PlayerInterpolator(const Offset(5, 10));

    // This is the failure mode seen in the live probe: a long delivery gap lets
    // prediction run ahead, then the next authoritative sample arrives behind
    // the predicted position. Reconciliation must continue forwards only.
    interp.acceptSnapshot(const Offset(5.06, 10), 16);
    interp.tick(32, 0.016, isMe: true);
    interp.acceptSnapshot(const Offset(5.12, 10), 46);
    interp.tick(62, 0.030, isMe: true);
    final beforeCatchUp = interp.position.dx;
    interp.acceptSnapshot(const Offset(5.125, 10), 47);
    interp.tick(63, 0.001, isMe: true);

    expect(interp.position.dx, greaterThanOrEqualTo(beforeCatchUp));
  });

  test('entering and leaving spores or geodes does not reverse movement', () {
    final gaps = windowsCadence(180);
    final steps = <double>[
      for (var i = 0; i < gaps.length; i++)
        if (i < 45)
          0.0572
        else if (i < 105)
          // Spore slow factor. Destroying a geode can produce the same abrupt
          // cadence transition when its snapshot and movement arrive together.
          0.0572 * 0.7
        else
          0.0572,
    ];
    final run = _simulate(tickGapsMs: gaps, steps: steps);

    expect(run.reversals(), 0,
        reason: 'a speed-zone boundary must not pull the player backwards');
    expect(run.maxBackstep, 0);
  });

  test('stop after motion: does the player overshoot then snap back?', () {
    final gaps = windowsCadence(120);
    // 60 ticks moving right, then 60 ticks standing still.
    final steps = <double>[
      for (var i = 0; i < gaps.length; i++) i < gaps.length ~/ 2 ? 0.0572 : 0.0,
    ];
    final run = _simulate(tickGapsMs: gaps, steps: steps);
    // ignore: avoid_print
    print('STOP: reversals=${run.reversals()} '
        'maxBackstep=${run.maxBackstep.toStringAsFixed(4)} tiles');
    // A clean stop should not bounce backward.
    expect(run.maxBackstep, lessThan(0.02),
        reason: 'overshoot-then-snap-back at stop = visible jitter');
  });

  test('reverse direction: smooth turn without a backward bounce spike', () {
    final gaps = windowsCadence(120);
    final steps = <double>[
      for (var i = 0; i < gaps.length; i++)
        i < gaps.length ~/ 2 ? 0.0572 : -0.0572,
    ];
    final run = _simulate(tickGapsMs: gaps, steps: steps);
    // After the turn the player legitimately moves backward, so instead of
    // monotonicity we check there is no single-frame spike far larger than the
    // genuine per-tick travel (which would read as a jerk at the turn).
    final steps2 = run.movingSteps().map((s) => s.abs()).toList();
    final maxStep = steps2.isEmpty ? 0.0 : steps2.reduce(max);
    // ignore: avoid_print
    print('REVERSE: maxStep=${maxStep.toStringAsFixed(4)} '
        'lurchRatio=${run.stepLurchRatio.toStringAsFixed(2)}');
    // One server tick travels ~0.057; a frame should never move more than a few
    // ticks' worth even at the turn.
    expect(maxStep, lessThan(0.18),
        reason: 'a frame jumped >3 ticks of travel = jerk at the turn');
  });
}
