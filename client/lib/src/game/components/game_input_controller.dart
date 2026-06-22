part of '../leha_bald_game.dart';

/// Component-level keyboard adapter. Flame owns focus and event propagation;
/// this component only translates input into network commands.
class _GameInputController extends Component
    with KeyboardHandler, HasGameReference<LehaBaldGame> {
  final MovementInput _movement = MovementInput();
  static const _minGraceMs = 80;
  static const _maxGraceMs = 180;
  static const _minHeartbeatMs = 24;
  static const _maxHeartbeatMs = 40;

  @override
  void update(double dt) {
    super.update(dt);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    _movement.configureTimings(
      graceMs: _adaptiveGraceMs(game.network.pingMs),
      heartbeatMs: _adaptiveHeartbeatMs(game.network.pingMs),
    );
    // Poll the actual pressed-key set each frame as a backstop for browsers
    // that occasionally drop or reorder key events while a key is held.
    _dispatch(
        _movement.onKeys(HardwareKeyboard.instance.logicalKeysPressed, nowMs));
    // Drives the deferred stop and the held-direction heartbeat (see
    // MovementInput) so a server-side intent clear or a dropped auto-repeat
    // can't leave the player stranded.
    _dispatch(_movement.tick(nowMs));
  }

  void _dispatch(MoveCommand? command) {
    if (command == null) return;
    if (command.kind == MoveCommandKind.stop) {
      game.network.stop();
    } else {
      game.network.input(command.direction!);
    }
  }

  @override
  bool onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event.logicalKey == LogicalKeyboardKey.escape &&
        event is KeyDownEvent) {
      game.network.cancelTargeting();
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.space && event is KeyDownEvent) {
      final snapshot = game.network.snapshot;
      if (snapshot?.you.role == PlayerRole.hunter) {
        if (_myHunterKind(snapshot) == HunterKind.bakhirkin) {
          game.network.beginTargeting(TargetingSkill.trap);
        } else if (_myHunterKind(snapshot) == HunterKind.sashaYakuza) {
          game.network.beginTargeting(TargetingSkill.barrel);
        } else {
          // Sima's "Фембой" is an instant self-buff — no aiming needed.
          game.network.useAbility();
        }
      } else if (snapshot?.you.role == PlayerRole.leha) {
        final me = snapshot?.players
            .where((player) => player.id == snapshot.you.id)
            .firstOrNull;
        if (me?.aspect == LehaAspect.spider) {
          game.network.beginTargeting(TargetingSkill.web);
        } else if (me?.aspect == LehaAspect.wizard) {
          game.network.beginTargeting(TargetingSkill.portal);
        }
      }
      return true;
    }

    // Sima's "Камингаут" — Q selects aiming; hold LMB on the board to fire.
    if (event.logicalKey == LogicalKeyboardKey.keyQ && event is KeyDownEvent) {
      final snapshot = game.network.snapshot;
      if (snapshot?.you.role == PlayerRole.hunter &&
          _myHunterKind(snapshot) == HunterKind.sima) {
        game.network.beginTargeting(TargetingSkill.comingOut);
        return true;
      }
    }

    if ((event.logicalKey == LogicalKeyboardKey.keyE ||
            event.logicalKey == LogicalKeyboardKey.keyQ) &&
        event is KeyDownEvent) {
      final snapshot = game.network.snapshot;
      final me = snapshot?.players
          .where((player) => player.id == snapshot.you.id)
          .firstOrNull;
      if (me?.aspect == LehaAspect.spider) {
        game.network.beginTargeting(TargetingSkill.web);
      } else if (me?.aspect == LehaAspect.wizard) {
        game.network.beginTargeting(TargetingSkill.portal);
      }
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyC && event is KeyDownEvent) {
      final snapshot = game.network.snapshot;
      final me = snapshot?.players
          .where((player) => player.id == snapshot.you.id)
          .firstOrNull;
      if (me?.aspect == LehaAspect.wizard) {
        game.network.beginTargeting(TargetingSkill.crystal);
      }
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyF && event is KeyDownEvent) {
      game.network.beginTargeting(TargetingSkill.clutch);
      return true;
    }

    if (MovementInput.directionForKey(event.logicalKey) == null) return true;

    // Feed the authoritative pressed-key snapshot to the resolver, which decides
    // moves/stops while absorbing web auto-repeat churn (see MovementInput).
    _dispatch(
        _movement.onKeys(keysPressed, DateTime.now().millisecondsSinceEpoch));
    return true;
  }

  HunterKind? _myHunterKind(GameSnapshotDto? snapshot) {
    if (snapshot == null) return null;
    final me = snapshot.players
        .where((player) => player.id == snapshot.you.id)
        .firstOrNull;
    if (me?.hunterKind != null) return me!.hunterKind;
    return snapshot.lobby.roles
        .where((role) => role.role == PlayerRole.hunter)
        .firstOrNull
        ?.hunterKind;
  }

  int _adaptiveGraceMs(double pingMs) {
    final pingAware = pingMs <= 0 ? _minGraceMs : (pingMs * 0.75).round();
    return pingAware.clamp(_minGraceMs, _maxGraceMs);
  }

  int _adaptiveHeartbeatMs(double pingMs) {
    if (pingMs <= 0) return 33;
    final fasterUnderLag = 40 - (pingMs / 12).round();
    return fasterUnderLag.clamp(_minHeartbeatMs, _maxHeartbeatMs);
  }
}
