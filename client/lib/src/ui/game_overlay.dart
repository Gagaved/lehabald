import 'package:flutter/material.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';

import '../net/game_network_client.dart';

class GameOverlay extends StatelessWidget {
  const GameOverlay({required this.network, super.key});

  final GameNetworkClient network;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: network,
      builder: (context, _) {
        final snapshot = network.snapshot;
        return SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: _Hud(network: network, snapshot: snapshot),
              ),
              if (snapshot?.game.phase == GamePhase.waiting || snapshot == null)
                Center(child: _Lobby(network: network, snapshot: snapshot)),
              if ((snapshot?.status ?? network.status).isNotEmpty && snapshot?.game.phase != GamePhase.waiting)
                Center(child: _StatusCard(text: snapshot?.status ?? network.status)),
              if (MediaQuery.sizeOf(context).width < 720)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _TouchControls(network: network),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.network, required this.snapshot});

  final GameNetworkClient network;
  final GameSnapshotDto? snapshot;

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    final role = s?.you.role ?? PlayerRole.spectator;
    final isLeha = role == PlayerRole.leha;
    final isBakhirkin = role == PlayerRole.bakhirkin;
    final myScore = s?.scores.where((score) => score.id == s.you.id).firstOrNull?.score ?? 0;
    final time = _formatTime(s?.game.timeLeftMs ?? 120000);
    final power = s?.game.lehaPowered == true ? ' BIG ${(s!.game.powerLeftMs / 1000).ceil()}с' : '';
    final trapLabel = s == null
        ? 'Капкан'
        : s.game.trapActive
            ? 'Капкан стоит'
            : s.game.trapCooldownMs > 0
                ? 'Капкан ${(s.game.trapCooldownMs / 1000).ceil()}с'
                : 'Капкан ${s.game.trapCharges}';
    final abilityLabel = _abilityLabel(s);
    final hunter = s?.players.where((player) => player.slot == 1).firstOrNull;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _Metric(label: 'Роль', value: isLeha ? 'Леха $myScore' : isBakhirkin ? 'Бахиркин' : 'Наблюдатель'),
          _Metric(
            label: isLeha ? 'TikTok / время' : isBakhirkin ? 'Охота' : 'Просмотр',
            value: isLeha ? '${s?.logos.length ?? 0} / $time$power' : time,
          ),
          if (hunter != null) _Metric(label: 'Бахиркин HP', value: '${hunter.hp}'),
          FilledButton.tonal(
            onPressed: isBakhirkin && s?.game.trapAvailable == true ? network.placeTrap : null,
            child: Text(trapLabel),
          ),
          if (isLeha)
            FilledButton.tonal(
              onPressed: s?.game.abilityAvailable == true ? network.useAbility : null,
              child: Text(abilityLabel),
            ),
          FilledButton(
            onPressed: network.restart,
            child: const Text('Рестарт'),
          ),
        ],
      ),
    );
  }

  String _abilityLabel(GameSnapshotDto? snapshot) {
    final s = snapshot;
    if (s == null) return 'Способность';
    final aspect = s.you.role == PlayerRole.leha
        ? s.players.where((player) => player.id == s.you.id).firstOrNull?.aspect ?? s.lobby.roles.firstOrNull?.aspect
        : null;
    if (aspect == LehaAspect.spider) return 'Паутина ${s.game.abilityCharges}';
    if (aspect == LehaAspect.wizard) {
      if (s.game.abilityCooldownMs > 0) return 'Портал ${(s.game.abilityCooldownMs / 1000).ceil()}с';
      return 'Портал';
    }
    return 'Способность';
  }
}

class _Lobby extends StatefulWidget {
  const _Lobby({required this.network, required this.snapshot});

  final GameNetworkClient network;
  final GameSnapshotDto? snapshot;

  @override
  State<_Lobby> createState() => _LobbyState();
}

class _LobbyState extends State<_Lobby> {
  late final TextEditingController _controller = TextEditingController(text: widget.network.serverUrl);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final lobby = snapshot?.lobby;
    final myId = snapshot?.you.id;
    final myRole = snapshot?.you.role ?? PlayerRole.spectator;
    final myRoleState = lobby?.roles.where((role) => role.playerId == myId).firstOrNull;
    final leha = lobby?.roles.where((role) => role.role == PlayerRole.leha).firstOrNull;
    final bakhirkin = lobby?.roles.where((role) => role.role == PlayerRole.bakhirkin).firstOrNull;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Card(
        color: const Color(0xee070a12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Лобби', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(labelText: 'WebSocket сервер', border: OutlineInputBorder()),
                onSubmitted: widget.network.connect,
              ),
              const SizedBox(height: 10),
              FilledButton.tonal(
                onPressed: () => widget.network.connect(_controller.text),
                child: const Text('Подключиться'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _RoleButton(
                      label: 'Леха${leha?.ready == true ? ' ✓' : ''}',
                      selected: myRole == PlayerRole.leha,
                      disabled: leha?.taken == true && leha?.playerId != myId,
                      onPressed: () => widget.network.selectRole(PlayerRole.leha),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RoleButton(
                      label: 'Бахиркин${bakhirkin?.ready == true ? ' ✓' : ''}',
                      selected: myRole == PlayerRole.bakhirkin,
                      disabled: bakhirkin?.taken == true && bakhirkin?.playerId != myId,
                      onPressed: () => widget.network.selectRole(PlayerRole.bakhirkin),
                    ),
                  ),
                ],
              ),
              if (myRole == PlayerRole.leha) ...[
                const SizedBox(height: 8),
                SegmentedButton<LehaAspect>(
                  segments: const [
                    ButtonSegment(value: LehaAspect.superLeha, label: Text('Супер')),
                    ButtonSegment(value: LehaAspect.spider, label: Text('Паук')),
                    ButtonSegment(value: LehaAspect.wizard, label: Text('Маг')),
                  ],
                  selected: {myRoleState?.aspect ?? LehaAspect.superLeha},
                  onSelectionChanged: (selection) => widget.network.selectAspect(selection.first),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: myRole == PlayerRole.spectator ? null : widget.network.spectate,
                child: const Text('Наблюдатель'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: myRoleState == null ? null : () => widget.network.ready(!myRoleState.ready),
                child: Text(myRoleState?.ready == true ? 'Готов: да' : 'Готов'),
              ),
              const SizedBox(height: 12),
              Text(
                myRole == PlayerRole.spectator
                    ? 'Вы наблюдатель. Леха: ${leha?.taken == true ? 'занят' : 'свободен'}, Бахиркин: ${bakhirkin?.taken == true ? 'занят' : 'свободен'}.'
                    : 'Леха ${leha?.ready == true ? 'готов' : 'не готов'}, Бахиркин ${bakhirkin?.ready == true ? 'готов' : 'не готов'}. Наблюдатели: ${lobby?.spectators ?? 0}.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TouchControls extends StatelessWidget {
  const _TouchControls({required this.network});

  final GameNetworkClient network;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DirectionButton(label: '↑', direction: MoveDirection.up, network: network),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _DirectionButton(label: '←', direction: MoveDirection.left, network: network),
              const SizedBox(width: 58),
              _DirectionButton(label: '→', direction: MoveDirection.right, network: network),
            ],
          ),
          _DirectionButton(label: '↓', direction: MoveDirection.down, network: network),
        ],
      ),
    );
  }
}

class _DirectionButton extends StatelessWidget {
  const _DirectionButton({
    required this.label,
    required this.direction,
    required this.network,
  });

  final String label;
  final MoveDirection direction;
  final GameNetworkClient network;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => network.input(direction),
      onPointerUp: (_) => network.stop(),
      onPointerCancel: (_) => network.stop(),
      child: SizedBox(
        width: 58,
        height: 50,
        child: FilledButton.tonal(
          onPressed: null,
          child: Text(label, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: disabled ? null : onPressed,
      style: FilledButton.styleFrom(
        foregroundColor: selected ? const Color(0xff00f2ea) : null,
      ),
      child: Text(label),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xdd0a0f1c),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: const TextStyle(color: Color(0xffaeb9ca), fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: Card(
        color: const Color(0xee070a12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

String _formatTime(int ms) {
  final totalSeconds = (ms / 1000).ceil().clamp(0, 999).toInt();
  final minutes = totalSeconds ~/ 60;
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
