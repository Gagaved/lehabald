part of '../leha_bald_game.dart';

/// Component-level keyboard adapter. Flame owns focus and event propagation;
/// this component only translates input into network commands.
class _GameInputController extends Component
    with KeyboardHandler, HasGameReference<LehaBaldGame> {
  final Map<LogicalKeyboardKey, MoveDirection> _heldKeys = {};

  @override
  bool onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event.logicalKey == LogicalKeyboardKey.escape &&
        event is KeyDownEvent) {
      game.network.cancelTargeting();
      return false;
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
      return false;
    }

    // Sima's "Камингаут" — Q selects aiming; hold LMB on the board to fire.
    if (event.logicalKey == LogicalKeyboardKey.keyQ && event is KeyDownEvent) {
      final snapshot = game.network.snapshot;
      if (snapshot?.you.role == PlayerRole.hunter &&
          _myHunterKind(snapshot) == HunterKind.sima) {
        game.network.beginTargeting(TargetingSkill.comingOut);
        return false;
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
      return false;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyC && event is KeyDownEvent) {
      final snapshot = game.network.snapshot;
      final me = snapshot?.players
          .where((player) => player.id == snapshot.you.id)
          .firstOrNull;
      if (me?.aspect == LehaAspect.wizard) {
        game.network.beginTargeting(TargetingSkill.crystal);
      }
      return false;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyF && event is KeyDownEvent) {
      final snapshot = game.network.snapshot;
      final me = snapshot?.players
          .where((player) => player.id == snapshot.you.id)
          .firstOrNull;
      if (me?.aspect == LehaAspect.wizard) {
        game.network.beginTargeting(TargetingSkill.chain);
      } else {
        game.network.beginTargeting(TargetingSkill.clutch);
      }
      return false;
    }

    final direction = _directionForKey(event.logicalKey);
    if (direction == null) return true;
    if (event is KeyDownEvent) {
      _heldKeys[event.logicalKey] = direction;
    } else if (event is KeyUpEvent) {
      _heldKeys.remove(event.logicalKey);
    }

    final combined = _combinedDirection();
    combined == null ? game.network.stop() : game.network.input(combined);
    return false;
  }

  MoveDirection? _combinedDirection() {
    final directions = _heldKeys.values.toSet();
    final up = directions.contains(MoveDirection.up) &&
        !directions.contains(MoveDirection.down);
    final down = directions.contains(MoveDirection.down) &&
        !directions.contains(MoveDirection.up);
    final left = directions.contains(MoveDirection.left) &&
        !directions.contains(MoveDirection.right);
    final right = directions.contains(MoveDirection.right) &&
        !directions.contains(MoveDirection.left);
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

  MoveDirection? _directionForKey(LogicalKeyboardKey key) {
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
}
