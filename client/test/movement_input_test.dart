import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leha_bald_client/src/game/movement_input.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';

const _w = LogicalKeyboardKey.keyW;
const _a = LogicalKeyboardKey.keyA;
const _s = LogicalKeyboardKey.keyS;
const _d = LogicalKeyboardKey.keyD;
const _up = LogicalKeyboardKey.arrowUp;
const _left = LogicalKeyboardKey.arrowLeft;
const _space = LogicalKeyboardKey.space;

void main() {
  group('combine', () {
    test('single keys map to cardinals (WASD and arrows alike)', () {
      expect(MovementInput.combine({_w}), MoveDirection.up);
      expect(MovementInput.combine({_up}), MoveDirection.up);
      expect(MovementInput.combine({_a}), MoveDirection.left);
      expect(MovementInput.combine({_left}), MoveDirection.left);
      expect(MovementInput.combine({_s}), MoveDirection.down);
      expect(MovementInput.combine({_d}), MoveDirection.right);
    });

    test('two perpendicular keys make a diagonal', () {
      expect(MovementInput.combine({_w, _d}), MoveDirection.upRight);
      expect(MovementInput.combine({_w, _a}), MoveDirection.upLeft);
      expect(MovementInput.combine({_s, _d}), MoveDirection.downRight);
      expect(MovementInput.combine({_s, _a}), MoveDirection.downLeft);
    });

    test('opposing keys cancel that axis', () {
      expect(MovementInput.combine({_w, _s}), isNull);
      expect(MovementInput.combine({_a, _d}), isNull);
      // Cancel one axis, keep the other.
      expect(MovementInput.combine({_w, _s, _d}), MoveDirection.right);
    });

    test('non-movement keys are ignored', () {
      expect(MovementInput.combine({_space}), isNull);
      expect(MovementInput.combine({_space, _w}), MoveDirection.up);
    });
  });

  group('press / release', () {
    test('first press emits a move immediately', () {
      final m = MovementInput();
      expect(m.onKeys({_w}, 0), const MoveCommand.move(MoveDirection.up));
    });

    test('holding the same key does not re-emit on every event', () {
      final m = MovementInput()..onKeys({_w}, 0);
      // A repeat with the same key set within the heartbeat window: nothing new.
      expect(m.onKeys({_w}, 10), isNull);
      expect(m.onKeys({_w}, 20), isNull);
    });

    test('changing direction emits the new direction at once', () {
      final m = MovementInput()..onKeys({_w}, 0);
      expect(m.onKeys({_w, _d}, 10),
          const MoveCommand.move(MoveDirection.upRight));
      expect(m.onKeys({_d}, 20), const MoveCommand.move(MoveDirection.right));
    });

    test('a genuine release stops — but only after the grace window', () {
      final m = MovementInput(graceMs: 60)..onKeys({_w}, 0);
      // Key up: empty set. No stop yet.
      expect(m.onKeys(<LogicalKeyboardKey>{}, 100), isNull);
      // Still inside the grace window.
      expect(m.tick(140), isNull);
      // Grace elapsed -> stop.
      expect(m.tick(160), const MoveCommand.stop());
      // And only once.
      expect(m.tick(200), isNull);
    });
  });

  group('web auto-repeat hardening', () {
    test('phantom key-up immediately followed by key-down does NOT stop', () {
      final m = MovementInput(graceMs: 60)..onKeys({_w}, 0);
      // OS/browser auto-repeat churn: up at 100, down again at 108.
      expect(m.onKeys(<LogicalKeyboardKey>{}, 100), isNull); // stop deferred
      expect(m.tick(105), isNull); // still within grace, no stop
      // The re-press lands inside the grace window and cancels the pending stop.
      expect(
          m.onKeys({_w}, 108), isNull); // unchanged hold, heartbeat covers it
      // Well past the original grace deadline: still moving (a heartbeat may
      // re-assert the move), but a stop must never have slipped through.
      final late = m.tick(200);
      expect(late?.kind, isNot(MoveCommandKind.stop));
      expect(m.held, MoveDirection.up);
    });

    test('repeated up/down churn never emits a stop', () {
      final m = MovementInput(graceMs: 60)..onKeys({_w}, 0);
      var stops = 0;
      for (var t = 10; t < 1000; t += 16) {
        // Every ~48ms drop the key for one frame then re-press (auto-repeat).
        final pressed = (t ~/ 16) % 3 == 0
            ? <LogicalKeyboardKey>{}
            : <LogicalKeyboardKey>{_w};
        final c1 = m.onKeys(pressed, t);
        final c2 = m.tick(t);
        for (final c in [c1, c2]) {
          if (c?.kind == MoveCommandKind.stop) stops++;
        }
      }
      expect(stops, 0, reason: 'auto-repeat churn must not stop the player');
    });
  });

  group('heartbeat re-assert', () {
    test('held direction is re-sent on the heartbeat interval', () {
      final m = MovementInput(heartbeatMs: 100)..onKeys({_w}, 0);
      // No new key events; the held intent must be re-asserted by ticks so a
      // server-side clear (stun/web/charm) or a dropped repeat can't strand us.
      expect(m.tick(50), isNull);
      expect(m.tick(100), const MoveCommand.move(MoveDirection.up));
      expect(m.tick(150), isNull);
      expect(m.tick(200), const MoveCommand.move(MoveDirection.up));
    });

    test('idle (no key held) never heartbeats', () {
      final m = MovementInput(heartbeatMs: 100);
      for (var t = 0; t <= 1000; t += 50) {
        expect(m.tick(t), isNull);
      }
    });

    test('after a real stop the heartbeat is silent', () {
      final m = MovementInput(graceMs: 60, heartbeatMs: 100)..onKeys({_w}, 0);
      m.onKeys(<LogicalKeyboardKey>{}, 100);
      expect(m.tick(170), const MoveCommand.stop());
      for (var t = 200; t <= 1000; t += 50) {
        expect(m.tick(t), isNull);
      }
    });

    test('simulated server-side intent clear: held key keeps the player moving',
        () {
      // Model the engine wiping nextDirection (stun ends) — the client gets no
      // new key event, yet the heartbeat keeps re-issuing the held direction.
      final m = MovementInput(heartbeatMs: 100)..onKeys({_d}, 0);
      var reasserts = 0;
      for (var t = 1; t <= 1000; t++) {
        final c = m.tick(t);
        if (c?.kind == MoveCommandKind.move) reasserts++;
      }
      // ~one re-assert per heartbeat over a second.
      expect(reasserts, greaterThanOrEqualTo(9));
    });
  });
}
