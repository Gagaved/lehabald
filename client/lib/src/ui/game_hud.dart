import 'package:flutter/material.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';

import '../net/game_network_client.dart';
import '../game/skill_targeting.dart';
import 'models/skill_action_model.dart';

class GameHud extends StatelessWidget {
  const GameHud({
    required this.network,
    required this.snapshot,
    required this.onToggleConsole,
    super.key,
  });

  final GameNetworkClient network;
  final GameSnapshotDto? snapshot;
  final VoidCallback onToggleConsole;

  @override
  Widget build(BuildContext context) {
    final s = snapshot;
    if (s == null || s.game.phase != GamePhase.playing) {
      return Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: _UtilityButton(
            icon: Icons.terminal_rounded,
            tooltip: 'Открыть консоль',
            onPressed: onToggleConsole,
          ),
        ),
      );
    }

    final compact = MediaQuery.sizeOf(context).width < 720;
    final actions = _actionsFor(s);
    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(compact ? 8 : 18, 8, 8, 0),
            child: _StatusStrip(
              snapshot: s,
              network: network,
              onToggleConsole: onToggleConsole,
              compact: compact,
            ),
          ),
        ),
        if (actions.isNotEmpty)
          Align(
            alignment: compact ? Alignment.bottomRight : Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                right: compact ? 14 : 0,
                bottom: compact ? 22 : 14,
              ),
              child: _SkillBar(
                actions: actions,
                compact: compact,
                selected: network.targetingSkill,
                onPressed: _activate,
              ),
            ),
          ),
      ],
    );
  }

  void _activate(SkillActionModel action) =>
      network.beginTargeting(action.targetingSkill);

  List<SkillActionModel> _actionsFor(GameSnapshotDto s) {
    final me = s.players.where((p) => p.id == s.you.id).firstOrNull;
    if (s.you.role == PlayerRole.hunter) {
      return switch (me?.hunterKind) {
        HunterKind.sashaYakuza => [
            SkillActionModel(
              kind: SkillActionKind.primary,
              name: 'Бочка',
              description: 'Бросает рикошетящую бочку, оглушающую Лёху.',
              icon: Icons.sports_bar_rounded,
              hotkey: 'SPACE',
              enabled: s.game.barrelAvailable,
              cooldownMs: s.game.barrelCooldownMs,
              accent: const Color(0xffffa94d),
              targetingSkill: TargetingSkill.barrel,
              range: SkillTargetRange.barrelPreview,
              projection: SkillProjectionKind.direction,
            ),
          ],
        HunterKind.sima => [
            SkillActionModel(
              kind: SkillActionKind.primary,
              name: 'Фембой',
              description: 'Притягивает видимого Лёху к Симе.',
              icon: Icons.favorite_rounded,
              hotkey: 'SPACE',
              enabled: s.game.femboyAvailable,
              cooldownMs: s.game.femboyCooldownMs,
              accent: const Color(0xffff6fae),
              targetingSkill: TargetingSkill.femboy,
              range: SkillTargetRange.femboy,
              projection: SkillProjectionKind.direction,
            ),
          ],
        _ => [
            SkillActionModel(
              kind: SkillActionKind.trap,
              name: 'Капкан',
              description: 'Ставит капкан или подбирает свой рядом.',
              icon: Icons.control_point_duplicate_rounded,
              hotkey: 'SPACE',
              enabled: s.game.trapAvailable,
              cooldownMs: s.game.trapCooldownMs,
              charges: s.game.trapCharges,
              accent: const Color(0xffff695f),
              targetingSkill: TargetingSkill.trap,
              range: SkillTargetRange.trap,
              projection: SkillProjectionKind.placement,
            ),
          ],
      };
    }
    if (s.you.role != PlayerRole.leha) return const [];
    return switch (me?.aspect) {
      LehaAspect.spider => [
          SkillActionModel(
            kind: SkillActionKind.primary,
            name: 'Паутина',
            description: 'Прокладывает проход через потрескавшуюся стену.',
            icon: Icons.hub_rounded,
            hotkey: 'E',
            enabled: s.game.abilityAvailable,
            cooldownMs: s.game.abilityCooldownMs,
            charges: s.game.abilityCharges,
            targetingSkill: TargetingSkill.web,
            range: SkillTargetRange.web,
            projection: SkillProjectionKind.placement,
          ),
          SkillActionModel(
            kind: SkillActionKind.clutch,
            name: 'Кладка',
            description: 'Оставляет кладку после сбора рафаэлок.',
            icon: Icons.egg_alt_rounded,
            hotkey: 'F',
            enabled: s.game.clutchAvailable,
            accent: const Color(0xffc084fc),
            targetingSkill: TargetingSkill.clutch,
            range: SkillTargetRange.clutch,
            projection: SkillProjectionKind.placement,
          ),
        ],
      LehaAspect.wizard => [
          SkillActionModel(
            kind: SkillActionKind.primary,
            name: 'Портал',
            description: 'Ставит или подбирает конец связанного портала.',
            icon: Icons.motion_photos_on_rounded,
            hotkey: 'E',
            enabled: s.game.abilityAvailable,
            cooldownMs: s.game.abilityCooldownMs,
            charges: s.game.abilityCharges,
            accent: const Color(0xff45e0d6),
            targetingSkill: TargetingSkill.portal,
            range: SkillTargetRange.portal,
            projection: SkillProjectionKind.placement,
          ),
          SkillActionModel(
            kind: SkillActionKind.crystal,
            name: 'Кристалл',
            description: 'Ставит кристалл или подбирает ближайший собственный.',
            icon: Icons.diamond_rounded,
            hotkey: 'C',
            enabled: s.game.magicCrystalAvailable,
            charges: s.game.magicCrystalCharges,
            accent: const Color(0xffc084fc),
            targetingSkill: TargetingSkill.crystal,
            range: SkillTargetRange.crystal,
            projection: SkillProjectionKind.placement,
          ),
          SkillActionModel(
            kind: SkillActionKind.chain,
            name: 'Цепь',
            description: 'Замыкает видимый контур от ближайшего кристалла.',
            icon: Icons.polyline_rounded,
            hotkey: 'F',
            enabled: s.game.magicChainCooldownMs == 0,
            cooldownMs: s.game.magicChainCooldownMs,
            accent: const Color(0xffffd166),
            targetingSkill: TargetingSkill.chain,
            range: SkillTargetRange.chain,
            projection: SkillProjectionKind.chain,
          ),
        ],
      _ => const [],
    };
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({
    required this.snapshot,
    required this.network,
    required this.onToggleConsole,
    required this.compact,
  });

  final GameSnapshotDto snapshot;
  final GameNetworkClient network;
  final VoidCallback onToggleConsole;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final me =
        snapshot.players.where((p) => p.id == snapshot.you.id).firstOrNull;
    final score = snapshot.scores
            .where((value) => value.id == snapshot.you.id)
            .firstOrNull
            ?.score ??
        0;
    final title = snapshot.you.role == PlayerRole.leha
        ? switch (me?.aspect) {
            LehaAspect.spider => 'Лёха-паук',
            LehaAspect.wizard => 'Лёха-маг',
            _ => 'Супер-Лёха',
          }
        : snapshot.you.role == PlayerRole.hunter
            ? switch (me?.hunterKind) {
                HunterKind.sashaYakuza => 'Саша-якудза',
                HunterKind.sima => 'Сима',
                _ => 'Бахиркин',
              }
            : 'Наблюдатель';
    final seconds = (snapshot.game.timeLeftMs / 1000).ceil();
    final progress = me?.aspect == LehaAspect.wizard
        ? '${(snapshot.game.wizardSaturation * 100).floor()}%'
        : '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xe60a0e17),
          border: Border.all(color: const Color(0xff28344a)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
                color: Color(0x99000000), blurRadius: 18, offset: Offset(0, 6)),
          ],
        ),
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_rounded,
                  size: 20, color: Color(0xff56d6c9)),
              const SizedBox(width: 7),
              Flexible(
                child: Text('$title  •  $score',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 14),
              Icon(
                  me?.aspect == LehaAspect.wizard
                      ? Icons.auto_awesome_rounded
                      : Icons.timer_outlined,
                  size: 18,
                  color: const Color(0xffaab6c9)),
              const SizedBox(width: 5),
              Text(progress,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              _UtilityButton(
                icon: Icons.restart_alt_rounded,
                tooltip: 'Рестарт',
                onPressed: network.restart,
              ),
              _UtilityButton(
                icon: Icons.terminal_rounded,
                tooltip: 'Консоль',
                onPressed: onToggleConsole,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkillBar extends StatelessWidget {
  const _SkillBar(
      {required this.actions,
      required this.compact,
      required this.selected,
      required this.onPressed});

  final List<SkillActionModel> actions;
  final bool compact;
  final TargetingSkill? selected;
  final ValueChanged<SkillActionModel> onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xe60a0e17),
          border: Border.all(color: const Color(0xff28344a)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0xaa000000), blurRadius: 20)
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final action in actions) ...[
                _SkillButton(
                  action: action,
                  size: compact ? 58 : 78,
                  selected: selected == action.targetingSkill,
                  onPressed: action.enabled ? () => onPressed(action) : null,
                ),
                if (action != actions.last) const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      );
}

class _SkillButton extends StatelessWidget {
  const _SkillButton(
      {required this.action,
      required this.size,
      required this.selected,
      this.onPressed});

  final SkillActionModel action;
  final double size;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final cooldown =
        action.cooldownMs > 0 ? '${(action.cooldownMs / 1000).ceil()}' : null;
    return Tooltip(
      richMessage: TextSpan(children: [
        TextSpan(
            text: '${action.name} [${action.hotkey}]\n',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(
            text: '${action.description}\nДальность: ${action.range} клетки'),
      ]),
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Ink(
              decoration: BoxDecoration(
                color: disabled
                    ? const Color(0xff171b24)
                    : const Color(0xff202936),
                border: Border.all(
                    color: disabled ? const Color(0xff343b48) : action.accent,
                    width: selected ? 3 : 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Center(
                      child: Icon(action.icon,
                          size: size * .42,
                          color: disabled
                              ? const Color(0xff626b78)
                              : action.accent)),
                  Positioned(left: 4, top: 4, child: _Badge(action.hotkey)),
                  if (action.charges != null)
                    Positioned(
                        right: 4,
                        top: 4,
                        child: _Badge('${action.charges}', bright: true)),
                  Positioned(
                    left: 3,
                    right: 3,
                    bottom: 4,
                    child: Text(action.name,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: size < 70 ? 9 : 10,
                            fontWeight: FontWeight.w700,
                            color: disabled
                                ? const Color(0xff747e8e)
                                : Colors.white)),
                  ),
                  if (cooldown != null)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xa6000000),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Center(
                            child: Text(cooldown,
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800))),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {this.bright = false});
  final String text;
  final bool bright;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: bright ? const Color(0xffecf4ff) : const Color(0xff05070c),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: bright
                    ? const Color(0xff111827)
                    : const Color(0xffd8e0ed))),
      );
}

class _UtilityButton extends StatelessWidget {
  const _UtilityButton(
      {required this.icon, required this.tooltip, required this.onPressed});
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
      );
}
