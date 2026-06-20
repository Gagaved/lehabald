/// Authoritative targeting ranges in map tiles, shared by server validation and
/// client-side placement previews.
abstract final class SkillTargetRange {
  static const trap = 2.5;
  static const web = 2.0;
  static const portal = 3.0;
  static const crystal = 3.0;
  static const chain = 3.0;
  static const clutch = 1.5;
  // baseSpeed (3.573) * barrel multiplier (1.84) * lifetime (4s).
  static const barrelPreview = 26.3;
  static const barrelRadius = 0.34;
  static const barrelStep = 3.573 * 1.84 * 0.016;
  static const barrelPreviewTicks = 4000 ~/ 16;
  static const femboy = 8.0;
}
