import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';

import 'src/game/leha_bald_game.dart';
import 'src/game/movement_input.dart';
import 'src/net/game_network_client.dart';
import 'src/ui/game_overlay.dart';
import 'src/game/skill_targeting.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ensureProtocolMappersInitialized();
  final network = GameNetworkClient(initialUrl: defaultServerUrl());
  final game = LehaBaldGame(network: network);
  runApp(LehaBaldApp(network: network, game: game));
}

const _backendPort = 4173;
const _devClientPort = 4183;

/// Resolves the WebSocket backend URL.
///
/// Priority:
/// 1. Explicit `SERVER_URL` dart-define — manual override for unusual setups
///    (e.g. a tunnel where the backend lives on a different host).
/// 2. Dev split: when the page is served by the Flutter dev server (port
///    4183), the backend is the same host on port 4173.
/// 3. Single-origin: otherwise connect to the same scheme/host/port that
///    served the page at `/ws`. This is the hosted path — the Dart backend
///    serves both the app and the socket on one port, so it works directly,
///    over the VPN, or behind an https tunnel (scheme upgrades to `wss`)
///    without rebuilding.
/// 4. Localhost fallback for native runs.
String defaultServerUrl() {
  const fromDefine = String.fromEnvironment('SERVER_URL');
  if (fromDefine.isNotEmpty) return fromDefine;

  final base = Uri.base;
  final scheme = base.scheme == 'https' ? 'wss' : 'ws';
  if (base.host.isEmpty ||
      base.host == 'localhost' ||
      base.host == '127.0.0.1') {
    return 'ws://127.0.0.1:$_backendPort/ws';
  }
  if (base.port == _devClientPort) {
    return '$scheme://${base.host}:$_backendPort/ws';
  }
  return '$scheme://${base.host}:${base.port}/ws';
}

class LehaBaldApp extends StatefulWidget {
  const LehaBaldApp({
    required this.network,
    required this.game,
    super.key,
  });

  final GameNetworkClient network;
  final LehaBaldGame game;

  @override
  State<LehaBaldApp> createState() => _LehaBaldAppState();
}

class _LehaBaldAppState extends State<LehaBaldApp> {
  final FocusNode _gameFocus = FocusNode(debugLabel: 'game-keyboard-input');
  final FocusNode _keyboardFocus = FocusNode(debugLabel: 'root-keyboard-input');
  final MovementInput _movement = MovementInput();
  final Set<LogicalKeyboardKey> _heldKeys = <LogicalKeyboardKey>{};
  Timer? _movementTimer;
  bool _refocusing = false;

  @override
  void initState() {
    super.initState();
    _gameFocus.addListener(_handleGameFocusChange);
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyboardEvent);
    _movementTimer = Timer.periodic(
        const Duration(milliseconds: 16), (_) => _tickMovement());
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyboardEvent);
    _gameFocus.removeListener(_handleGameFocusChange);
    _gameFocus.dispose();
    _keyboardFocus.dispose();
    super.dispose();
  }

  void _handleGameFocusChange() {
    if (_gameFocus.hasFocus) return;
    final snapshot = widget.network.snapshot;
    if (snapshot?.session?.phase != SessionPhase.playing) return;
    if (_refocusing) return;
    _refocusing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refocusing = false;
      if (!mounted || _gameFocus.hasFocus) return;
      _gameFocus.requestFocus();
    });
  }

  void _tickMovement() {
    if (!mounted) return;
    _movement.configureTimings(
      graceMs: 80,
      heartbeatMs: 33,
    );
    _dispatch(_movement.tick(DateTime.now().millisecondsSinceEpoch));
  }

  void _dispatch(MoveCommand? command) {
    if (command == null) return;
    if (command.kind == MoveCommandKind.stop) {
      widget.network.stop();
    } else {
      widget.network.input(command.direction!);
    }
  }

  bool _isMovementKey(LogicalKeyboardKey key) =>
      MovementInput.directionForKey(key) != null;

  bool _isGameActionKey(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.keyQ ||
      key == LogicalKeyboardKey.keyE ||
      key == LogicalKeyboardKey.keyC ||
      key == LogicalKeyboardKey.keyF ||
      key == LogicalKeyboardKey.escape;

  void _syncMovementFromKeys() {
    _dispatch(
      _movement.onKeys(_heldKeys, DateTime.now().millisecondsSinceEpoch),
    );
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

  bool _handleGlobalKeyboardEvent(KeyEvent event) {
    final key = event.logicalKey;
    final isDown = event is KeyDownEvent;
    final isUp = event is KeyUpEvent;
    final handled = _isMovementKey(key) || _isGameActionKey(key);

    if (_isMovementKey(key)) {
      if (isDown) {
        _heldKeys.add(key);
        _syncMovementFromKeys();
      } else if (isUp) {
        _heldKeys.remove(key);
        _syncMovementFromKeys();
      }
      return handled;
    }

    if (!isDown)
      return handled;

    if (key == LogicalKeyboardKey.escape) {
      widget.network.cancelTargeting();
      return true;
    }
    if (key == LogicalKeyboardKey.space) {
      final snapshot = widget.network.snapshot;
      if (snapshot?.you.role == PlayerRole.hunter) {
        final hunterKind = _myHunterKind(snapshot);
        if (hunterKind == HunterKind.bakhirkin) {
          widget.network.beginTargeting(TargetingSkill.trap);
        } else if (hunterKind == HunterKind.sashaYakuza) {
          widget.network.beginTargeting(TargetingSkill.barrel);
        } else {
          widget.network.useAbility();
        }
      } else if (snapshot?.you.role == PlayerRole.leha) {
        final me = snapshot?.players
            .where((player) => player.id == snapshot.you.id)
            .firstOrNull;
        if (me?.aspect == LehaAspect.spider) {
          widget.network.beginTargeting(TargetingSkill.web);
        } else if (me?.aspect == LehaAspect.wizard) {
          widget.network.beginTargeting(TargetingSkill.portal);
        }
      }
      return true;
    }
    if (key == LogicalKeyboardKey.keyQ) {
      final snapshot = widget.network.snapshot;
      if (snapshot?.you.role == PlayerRole.hunter &&
          _myHunterKind(snapshot) == HunterKind.sima) {
        widget.network.beginTargeting(TargetingSkill.comingOut);
        return true;
      }
      final me = snapshot == null
          ? null
          : snapshot.players
              .where((player) => player.id == snapshot.you.id)
              .firstOrNull;
      if (me?.aspect == LehaAspect.spider) {
        widget.network.beginTargeting(TargetingSkill.web);
      } else if (me?.aspect == LehaAspect.wizard) {
        widget.network.beginTargeting(TargetingSkill.portal);
      }
      return true;
    }
    if (key == LogicalKeyboardKey.keyE) {
      final snapshot = widget.network.snapshot;
      final me = snapshot == null
          ? null
          : snapshot.players
              .where((player) => player.id == snapshot.you.id)
              .firstOrNull;
      if (me?.aspect == LehaAspect.spider) {
        widget.network.beginTargeting(TargetingSkill.web);
      } else if (me?.aspect == LehaAspect.wizard) {
        widget.network.beginTargeting(TargetingSkill.portal);
      }
      return true;
    }
    if (key == LogicalKeyboardKey.keyC) {
      final snapshot = widget.network.snapshot;
      final me = snapshot == null
          ? null
          : snapshot.players
              .where((player) => player.id == snapshot.you.id)
              .firstOrNull;
      if (me?.aspect == LehaAspect.wizard) {
        widget.network.beginTargeting(TargetingSkill.crystal);
      }
      return true;
    }
    if (key == LogicalKeyboardKey.keyF) {
      widget.network.beginTargeting(TargetingSkill.clutch);
      return true;
    }
    return handled;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Леха против Охотника',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xff05070d),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff00f2ea),
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(
        backgroundColor: const Color(0xff0d111a),
        body: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Material(
                      elevation: 30,
                      shadowColor: const Color(0xe6000000),
                      color: LehaBaldGame.backdropColor,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide.none,
                      ),
                      child: Listener(
                        onPointerDown: (_) => _keyboardFocus.requestFocus(),
                        child: GameWidget(
                          game: widget.game,
                          focusNode: _gameFocus,
                          autofocus: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: GameOverlay(
                network: widget.network,
                onRequestGameFocus: _keyboardFocus.requestFocus,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
