// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'game_types.dart';

class PlayerRoleMapper extends EnumMapper<PlayerRole> {
  PlayerRoleMapper._();

  static PlayerRoleMapper? _instance;
  static PlayerRoleMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PlayerRoleMapper._());
    }
    return _instance!;
  }

  static PlayerRole fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  PlayerRole decode(dynamic value) {
    switch (value) {
      case r'leha':
        return PlayerRole.leha;
      case r'bakhirkin':
        return PlayerRole.bakhirkin;
      case r'spectator':
        return PlayerRole.spectator;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(PlayerRole self) {
    switch (self) {
      case PlayerRole.leha:
        return r'leha';
      case PlayerRole.bakhirkin:
        return r'bakhirkin';
      case PlayerRole.spectator:
        return r'spectator';
    }
  }
}

extension PlayerRoleMapperExtension on PlayerRole {
  String toValue() {
    PlayerRoleMapper.ensureInitialized();
    return MapperContainer.globals.toValue<PlayerRole>(this) as String;
  }
}

class LehaAspectMapper extends EnumMapper<LehaAspect> {
  LehaAspectMapper._();

  static LehaAspectMapper? _instance;
  static LehaAspectMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LehaAspectMapper._());
    }
    return _instance!;
  }

  static LehaAspect fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  LehaAspect decode(dynamic value) {
    switch (value) {
      case r'superLeha':
        return LehaAspect.superLeha;
      case r'spider':
        return LehaAspect.spider;
      case r'wizard':
        return LehaAspect.wizard;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(LehaAspect self) {
    switch (self) {
      case LehaAspect.superLeha:
        return r'superLeha';
      case LehaAspect.spider:
        return r'spider';
      case LehaAspect.wizard:
        return r'wizard';
    }
  }
}

extension LehaAspectMapperExtension on LehaAspect {
  String toValue() {
    LehaAspectMapper.ensureInitialized();
    return MapperContainer.globals.toValue<LehaAspect>(this) as String;
  }
}

class GamePhaseMapper extends EnumMapper<GamePhase> {
  GamePhaseMapper._();

  static GamePhaseMapper? _instance;
  static GamePhaseMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GamePhaseMapper._());
    }
    return _instance!;
  }

  static GamePhase fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  GamePhase decode(dynamic value) {
    switch (value) {
      case r'waiting':
        return GamePhase.waiting;
      case r'playing':
        return GamePhase.playing;
      case r'ended':
        return GamePhase.ended;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(GamePhase self) {
    switch (self) {
      case GamePhase.waiting:
        return r'waiting';
      case GamePhase.playing:
        return r'playing';
      case GamePhase.ended:
        return r'ended';
    }
  }
}

extension GamePhaseMapperExtension on GamePhase {
  String toValue() {
    GamePhaseMapper.ensureInitialized();
    return MapperContainer.globals.toValue<GamePhase>(this) as String;
  }
}

class Vec2iMapper extends ClassMapperBase<Vec2i> {
  Vec2iMapper._();

  static Vec2iMapper? _instance;
  static Vec2iMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = Vec2iMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Vec2i';

  static int _$x(Vec2i v) => v.x;
  static const Field<Vec2i, int> _f$x = Field('x', _$x);
  static int _$y(Vec2i v) => v.y;
  static const Field<Vec2i, int> _f$y = Field('y', _$y);

  @override
  final MappableFields<Vec2i> fields = const {#x: _f$x, #y: _f$y};

  static Vec2i _instantiate(DecodingData data) {
    return Vec2i(data.dec(_f$x), data.dec(_f$y));
  }

  @override
  final Function instantiate = _instantiate;

  static Vec2i fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Vec2i>(map);
  }

  static Vec2i fromJson(String json) {
    return ensureInitialized().decodeJson<Vec2i>(json);
  }
}

mixin Vec2iMappable {
  String toJson() {
    return Vec2iMapper.ensureInitialized().encodeJson<Vec2i>(this as Vec2i);
  }

  Map<String, dynamic> toMap() {
    return Vec2iMapper.ensureInitialized().encodeMap<Vec2i>(this as Vec2i);
  }

  Vec2iCopyWith<Vec2i, Vec2i, Vec2i> get copyWith =>
      _Vec2iCopyWithImpl<Vec2i, Vec2i>(this as Vec2i, $identity, $identity);
  @override
  String toString() {
    return Vec2iMapper.ensureInitialized().stringifyValue(this as Vec2i);
  }

  @override
  bool operator ==(Object other) {
    return Vec2iMapper.ensureInitialized().equalsValue(this as Vec2i, other);
  }

  @override
  int get hashCode {
    return Vec2iMapper.ensureInitialized().hashValue(this as Vec2i);
  }
}

extension Vec2iValueCopy<$R, $Out> on ObjectCopyWith<$R, Vec2i, $Out> {
  Vec2iCopyWith<$R, Vec2i, $Out> get $asVec2i =>
      $base.as((v, t, t2) => _Vec2iCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class Vec2iCopyWith<$R, $In extends Vec2i, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? x, int? y});
  Vec2iCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _Vec2iCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Vec2i, $Out>
    implements Vec2iCopyWith<$R, Vec2i, $Out> {
  _Vec2iCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Vec2i> $mapper = Vec2iMapper.ensureInitialized();
  @override
  $R call({int? x, int? y}) =>
      $apply(FieldCopyWithData({if (x != null) #x: x, if (y != null) #y: y}));
  @override
  Vec2i $make(CopyWithData data) =>
      Vec2i(data.get(#x, or: $value.x), data.get(#y, or: $value.y));

  @override
  Vec2iCopyWith<$R2, Vec2i, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _Vec2iCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class Vec2dMapper extends ClassMapperBase<Vec2d> {
  Vec2dMapper._();

  static Vec2dMapper? _instance;
  static Vec2dMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = Vec2dMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'Vec2d';

  static double _$x(Vec2d v) => v.x;
  static const Field<Vec2d, double> _f$x = Field('x', _$x);
  static double _$y(Vec2d v) => v.y;
  static const Field<Vec2d, double> _f$y = Field('y', _$y);

  @override
  final MappableFields<Vec2d> fields = const {#x: _f$x, #y: _f$y};

  static Vec2d _instantiate(DecodingData data) {
    return Vec2d(data.dec(_f$x), data.dec(_f$y));
  }

  @override
  final Function instantiate = _instantiate;

  static Vec2d fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Vec2d>(map);
  }

  static Vec2d fromJson(String json) {
    return ensureInitialized().decodeJson<Vec2d>(json);
  }
}

mixin Vec2dMappable {
  String toJson() {
    return Vec2dMapper.ensureInitialized().encodeJson<Vec2d>(this as Vec2d);
  }

  Map<String, dynamic> toMap() {
    return Vec2dMapper.ensureInitialized().encodeMap<Vec2d>(this as Vec2d);
  }

  Vec2dCopyWith<Vec2d, Vec2d, Vec2d> get copyWith =>
      _Vec2dCopyWithImpl<Vec2d, Vec2d>(this as Vec2d, $identity, $identity);
  @override
  String toString() {
    return Vec2dMapper.ensureInitialized().stringifyValue(this as Vec2d);
  }

  @override
  bool operator ==(Object other) {
    return Vec2dMapper.ensureInitialized().equalsValue(this as Vec2d, other);
  }

  @override
  int get hashCode {
    return Vec2dMapper.ensureInitialized().hashValue(this as Vec2d);
  }
}

extension Vec2dValueCopy<$R, $Out> on ObjectCopyWith<$R, Vec2d, $Out> {
  Vec2dCopyWith<$R, Vec2d, $Out> get $asVec2d =>
      $base.as((v, t, t2) => _Vec2dCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class Vec2dCopyWith<$R, $In extends Vec2d, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({double? x, double? y});
  Vec2dCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _Vec2dCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Vec2d, $Out>
    implements Vec2dCopyWith<$R, Vec2d, $Out> {
  _Vec2dCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Vec2d> $mapper = Vec2dMapper.ensureInitialized();
  @override
  $R call({double? x, double? y}) =>
      $apply(FieldCopyWithData({if (x != null) #x: x, if (y != null) #y: y}));
  @override
  Vec2d $make(CopyWithData data) =>
      Vec2d(data.get(#x, or: $value.x), data.get(#y, or: $value.y));

  @override
  Vec2dCopyWith<$R2, Vec2d, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _Vec2dCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

