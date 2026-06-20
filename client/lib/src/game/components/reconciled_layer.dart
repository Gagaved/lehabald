part of '../leha_bald_game.dart';

/// Reconciles a list of server DTOs with long-lived Flame components.
///
/// The server is authoritative: every snapshot we diff the incoming DTOs against
/// the components we already hold, creating, updating and removing as needed.
/// This is the generalisation of the original portal layer so every entity
/// family (players, traps, barrels, ...) can reuse the same bookkeeping instead
/// of hand-rolling a `Map` + diff loop each time.
///
/// [TDto] is the snapshot record; [TComponent] is the live entity. Subclasses
/// provide identity ([keyOf]), construction ([create]) and per-frame
/// reconciliation ([updateComponent]).
abstract class _ReconciledLayer<TDto, TComponent extends Component>
    extends Component {
  _ReconciledLayer({super.priority});

  final Map<Object, TComponent> _entities = {};

  /// Stable identity for a DTO across snapshots (id, grid cell, ...).
  Object keyOf(TDto dto);

  /// Builds a fresh component for a DTO that has no live counterpart yet.
  TComponent create(TDto dto);

  /// Pushes the latest DTO state onto an existing component.
  void updateComponent(TComponent component, TDto dto);

  /// Called for a component whose DTO disappeared from the snapshot. The default
  /// removes it immediately; override to play an exit animation and remove the
  /// component yourself once it finishes.
  void disposeComponent(TComponent component) => component.removeFromParent();

  void sync(List<TDto> dtos) {
    final seen = <Object>{};
    for (final dto in dtos) {
      final key = keyOf(dto);
      seen.add(key);
      final current = _entities[key];
      if (current == null) {
        final component = create(dto);
        _entities[key] = component;
        add(component);
      } else {
        updateComponent(current, dto);
      }
    }
    if (_entities.isEmpty) return;
    for (final entry in _entities.entries.toList()) {
      if (!seen.contains(entry.key)) {
        _entities.remove(entry.key);
        disposeComponent(entry.value);
      }
    }
  }
}
