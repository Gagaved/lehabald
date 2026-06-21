import 'package:flutter/material.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';

import '../net/game_network_client.dart';

const _surface = Color(0xf20a0e17);
const _line = Color(0xff253149);
const _leha = Color(0xff57d6c7);
const _hunter = Color(0xffff6b62);
const _muted = Color(0xff9aa8bc);

class SessionDirectoryView extends StatefulWidget {
  const SessionDirectoryView({required this.network, super.key});
  final GameNetworkClient network;

  @override
  State<SessionDirectoryView> createState() => _SessionDirectoryViewState();
}

class _SessionDirectoryViewState extends State<SessionDirectoryView> {
  final _name = TextEditingController();
  final _room = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _room.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final directory = widget.network.directory;
    final sessions = directory?.sessions ?? const <SessionSummaryDto>[];
    final nickname = widget.network.nickname;
    return ColoredBox(
      color: const Color(0xee05070d),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text('LEHA BALD',
                    style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2)),
                const SizedBox(height: 4),
                const Text('Публичные игровые сессии',
                    style: TextStyle(color: _muted, fontSize: 16)),
                const SizedBox(height: 24),
                _Panel(
                    child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 240,
                      child: TextField(
                        controller: _name,
                        maxLength: 20,
                        decoration: InputDecoration(
                          labelText: 'Никнейм',
                          hintText: nickname.isEmpty ? 'Введите ник' : nickname,
                          counterText: '',
                        ),
                        onSubmitted: _saveName,
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () => _saveName(_name.text),
                      child: Text(nickname.isEmpty ? 'Сохранить' : 'Сменить'),
                    ),
                    if (nickname.isNotEmpty)
                      Text('Вы: $nickname',
                          style: const TextStyle(color: _leha)),
                  ],
                )),
                const SizedBox(height: 16),
                LayoutBuilder(builder: (context, constraints) {
                  final sessionList = _sessionList(sessions, nickname);
                  final overview = _DirectoryOverview(
                    directory: directory,
                    sessions: sessions,
                  );
                  final dashboard = _DirectoryDashboard(
                    stats: directory?.yourStats,
                    leaderboard:
                        directory?.leaderboard ?? const <UserStatsDto>[],
                  );
                  if (constraints.maxWidth >= 800) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              overview,
                              const SizedBox(height: 16),
                              sessionList,
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(width: 300, child: dashboard),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      overview,
                      const SizedBox(height: 16),
                      sessionList,
                      const SizedBox(height: 16),
                      dashboard,
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sessionList(List<SessionSummaryDto> sessions, String nickname) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          const Expanded(
              child: Text('СЕССИИ',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, letterSpacing: 1.2))),
          FilledButton.icon(
            onPressed: nickname.isEmpty ? null : _createRoom,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Создать'),
          ),
        ]),
        const SizedBox(height: 12),
        if (sessions.isEmpty)
          const _Panel(
              child: Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Column(children: [
              Icon(Icons.sports_esports_outlined, size: 44, color: _muted),
              SizedBox(height: 12),
              Text('Активных сессий пока нет'),
              SizedBox(height: 4),
              Text('Создайте первую комнату', style: TextStyle(color: _muted)),
            ]),
          ))
        else
          for (final session in sessions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SessionCard(
                session: session,
                enabled: nickname.isNotEmpty,
                onJoin: () => _join(session.id),
              ),
            ),
      ],
    );
  }

  void _saveName(String value) {
    if (value.trim().isEmpty) return;
    widget.network.register(value);
    _name.clear();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// Guards an action that needs a live socket. Returns false and shows why when
  /// the connection is down, so create/join never silently swallow the request.
  bool _requireConnection() {
    if (widget.network.online) return true;
    final reason = widget.network.lastDisconnectReason;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: const Color(0xffb3322b),
      content: Text(reason == null
          ? 'Нет связи с сервером — подождите переподключения'
          : 'Нет связи с сервером: $reason'),
    ));
    return false;
  }

  void _join(String id) {
    if (_requireConnection()) widget.network.joinSession(id);
  }

  Future<void> _createRoom() async {
    if (!_requireConnection()) return;
    _room.clear();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая сессия'),
        content: TextField(
          controller: _room,
          autofocus: true,
          maxLength: 28,
          decoration: const InputDecoration(labelText: 'Название'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.pop(context, _room.text),
              child: const Text('Создать')),
        ],
      ),
    );
    if (value != null && _requireConnection()) {
      widget.network.createSession(value);
    }
  }
}

class _DirectoryOverview extends StatelessWidget {
  const _DirectoryOverview({required this.directory, required this.sessions});

  final DirectorySnapshotDto? directory;
  final List<SessionSummaryDto> sessions;

  @override
  Widget build(BuildContext context) {
    final active = sessions
        .where((session) =>
            session.phase != SessionPhase.waiting &&
            session.phase != SessionPhase.matchResult)
        .length;
    final spectators =
        sessions.fold<int>(0, (total, session) => total + session.spectators);
    final metrics = [
      _DirectoryMetric(
        icon: Icons.people_alt_outlined,
        label: 'Онлайн',
        value: '${directory?.onlineUsers ?? 0}',
      ),
      _DirectoryMetric(
        icon: Icons.meeting_room_outlined,
        label: 'Комнаты',
        value: '${sessions.length}',
      ),
      _DirectoryMetric(
        icon: Icons.sports_esports_outlined,
        label: 'Активные игры',
        value: '$active',
      ),
      _DirectoryMetric(
        icon: Icons.visibility_outlined,
        label: 'Зрители',
        value: '$spectators',
      ),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 560) {
        return Row(children: [
          for (var index = 0; index < metrics.length; index++) ...[
            if (index > 0) const SizedBox(width: 10),
            Expanded(child: metrics[index]),
          ],
        ]);
      }
      final width = (constraints.maxWidth - 10) / 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final metric in metrics) SizedBox(width: width, child: metric),
        ],
      );
    });
  }
}

class _DirectoryMetric extends StatelessWidget {
  const _DirectoryMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _surface,
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, color: _muted, size: 21),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
          ]),
        ]),
      );
}

class _DirectoryDashboard extends StatelessWidget {
  const _DirectoryDashboard({required this.stats, required this.leaderboard});

  final UserStatsDto? stats;
  final List<UserStatsDto> leaderboard;

  @override
  Widget build(BuildContext context) => _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('ДАШБОРД',
                style:
                    TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            if (stats == null)
              const Text(
                'Введите никнейм, чтобы видеть личную статистику.',
                style: TextStyle(color: _muted),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff111827),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stats!.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 7),
                    Text(
                        'Победы ${stats!.wins}  ·  Поражения ${stats!.losses}'),
                    Text('Винрейт ${_winrate(stats!)}',
                        style: const TextStyle(
                            color: _leha, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Text('ЛИДЕРБОРД',
                style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1)),
            const SizedBox(height: 8),
            if (leaderboard.isEmpty)
              const Text('Пока нет завершенных матчей.',
                  style: TextStyle(color: _muted))
            else
              for (var index = 0; index < leaderboard.length; index++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(children: [
                    SizedBox(
                      width: 24,
                      child: Text('${index + 1}',
                          style: const TextStyle(color: _muted)),
                    ),
                    Expanded(
                      child: Text(leaderboard[index].name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: leaderboard[index].name == stats?.name
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: leaderboard[index].name == stats?.name
                                ? _leha
                                : null,
                          )),
                    ),
                    Text('${leaderboard[index].wins}W',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text('${leaderboard[index].losses}L',
                        style: const TextStyle(color: _muted)),
                  ]),
                ),
          ],
        ),
      );

  static String _winrate(UserStatsDto stats) {
    final total = stats.wins + stats.losses;
    if (total == 0) return '—';
    return '${(stats.wins / total * 100).round()}%';
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard(
      {required this.session, required this.enabled, required this.onJoin});
  final SessionSummaryDto session;
  final bool enabled;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final playing = session.phase != SessionPhase.waiting;
    return _Panel(
        child: Row(children: [
      Container(
          width: 5,
          height: 64,
          decoration: BoxDecoration(
              color: playing ? _hunter : _leha,
              borderRadius: BorderRadius.circular(8))),
      const SizedBox(width: 14),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(session.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(_phaseLabel(session.phase, session.round),
            style: const TextStyle(color: _muted)),
        if (session.players.isNotEmpty)
          Text(
              session.players
                  .map((p) => '${p.name} ${p.roundWins}')
                  .join('  •  '),
              overflow: TextOverflow.ellipsis),
      ])),
      const SizedBox(width: 12),
      Text('${session.spectators}', style: const TextStyle(color: _muted)),
      const SizedBox(width: 4),
      const Icon(Icons.visibility_outlined, size: 18, color: _muted),
      const SizedBox(width: 14),
      FilledButton.tonal(
          onPressed: enabled ? onJoin : null,
          child: Text(playing ? 'Смотреть' : 'Войти')),
    ]));
  }
}

class WaitingRoomView extends StatelessWidget {
  const WaitingRoomView(
      {required this.network, required this.snapshot, super.key});
  final GameNetworkClient network;
  final GameSnapshotDto snapshot;

  @override
  Widget build(BuildContext context) {
    final roles = snapshot.lobby.roles;
    final myId = snapshot.you.id;
    final lehaState = roles.where((r) => r.role == PlayerRole.leha).firstOrNull;
    final hunterState =
        roles.where((r) => r.role == PlayerRole.hunter).firstOrNull;
    return _ScreenShell(
      title: snapshot.session?.name ?? 'Комната',
      onLeave: network.leaveSession,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('ПОДКЛЮЧЕННЫЕ ИГРОКИ',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        _Panel(
            child: Column(children: [
          for (final user in snapshot.lobby.users)
            ListTile(
              leading: CircleAvatar(
                  child: Text(user.name.characters.first.toUpperCase())),
              title: Text(user.name),
              subtitle: Text(user.role == PlayerRole.spectator
                  ? 'В комнате'
                  : _roleName(user.role)),
              trailing: user.id == myId
                  ? const Text('ВЫ', style: TextStyle(color: _leha))
                  : null,
            ),
        ])),
        const SizedBox(height: 18),
        LayoutBuilder(builder: (context, constraints) {
          final cards = [
            _SeatCard(
                role: PlayerRole.leha,
                state: lehaState,
                snapshot: snapshot,
                onTake: () => network.selectRole(PlayerRole.leha)),
            _SeatCard(
                role: PlayerRole.hunter,
                state: hunterState,
                snapshot: snapshot,
                onTake: () => network.selectRole(PlayerRole.hunter)),
          ];
          return constraints.maxWidth > 620
              ? Row(children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 12),
                  Expanded(child: cards[1])
                ])
              : Column(
                  children: [cards[0], const SizedBox(height: 12), cards[1]]);
        }),
        const SizedBox(height: 14),
        if (snapshot.you.slot != null)
          OutlinedButton(
              onPressed: network.spectate,
              child: const Text('Освободить слот')),
        const SizedBox(height: 10),
        ExpansionTile(
          title: const Text('Настройки комнаты'),
          subtitle: const Text('Доступны всем до начала пика'),
          children: [_RoomSettings(network: network, snapshot: snapshot)],
        ),
      ]),
    );
  }
}

class _SeatCard extends StatelessWidget {
  const _SeatCard(
      {required this.role,
      required this.state,
      required this.snapshot,
      required this.onTake});
  final PlayerRole role;
  final RoleStateDto? state;
  final GameSnapshotDto snapshot;
  final VoidCallback onTake;

  @override
  Widget build(BuildContext context) {
    final user =
        snapshot.lobby.users.where((u) => u.id == state?.playerId).firstOrNull;
    final mine = state?.playerId == snapshot.you.id;
    final color = role == PlayerRole.leha ? _leha : _hunter;
    return _Panel(
        child: Column(children: [
      Icon(
          role == PlayerRole.leha
              ? Icons.directions_run_rounded
              : Icons.gps_fixed_rounded,
          color: color,
          size: 30),
      const SizedBox(height: 8),
      Text(_roleName(role),
          style: TextStyle(
              color: color, fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(user?.name ?? 'Слот свободен',
          style: const TextStyle(color: _muted)),
      const SizedBox(height: 12),
      FilledButton.tonal(
          onPressed: state?.taken == true ? null : onTake,
          child: Text(mine ? 'Вы заняли слот' : 'Занять')),
    ]));
  }
}

class PickView extends StatelessWidget {
  const PickView({required this.network, required this.snapshot, super.key});
  final GameNetworkClient network;
  final GameSnapshotDto snapshot;

  @override
  Widget build(BuildContext context) {
    final role = snapshot.you.role;
    final roleState = snapshot.lobby.roles
        .where((r) => r.playerId == snapshot.you.id)
        .firstOrNull;
    final opponent = snapshot.session?.players
        .where((p) => p.id != snapshot.you.id)
        .firstOrNull;
    final locked = roleState?.ready == true;
    final options = role == PlayerRole.leha
        ? const [
            (
              'Супер-Леха',
              'assets/images/player-head.png',
              LehaAspect.superLeha
            ),
            ('Леха-паук', 'assets/images/leha-spider.png', LehaAspect.spider),
            ('Леха-маг', 'assets/images/leha-wizard.png', LehaAspect.wizard),
          ]
        : const [
            ('Бахиркин', 'assets/images/chaser-head.png', HunterKind.bakhirkin),
            (
              'Саша-якудза',
              'assets/images/sasha-head.png',
              HunterKind.sashaYakuza
            ),
            ('Сима', 'assets/images/sima-head.png', HunterKind.sima),
          ];
    bool selected(Object value) => value is LehaAspect
        ? roleState?.aspect == value
        : roleState?.hunterKind == value;
    return _ScreenShell(
      title: 'Раунд ${snapshot.session?.round ?? 1} · ${_roleName(role)}',
      onLeave: network.leaveSession,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Открытый пик',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
            opponent == null
                ? 'Ожидание соперника'
                : '${opponent.name}: ${_roleName(opponent.role)}${opponent.pickLocked ? ' · выбор подтвержден' : ''}',
            style: const TextStyle(color: _muted)),
        const SizedBox(height: 18),
        Wrap(spacing: 12, runSpacing: 12, children: [
          for (final option in options)
            _PickCard(
              name: option.$1,
              asset: option.$2,
              selected: selected(option.$3),
              disabled: locked,
              onTap: () {
                final value = option.$3;
                if (value is LehaAspect) network.selectAspect(value);
                if (value is HunterKind) network.selectHunter(value);
              },
            ),
        ]),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => network.ready(!locked),
          icon: Icon(locked ? Icons.lock_open_rounded : Icons.lock_rounded),
          label: Text(locked ? 'Отменить подтверждение' : 'Подтвердить выбор'),
        ),
      ]),
    );
  }
}

class RoundResultView extends StatelessWidget {
  const RoundResultView({required this.snapshot, super.key});
  final GameSnapshotDto snapshot;

  @override
  Widget build(BuildContext context) {
    final session = snapshot.session!;
    final result = session.history.last;
    return _ResultCard(
      eyebrow: 'РАУНД ${result.round} ЗАВЕРШЕН',
      title: '${result.winnerName} побеждает',
      subtitle: '${_roleName(result.role)} · ${result.reason}',
      session: session,
      footer: 'Стороны меняются. Следующий пик начнется автоматически.',
    );
  }
}

class MatchResultView extends StatelessWidget {
  const MatchResultView(
      {required this.network, required this.snapshot, super.key});
  final GameNetworkClient network;
  final GameSnapshotDto snapshot;

  @override
  Widget build(BuildContext context) {
    final session = snapshot.session!;
    final winner =
        session.players.where((p) => p.id == session.matchWinnerId).firstOrNull;
    final me =
        session.players.where((p) => p.id == snapshot.you.id).firstOrNull;
    return _ResultCard(
      eyebrow: session.technical ? 'ТЕХНИЧЕСКАЯ ПОБЕДА' : 'МАТЧ ЗАВЕРШЕН',
      title: '${winner?.name ?? 'Игрок'} выиграл матч',
      subtitle: session.technical
          ? 'Соперник покинул матч'
          : 'Две победы подряд за разные стороны',
      session: session,
      footerWidget: Row(children: [
        Expanded(
            child: OutlinedButton(
                onPressed: network.leaveSession,
                child: const Text('К списку сессий'))),
        const SizedBox(width: 10),
        Expanded(
            child: FilledButton(
          onPressed: snapshot.you.slot == null ? null : network.rematch,
          child:
              Text(me?.rematch == true ? 'Ожидаем соперника' : 'Сыграть еще'),
        )),
      ]),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard(
      {required this.eyebrow,
      required this.title,
      required this.subtitle,
      required this.session,
      this.footer,
      this.footerWidget});
  final String eyebrow;
  final String title;
  final String subtitle;
  final SessionStateDto session;
  final String? footer;
  final Widget? footerWidget;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: const Color(0xbb05070d),
        child: Center(
            child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _Panel(
              child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(eyebrow,
                  style: const TextStyle(
                      color: _leha,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4)),
              const SizedBox(height: 10),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted)),
              const SizedBox(height: 20),
              MatchScore(session: session),
              if (session.phase == SessionPhase.matchResult &&
                  session.history.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final result in session.history)
                      Chip(
                        label: Text(
                            'R${result.round} · ${result.winnerName} · ${_roleName(result.role)}'),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              if (footer != null)
                Text(footer!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _muted)),
              if (footerWidget != null) footerWidget!,
            ]),
          )),
        )),
      );
}

class MatchScore extends StatelessWidget {
  const MatchScore({required this.session, super.key});
  final SessionStateDto session;

  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < session.players.length; i++) ...[
          if (i > 0)
            const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('—', style: TextStyle(color: _muted))),
          Expanded(
              child: Column(children: [
            Text(session.players[i].name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${session.players[i].roundWins}',
                style:
                    const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
            Text(
                session.matchWinnerId == session.players[i].id &&
                        !session.technical
                    ? 'Серия 2/2'
                    : session.streakOwnerId == session.players[i].id
                        ? 'Серия 1/2'
                        : 'Серия 0/2',
                style: TextStyle(
                    color: session.streakOwnerId == session.players[i].id
                        ? _leha
                        : _muted)),
          ])),
        ],
      ]);
}

class _PickCard extends StatelessWidget {
  const _PickCard(
      {required this.name,
      required this.asset,
      required this.selected,
      required this.disabled,
      required this.onTap});
  final String name;
  final String asset;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: disabled && !selected ? .45 : 1,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
              width: 150,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: _surface,
                  border: Border.all(
                      color: selected ? _leha : _line, width: selected ? 2 : 1),
                  borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                SizedBox(
                    height: 104,
                    child: Image.asset(asset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person, size: 60))),
                const SizedBox(height: 8),
                Text(name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ])),
        ),
      );
}

class _RoomSettings extends StatelessWidget {
  const _RoomSettings({required this.network, required this.snapshot});
  final GameNetworkClient network;
  final GameSnapshotDto snapshot;

  @override
  Widget build(BuildContext context) {
    final enabled = snapshot.enabledBiomes.toSet();
    final lehaBot = snapshot.lobby.roles
            .where((role) => role.role == PlayerRole.leha)
            .firstOrNull
            ?.bot ==
        true;
    final hunterBot = snapshot.lobby.roles
            .where((role) => role.role == PlayerRole.hunter)
            .firstOrNull
            ?.bot ==
        true;
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(children: [
          Wrap(spacing: 7, children: [
            for (final biome in CaveBiome.values)
              FilterChip(
                  label: Text(biome.name),
                  selected: enabled.contains(biome),
                  onSelected: (selected) {
                    final next = enabled.toSet();
                    selected ? next.add(biome) : next.remove(biome);
                    if (next.isNotEmpty) network.setBiomes(next.toList());
                  }),
          ]),
          SwitchListTile(
              title: const Text('Песочница'),
              value: snapshot.sandboxMode,
              onChanged: network.setSandbox),
          Row(children: [
            Expanded(
                child: OutlinedButton(
                    onPressed: () => lehaBot
                        ? network.removeBot(PlayerRole.leha)
                        : network.addBot(PlayerRole.leha),
                    child: Text(lehaBot ? '− Бот-жертва' : '+ Бот-жертва'))),
            const SizedBox(width: 8),
            Expanded(
                child: OutlinedButton(
                    onPressed: () => hunterBot
                        ? network.removeBot(PlayerRole.hunter)
                        : network.addBot(PlayerRole.hunter),
                    child:
                        Text(hunterBot ? '− Бот-охотник' : '+ Бот-охотник'))),
          ]),
        ]));
  }
}

class _ScreenShell extends StatelessWidget {
  const _ScreenShell(
      {required this.title, required this.child, required this.onLeave});
  final String title;
  final Widget child;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: const Color(0xe805070d),
        child: SafeArea(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Row(children: [
              IconButton(
                  onPressed: onLeave,
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Покинуть сессию'),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w900))),
            ]),
            const SizedBox(height: 18),
            child,
          ]),
        ))),
      );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _surface,
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(16)),
      child: child);
}

String _roleName(PlayerRole role) => switch (role) {
      PlayerRole.leha => 'Жертва',
      PlayerRole.hunter => 'Охотник',
      PlayerRole.spectator => 'Зритель',
    };

String _phaseLabel(SessionPhase phase, int round) => switch (phase) {
      SessionPhase.waiting => 'Ожидание игроков',
      SessionPhase.picking => 'Пик · раунд $round',
      SessionPhase.playing => 'Идет раунд $round',
      SessionPhase.roundResult => 'Результат раунда $round',
      SessionPhase.matchResult => 'Матч завершен',
    };
