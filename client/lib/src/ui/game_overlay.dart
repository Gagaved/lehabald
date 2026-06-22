import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';

import '../net/game_network_client.dart';
import 'debug_console_drawer.dart';
import 'game_hud.dart';
import 'session_flow.dart';

class GameOverlay extends StatefulWidget {
  const GameOverlay({
    required this.network,
    required this.onRequestGameFocus,
    super.key,
  });

  final GameNetworkClient network;
  final VoidCallback onRequestGameFocus;

  @override
  State<GameOverlay> createState() => _GameOverlayState();
}

class _GameOverlayState extends State<GameOverlay> {
  bool _consoleOpen = false;
  int? _focusedRound;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.network,
      builder: (context, _) {
        final network = widget.network;
        final snapshot = network.snapshot;
        final sessionPhase = snapshot?.session?.phase;
        final round = snapshot?.session?.round;
        if (sessionPhase == SessionPhase.playing && _focusedRound != round) {
          _focusedRound = round;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FocusManager.instance.primaryFocus?.unfocus();
            widget.onRequestGameFocus();
          });
        } else if (sessionPhase != SessionPhase.playing) {
          _focusedRound = null;
        }
        return SafeArea(
          child: Stack(
            children: [
              if (snapshot == null)
                SessionDirectoryView(network: network)
              else if (sessionPhase == SessionPhase.waiting)
                WaitingRoomView(network: network, snapshot: snapshot)
              else if (sessionPhase == SessionPhase.picking)
                PickView(network: network, snapshot: snapshot)
              else ...[
                GameHud(
                  network: network,
                  snapshot: snapshot,
                  onToggleConsole: () =>
                      setState(() => _consoleOpen = !_consoleOpen),
                  onRequestGameFocus: widget.onRequestGameFocus,
                ),
                if (sessionPhase == SessionPhase.roundResult)
                  RoundResultView(snapshot: snapshot),
                if (sessionPhase == SessionPhase.matchResult)
                  MatchResultView(network: network, snapshot: snapshot),
              ],
              if (MediaQuery.sizeOf(context).width < 720 &&
                  sessionPhase == SessionPhase.playing &&
                  snapshot?.you.slot != null) ...[
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, bottom: 28),
                    child: _Joystick(network: network),
                  ),
                ),
              ],
              if (_consoleOpen)
                Positioned.fill(
                  child: DebugConsoleDrawer(
                    network: network,
                    onClose: () => setState(() => _consoleOpen = false),
                  ),
                ),
              // Always on top: when the socket is down, say so instead of
              // leaving the player staring at an empty session list.
              _ConnectionBanner(network: network),
            ],
          ),
        );
      },
    );
  }
}

/// Slim top banner shown whenever the socket is not actively receiving data —
/// initial connect, a reconnect, or a silent stall (e.g. MTU black hole behind
/// a VPN). Shows the reason so a dropped connection is never silent.
class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.network});

  final GameNetworkClient network;

  @override
  Widget build(BuildContext context) {
    if (network.online) return const SizedBox.shrink();
    final reason = network.lastDisconnectReason;
    final lost = reason != null;
    final headline = network.status.isEmpty
        ? (lost ? 'Связь с сервером потеряна' : 'Подключение к серверу…')
        : network.status;
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: lost ? const Color(0xffb3322b) : const Color(0xff1f4f86),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(color: Color(0x66000000), blurRadius: 12)
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headline,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  if (lost)
                    Text(reason,
                        style: const TextStyle(
                            color: Color(0xfff2d2cf), fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Legacy HUD retained temporarily while lobby UI is split from this large file.
// ignore: unused_element
class _Hud extends StatelessWidget {
  const _Hud({required this.network, required this.snapshot});

  final GameNetworkClient network;
  final GameSnapshotDto? snapshot;

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    final role = s?.you.role ?? PlayerRole.spectator;
    final isLeha = role == PlayerRole.leha;
    final isHunter = role == PlayerRole.hunter;
    final hunterKind = _hunterKind(s);
    final myScore =
        s?.scores.where((score) => score.id == s.you.id).firstOrNull?.score ??
            0;
    final time = _formatTime(s?.game.timeLeftMs ?? 180000);
    final power = s?.game.lehaPowered == true
        ? ' BIG ${(s!.game.powerLeftMs / 1000).ceil()}с'
        : '';
    // No cooldown now — just show how many traps Bakhirkin has in hand (max 5).
    // The same button picks an un-sprung trap back up.
    final trapLabel = s == null ? 'Капкан' : 'Капкан ${s.game.trapCharges}';
    final abilityLabel = _abilityLabel(s);
    final hunter = s?.players.where((player) => player.slot == 1).firstOrNull;
    final hunterName = switch (hunterKind) {
      HunterKind.sashaYakuza => 'Саша',
      HunterKind.sima => 'Сима',
      _ => 'Бахиркин',
    };
    String cdLabel(String name, int ms) =>
        ms > 0 ? '$name ${(ms / 1000).ceil()}с' : name;
    final spiderMode = s?.game.spiderMode == true;
    final wizardMode = s != null && _aspectOf(s) == LehaAspect.wizard;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _Metric(
              label: 'Роль',
              value: isLeha
                  ? 'Леха $myScore'
                  : isHunter
                      ? hunterName
                      : 'Наблюдатель'),
          if (!wizardMode)
            _Metric(
              label: isLeha
                  ? (spiderMode ? 'Рафаэлки' : 'Время / TikTok')
                  : isHunter
                      ? 'Охота'
                      : 'Просмотр',
              value: isLeha
                  ? (spiderMode
                      ? '${s?.game.rafaelkiEaten ?? 0}/${s?.game.rafaelkiNeeded ?? 4}'
                      : '$time / ${s?.logos.length ?? 0}$power')
                  : time,
            ),
          // Clutch alert / hatch countdown — the hunter's notice that a clutch
          // was laid (he still has to find it), and Leha's hatch timer.
          if (s?.game.clutchActive == true)
            _Metric(
              label: isHunter ? '⚠ Кладка' : 'Кладка',
              value: '${((s!.game.clutchHatchMs) / 1000).ceil()}с',
            ),
          if (wizardMode)
            _Metric(
              label: 'Насыщение',
              value: '${(s.game.wizardSaturation * 100).floor()}%',
            ),
          if (hunter != null)
            _Metric(label: '$hunterName HP', value: '${hunter.hp}'),
          if (isHunter && hunterKind == HunterKind.sashaYakuza)
            FilledButton.tonal(
              onPressed:
                  s?.game.barrelAvailable == true ? network.useAbility : null,
              child: Text(cdLabel('Бочка', s?.game.barrelCooldownMs ?? 0)),
            )
          else if (isHunter && hunterKind == HunterKind.sima)
            FilledButton.tonal(
              onPressed:
                  s?.game.femboyAvailable == true ? network.useAbility : null,
              child: Text(cdLabel('Фембой', s?.game.femboyCooldownMs ?? 0)),
            )
          else
            FilledButton.tonal(
              onPressed: isHunter && s?.game.trapAvailable == true
                  ? network.placeTrap
                  : null,
              child: Text(trapLabel),
            ),
          if (isLeha)
            FilledButton.tonal(
              onPressed:
                  s?.game.abilityAvailable == true ? network.useAbility : null,
              child: Text(abilityLabel),
            ),
          if (isLeha && spiderMode)
            FilledButton.tonal(
              onPressed:
                  s?.game.clutchAvailable == true ? network.layClutch : null,
              child: const Text('Кладка (F)'),
            ),
          if (isLeha && wizardMode)
            FilledButton.tonal(
              onPressed: s.game.magicCrystalAvailable
                  ? network.placeMagicCrystal
                  : null,
              child: Text('Кристалл ${s.game.magicCrystalCharges} (C)'),
            ),
          if (isLeha && wizardMode)
            FilledButton.tonal(
              onPressed: s.game.magicChainCooldownMs == 0
                  ? network.activateMagicChain
                  : null,
              child: Text(s.game.magicChainCooldownMs > 0
                  ? 'Цепь ${(s.game.magicChainCooldownMs / 1000).ceil()}с'
                  : 'Цепь (F)'),
            ),
          OutlinedButton(
            onPressed: () => _showDiagnostics(context, network),
            child: const Text('Логи'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDiagnostics(
      BuildContext context, GameNetworkClient network) async {
    final text = network.diagnosticsText;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Логи клиента'),
        content: SizedBox(
          width: min(MediaQuery.sizeOf(context).width * 0.9, 760),
          height: min(MediaQuery.sizeOf(context).height * 0.65, 520),
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(
                  ClipboardData(text: network.diagnosticsText));
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Скопировать'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  HunterKind? _hunterKind(GameSnapshotDto? snapshot) {
    final s = snapshot;
    if (s == null) return null;
    final me = s.players.where((player) => player.id == s.you.id).firstOrNull;
    if (me?.hunterKind != null) return me!.hunterKind;
    return s.lobby.roles
        .where((r) => r.role == PlayerRole.hunter)
        .firstOrNull
        ?.hunterKind;
  }

  String _abilityLabel(GameSnapshotDto? snapshot) {
    final s = snapshot;
    if (s == null) return 'Способность';
    final aspect = s.you.role == PlayerRole.leha
        ? s.players
                .where((player) => player.id == s.you.id)
                .firstOrNull
                ?.aspect ??
            s.lobby.roles.firstOrNull?.aspect
        : null;
    if (aspect == LehaAspect.spider) {
      if (s.game.abilityCharges <= 0 && s.game.abilityCooldownMs > 0) {
        return 'Паутина ${(s.game.abilityCooldownMs / 1000).ceil()}с';
      }
      return 'Паутина ${s.game.abilityCharges}';
    }
    if (aspect == LehaAspect.wizard) {
      if (s.game.abilityCooldownMs > 0) {
        return 'Портал ${(s.game.abilityCooldownMs / 1000).ceil()}с';
      }
      return 'Портал ${s.game.abilityCharges}';
    }
    return 'Способность';
  }
}

/// Selectable character: a side (role) plus the concrete variant within it.
class _CharOption {
  const _CharOption(this.name, this.asset, this.desc, this.role,
      {this.aspect, this.hunter});

  final String name;
  final String asset;
  final String desc;
  final PlayerRole role;
  final LehaAspect? aspect;
  final HunterKind? hunter;
}

const _lehaChars = [
  _CharOption(
      'Супер-Леха',
      'assets/images/player-head.png',
      'Ест тиктоки. Супер-тикток даёт форму BIG — в ней можно съесть Охотника '
          '(дважды = победа). Победа: съесть Охотника 2 раза или продержаться 3 минуты. '
          'Поражение: попасться без BIG.',
      PlayerRole.leha,
      aspect: LehaAspect.superLeha),
  _CharOption(
      'Леха-Паук',
      'assets/images/leha-spider.png',
      'Не ест тиктоки — собирает рафаэлки (нужно 4 из 5, видит только обычным зрением). '
          'На F кладёт кладку (можно в кусты, не на стены/паутину); зреет 10с — '
          'не найдёт Охотник = победа. Паутина: только на потрескавшихся стенах '
          '(их немного на карте) — проход сквозь них. '
          'Победы по таймеру нет. Поражение: попасться.',
      PlayerRole.leha,
      aspect: LehaAspect.spider),
  _CharOption(
      'Леха-Маг',
      'assets/images/leha-wizard.png',
      'Ставит порталы (КД 20с). Кристалл (C) ставит и подбирает до 6 кристаллов. Кнопка Цепь (F) замыкает видимый '
          'контур возле выбранного кристалла. Энергия уничтожает объекты, '
          'замедляет Охотника и насыщает ритуал. Победа: заполнить насыщение. '
          'Охотник может валить кристаллы касанием.',
      PlayerRole.leha,
      aspect: LehaAspect.wizard),
];

const _hunterChars = [
  _CharOption(
      'Бахиркин',
      'assets/images/chaser-head.png',
      'Ставит до 5 капканов — оглушают Леху на месте, без КД. Той же кнопкой '
          'собирает свой капкан обратно. Чует свежий след Лехи рядом. '
          'Цель: поймать Леху (а Паука — не дать высидеть кладку).',
      PlayerRole.hunter,
      hunter: HunterKind.bakhirkin),
  _CharOption(
      'Саша-якудза',
      'assets/images/sasha-head.png',
      'Кидает бочку: рикошетит от стен, оглушает и ослепляет Леху. Если Леха был '
          'в прямой видимости при броске — бочка доворачивает в его сторону. КД 10с. '
          'Цель: поймать Леху.',
      PlayerRole.hunter,
      hunter: HunterKind.sashaYakuza),
  _CharOption(
      'Сима',
      'assets/images/sima-head.png',
      'Фембой на 1с: Леха в прямой видимости медленно тянется к Симе. КД 20с. '
          'Цель: поймать Леху.',
      PlayerRole.hunter,
      hunter: HunterKind.sima),
];

// Legacy lobby widgets are kept temporarily for character descriptions.
// ignore: unused_element
class _MainMenu extends StatelessWidget {
  const _MainMenu({required this.network, required this.snapshot});

  final GameNetworkClient network;
  final GameSnapshotDto? snapshot;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final lobby = _Lobby(network: network, snapshot: snapshot);
    final dash = snapshot == null ? null : _DashboardPanel(snapshot: snapshot!);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: wide
            ? Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  lobby,
                  if (dash != null) ...[const SizedBox(width: 14), dash],
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  lobby,
                  if (dash != null) ...[const SizedBox(height: 12), dash],
                ],
              ),
      ),
    );
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
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    widget.network.register(name);
    _nameController.clear();
    FocusScope.of(context).unfocus();
  }

  void _pick(_CharOption o) {
    if (o.role == PlayerRole.leha) {
      widget.network.selectRole(PlayerRole.leha);
      if (o.aspect != null) widget.network.selectAspect(o.aspect!);
    } else {
      widget.network.selectRole(PlayerRole.hunter);
      if (o.hunter != null) widget.network.selectHunter(o.hunter!);
    }
  }

  Widget _botButton(
      RoleStateDto? state, PlayerRole role, String name, String? myId) {
    final isBot = state?.bot == true;
    final takenByHuman =
        state?.taken == true && !isBot && state?.playerId != myId;
    if (isBot) {
      return FilledButton.tonal(
        onPressed: () => widget.network.removeBot(role),
        child: Text('✖ Бот: $name'),
      );
    }
    return OutlinedButton(
      onPressed: takenByHuman ? null : () => widget.network.addBot(role),
      child: Text('＋ Бот: $name'),
    );
  }

  static const _biomeLabels = {
    CaveBiome.forest: '🌿 Лес',
    CaveBiome.amethyst: '🍄 Аметист',
    CaveBiome.ember: '🔥 Вулкан',
    CaveBiome.frost: '❄️ Лёд',
    CaveBiome.sandstone: '🏜 Песок',
  };

  /// Checkboxes choosing which biomes the next generated map may use. At least
  /// one must stay enabled.
  Widget _biomeToggles(GameSnapshotDto? snapshot) {
    final enabled = (snapshot?.enabledBiomes.isNotEmpty == true)
        ? snapshot!.enabledBiomes.toSet()
        : CaveBiome.values.toSet();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final b in CaveBiome.values)
          FilterChip(
            label: Text(_biomeLabels[b] ?? b.name),
            selected: enabled.contains(b),
            onSelected: (sel) {
              final next = enabled.toSet();
              if (sel) {
                next.add(b);
              } else {
                next.remove(b);
              }
              if (next.isEmpty) return; // keep at least one biome enabled
              widget.network.setBiomes(next.toList());
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = widget.snapshot;
    final lobby = snapshot?.lobby;
    final myId = snapshot?.you.id;
    final myName = (snapshot?.you.name.isNotEmpty == true
            ? snapshot!.you.name
            : widget.network.nickname)
        .trim();
    final myRole = snapshot?.you.role ?? PlayerRole.spectator;
    final myRoleState =
        lobby?.roles.where((role) => role.playerId == myId).firstOrNull;
    final leha =
        lobby?.roles.where((role) => role.role == PlayerRole.leha).firstOrNull;
    final hunter = lobby?.roles
        .where((role) => role.role == PlayerRole.hunter)
        .firstOrNull;

    final lehaTakenByOther = leha?.taken == true && leha?.playerId != myId;
    final hunterTakenByOther =
        hunter?.taken == true && hunter?.playerId != myId;

    bool isSelected(_CharOption o) {
      if (myRole != o.role) return false;
      if (o.role == PlayerRole.leha) {
        return (myRoleState?.aspect ?? LehaAspect.superLeha) == o.aspect;
      }
      return (myRoleState?.hunterKind ?? HunterKind.bakhirkin) == o.hunter;
    }

    _CharOption? selected;
    for (final o in [..._lehaChars, ..._hunterChars]) {
      if (isSelected(o)) selected = o;
    }

    String readyText(RoleStateDto? state) {
      if (state?.ready == true) return 'готов';
      return 'не готов';
    }

    String slotText(RoleStateDto? state) {
      if (state?.taken != true) return 'свободен';
      return readyText(state);
    }

    Widget tilesFor(List<_CharOption> chars, bool takenByOther) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in chars)
              _CharTile(
                option: o,
                selected: isSelected(o),
                disabled: takenByOther,
                onTap: () => _pick(o),
              ),
          ],
        );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Card(
        color: const Color(0xee070a12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Выбор персонажа',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      maxLength: 20,
                      decoration: InputDecoration(
                        labelText: 'Никнейм',
                        hintText: myName.isEmpty ? 'Введите ник' : myName,
                        border: const OutlineInputBorder(),
                        counterText: '',
                      ),
                      onSubmitted: (_) => _saveName(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saveName,
                    child: Text(myName.isEmpty ? 'Войти' : 'Сменить'),
                  ),
                ],
              ),
              if (myName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 4),
                  child: Text('Вы вошли как: $myName',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xff00f2ea),
                          fontWeight: FontWeight.w600)),
                ),
              const SizedBox(height: 12),
              const _SectionLabel('Леха'),
              const SizedBox(height: 6),
              tilesFor(_lehaChars, lehaTakenByOther),
              const SizedBox(height: 12),
              const _SectionLabel('Охотник'),
              const SizedBox(height: 6),
              tilesFor(_hunterChars, hunterTakenByOther),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xdd0a0f1c),
                  border: Border.all(color: const Color(0x3300f2ea)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: selected == null
                    ? const Text('Выберите персонажа выше.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xffaeb9ca)))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(selected.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff00f2ea))),
                          const SizedBox(height: 4),
                          Text(selected.desc),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              const _SectionLabel('Биомы следующей карты'),
              const SizedBox(height: 6),
              _biomeToggles(snapshot),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Песочница'),
                subtitle:
                    const Text('Можно играть одному, условия победы отключены'),
                value: snapshot?.sandboxMode ?? false,
                onChanged: widget.network.setSandbox,
              ),
              const SizedBox(height: 4),
              const _SectionLabel('Боты'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                      child: _botButton(
                          leha, PlayerRole.leha, 'Супер-Леха', myId)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _botButton(
                          hunter, PlayerRole.hunter, 'Бахиркин', myId)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: myRole == PlayerRole.spectator
                          ? null
                          : widget.network.spectate,
                      child: const Text('Наблюдатель'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: myRoleState == null
                          ? null
                          : () => widget.network.ready(!myRoleState.ready),
                      child: Text(
                          myRoleState?.ready == true ? 'Готов: да' : 'Готов'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                myRole == PlayerRole.spectator
                    ? 'Вы наблюдатель. Леха: ${slotText(leha)}, Охотник: ${slotText(hunter)}.'
                    : 'Леха ${readyText(leha)}, Охотник ${readyText(hunter)}. Наблюдатели: ${lobby?.spectators ?? 0}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xffaeb9ca), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              color: Color(0xffaeb9ca),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2)),
    );
  }
}

class _CharTile extends StatelessWidget {
  const _CharTile({
    required this.option,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final _CharOption option;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? const Color(0xff00f2ea) : const Color(0x33ffffff);
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 92,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: selected ? const Color(0x2200f2ea) : const Color(0xdd0a0f1c),
            border: Border.all(color: borderColor, width: selected ? 2.5 : 1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 64,
                child: Image.asset(
                  option.asset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.person, size: 48),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                option.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.1,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? const Color(0xff00f2ea) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({required this.snapshot});

  final GameSnapshotDto snapshot;

  @override
  Widget build(BuildContext context) {
    final you = snapshot.yourStats;
    final board = snapshot.leaderboard;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320, minWidth: 260),
      child: Card(
        color: const Color(0xee070a12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Дашборд',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              if (you != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xdd0a0f1c),
                    border: Border.all(color: const Color(0x3300f2ea)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      const Text('Ваша статистика',
                          style: TextStyle(
                              color: Color(0xffaeb9ca), fontSize: 13)),
                      const SizedBox(height: 4),
                      Text('Победы ${you.wins} · Поражения ${you.losses}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      Text('Винрейт ${_winrate(you)}',
                          style: const TextStyle(
                              color: Color(0xff00f2ea),
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
              else
                const Text('Введите ник, чтобы вести статистику.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xffaeb9ca))),
              const SizedBox(height: 12),
              const _SectionLabel('Лидерборд'),
              const SizedBox(height: 6),
              if (board.isEmpty)
                const Text('Пока нет сыгранных игр.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xffaeb9ca)))
              else ...[
                const Row(
                  children: [
                    SizedBox(width: 22, child: Text('#', style: _thStyle)),
                    Expanded(child: Text('Игрок', style: _thStyle)),
                    SizedBox(
                        width: 36,
                        child: Text('W',
                            textAlign: TextAlign.right, style: _thStyle)),
                    SizedBox(
                        width: 36,
                        child: Text('L',
                            textAlign: TextAlign.right, style: _thStyle)),
                  ],
                ),
                const SizedBox(height: 2),
                for (var i = 0; i < board.length; i += 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(width: 22, child: Text('${i + 1}')),
                        Expanded(
                          child: Text(
                            board[i].name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: _isMe(board[i].name)
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: _isMe(board[i].name)
                                  ? const Color(0xff00f2ea)
                                  : null,
                            ),
                          ),
                        ),
                        SizedBox(
                            width: 36,
                            child: Text('${board[i].wins}',
                                textAlign: TextAlign.right)),
                        SizedBox(
                            width: 36,
                            child: Text('${board[i].losses}',
                                textAlign: TextAlign.right)),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _isMe(String name) =>
      name == snapshot.you.name && snapshot.you.name.isNotEmpty;

  String _winrate(UserStatsDto s) {
    final total = s.wins + s.losses;
    if (total == 0) return '—';
    return '${(s.wins / total * 100).round()}%';
  }
}

const _thStyle = TextStyle(
    color: Color(0xffaeb9ca), fontSize: 13, fontWeight: FontWeight.w600);

HunterKind? _hunterKindOf(GameSnapshotDto s) {
  final me = s.players.where((p) => p.id == s.you.id).firstOrNull;
  if (me?.hunterKind != null) return me!.hunterKind;
  return s.lobby.roles
      .where((r) => r.role == PlayerRole.hunter)
      .firstOrNull
      ?.hunterKind;
}

LehaAspect? _aspectOf(GameSnapshotDto s) {
  final me = s.players.where((p) => p.id == s.you.id).firstOrNull;
  if (me?.aspect != null) return me!.aspect;
  return s.lobby.roles
      .where((r) => r.role == PlayerRole.leha)
      .firstOrNull
      ?.aspect;
}

/// Left-hand analog stick: drag to choose one of 8 directions; release to stop.
class _Joystick extends StatefulWidget {
  const _Joystick({required this.network});

  final GameNetworkClient network;

  @override
  State<_Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<_Joystick> {
  static const double _size = 132;
  static const double _knob = 56;

  Offset _knobOffset = Offset.zero;
  MoveDirection? _current;

  void _update(Offset local) {
    const center = Offset(_size / 2, _size / 2);
    final v = local - center;
    final radius = _size / 2 - _knob / 4;
    final clamped =
        v.distance > radius ? Offset.fromDirection(v.direction, radius) : v;
    final dir = v.distance < radius * 0.35 ? null : _dirFor(v);
    if (dir != _current) {
      _current = dir;
      if (dir == null) {
        widget.network.stop();
      } else {
        widget.network.input(dir);
      }
    }
    setState(() => _knobOffset = clamped);
  }

  void _end() {
    setState(() => _knobOffset = Offset.zero);
    if (_current != null) {
      _current = null;
      widget.network.stop();
    }
  }

  MoveDirection _dirFor(Offset v) {
    final deg = v.direction * 180 / pi; // y is down: 0=right, 90=down
    final idx = ((deg + 360 + 22.5) ~/ 45) % 8;
    const dirs = [
      MoveDirection.right,
      MoveDirection.downRight,
      MoveDirection.down,
      MoveDirection.downLeft,
      MoveDirection.left,
      MoveDirection.upLeft,
      MoveDirection.up,
      MoveDirection.upRight,
    ];
    return dirs[idx];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _update(d.localPosition),
      onPanUpdate: (d) => _update(d.localPosition),
      onPanEnd: (_) => _end(),
      onPanCancel: _end,
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x55070a12),
          border: Border.all(color: const Color(0x3300f2ea), width: 2),
        ),
        child: Stack(
          children: [
            Positioned(
              left: _size / 2 - _knob / 2 + _knobOffset.dx,
              top: _size / 2 - _knob / 2 + _knobOffset.dy,
              child: Container(
                width: _knob,
                height: _knob,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xcc00f2ea),
                  boxShadow: const [
                    BoxShadow(color: Color(0x6600f2ea), blurRadius: 12)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Right-hand action button — context-sensitive: ability / trap / barrel.
// Legacy mobile action control; the skill bar now handles all actions.
// ignore: unused_element
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.network, required this.snapshot});

  final GameNetworkClient network;
  final GameSnapshotDto snapshot;

  @override
  Widget build(BuildContext context) {
    final role = snapshot.you.role;
    final game = snapshot.game;
    String label;
    bool enabled;
    VoidCallback onTap;

    if (role == PlayerRole.hunter) {
      final kind = _hunterKindOf(snapshot);
      if (kind == HunterKind.sashaYakuza) {
        label = 'Бочка';
        enabled = game.barrelAvailable;
        onTap = network.useAbility;
      } else if (kind == HunterKind.sima) {
        label = 'Фембой';
        enabled = game.femboyAvailable;
        onTap = network.useAbility;
      } else {
        label = 'Капкан';
        enabled = game.trapAvailable;
        onTap = network.placeTrap;
      }
    } else if (role == PlayerRole.leha) {
      final aspect = _aspectOf(snapshot);
      if (aspect == LehaAspect.spider) {
        label = 'Паутина';
      } else if (aspect == LehaAspect.wizard) {
        label = game.abilityCooldownMs > 0
            ? 'Портал\n${(game.abilityCooldownMs / 1000).ceil()}с'
            : 'Портал';
      } else {
        return const SizedBox.shrink(); // Super-Leha has no active ability
      }
      enabled = game.abilityAvailable;
      onTap = network.useAbility;
    } else {
      return const SizedBox.shrink();
    }

    final action = SizedBox(
      width: 96,
      height: 96,
      child: FilledButton(
        onPressed: enabled ? onTap : null,
        style: FilledButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          backgroundColor: const Color(0xcc00a39d),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
    if (role == PlayerRole.leha && _aspectOf(snapshot) == LehaAspect.wizard) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          action,
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed:
                game.magicCrystalAvailable ? network.placeMagicCrystal : null,
            child: Text('Кристалл ${game.magicCrystalCharges}'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: game.magicChainCooldownMs == 0
                ? network.activateMagicChain
                : null,
            child: Text(game.magicChainCooldownMs > 0
                ? 'Цепь ${(game.magicChainCooldownMs / 1000).ceil()}с'
                : 'Цепь'),
          ),
        ],
      );
    }
    return action;
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
          Text(label,
              style: const TextStyle(color: Color(0xffaeb9ca), fontSize: 13)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        ],
      ),
    );
  }
}

// ignore: unused_element
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
          child: Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18)),
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
