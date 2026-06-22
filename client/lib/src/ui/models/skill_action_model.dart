import 'package:flutter/material.dart';

import '../../game/skill_targeting.dart';

enum SkillActionKind {
  primary,
  trap,
  clutch,
  crystal,
  chain,
}

/// Presentation model for one actionable skill in the in-game HUD.
///
/// Gameplay remains server-authoritative; this model only describes how the
/// latest snapshot should be presented and which command the button represents.
@immutable
class SkillActionModel {
  const SkillActionModel({
    required this.kind,
    required this.name,
    required this.description,
    required this.icon,
    required this.hotkey,
    required this.enabled,
    this.cooldownMs = 0,
    this.charges,
    this.accent = const Color(0xff56d6c9),
    required this.targetingSkill,
    required this.range,
    required this.projection,
    this.directAction,
  });

  final SkillActionKind kind;
  final String name;
  final String description;
  final IconData icon;
  final String hotkey;
  final bool enabled;
  final int cooldownMs;
  final int? charges;
  final Color accent;
  final TargetingSkill targetingSkill;
  final double range;
  final SkillProjectionKind projection;

  /// When set, pressing this action fires immediately (no aim/targeting step).
  /// Used by Sima's instant "Фембой" and held-spray "Камингаут".
  final VoidCallback? directAction;
}
