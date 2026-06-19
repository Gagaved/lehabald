// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'game_snapshot.dart';

class PlayerDtoMapper extends ClassMapperBase<PlayerDto> {
  PlayerDtoMapper._();

  static PlayerDtoMapper? _instance;
  static PlayerDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PlayerDtoMapper._());
      PlayerRoleMapper.ensureInitialized();
      LehaAspectMapper.ensureInitialized();
      HunterKindMapper.ensureInitialized();
      MoveDirectionMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'PlayerDto';

  static String _$id(PlayerDto v) => v.id;
  static const Field<PlayerDto, String> _f$id = Field('id', _$id);
  static int? _$slot(PlayerDto v) => v.slot;
  static const Field<PlayerDto, int> _f$slot = Field('slot', _$slot);
  static PlayerRole _$role(PlayerDto v) => v.role;
  static const Field<PlayerDto, PlayerRole> _f$role = Field('role', _$role);
  static double _$x(PlayerDto v) => v.x;
  static const Field<PlayerDto, double> _f$x = Field('x', _$x);
  static double _$y(PlayerDto v) => v.y;
  static const Field<PlayerDto, double> _f$y = Field('y', _$y);
  static int _$score(PlayerDto v) => v.score;
  static const Field<PlayerDto, int> _f$score = Field('score', _$score);
  static bool _$powered(PlayerDto v) => v.powered;
  static const Field<PlayerDto, bool> _f$powered = Field('powered', _$powered);
  static bool _$ghost(PlayerDto v) => v.ghost;
  static const Field<PlayerDto, bool> _f$ghost = Field('ghost', _$ghost);
  static bool _$stunned(PlayerDto v) => v.stunned;
  static const Field<PlayerDto, bool> _f$stunned = Field('stunned', _$stunned);
  static bool _$invulnerable(PlayerDto v) => v.invulnerable;
  static const Field<PlayerDto, bool> _f$invulnerable = Field(
    'invulnerable',
    _$invulnerable,
  );
  static int _$hp(PlayerDto v) => v.hp;
  static const Field<PlayerDto, int> _f$hp = Field('hp', _$hp);
  static LehaAspect? _$aspect(PlayerDto v) => v.aspect;
  static const Field<PlayerDto, LehaAspect> _f$aspect = Field(
    'aspect',
    _$aspect,
  );
  static HunterKind? _$hunterKind(PlayerDto v) => v.hunterKind;
  static const Field<PlayerDto, HunterKind> _f$hunterKind = Field(
    'hunterKind',
    _$hunterKind,
    opt: true,
  );
  static bool _$blinded(PlayerDto v) => v.blinded;
  static const Field<PlayerDto, bool> _f$blinded = Field(
    'blinded',
    _$blinded,
    opt: true,
    def: false,
  );
  static bool _$femboy(PlayerDto v) => v.femboy;
  static const Field<PlayerDto, bool> _f$femboy = Field(
    'femboy',
    _$femboy,
    opt: true,
    def: false,
  );
  static MoveDirection? _$facing(PlayerDto v) => v.facing;
  static const Field<PlayerDto, MoveDirection> _f$facing = Field(
    'facing',
    _$facing,
    opt: true,
  );

  @override
  final MappableFields<PlayerDto> fields = const {
    #id: _f$id,
    #slot: _f$slot,
    #role: _f$role,
    #x: _f$x,
    #y: _f$y,
    #score: _f$score,
    #powered: _f$powered,
    #ghost: _f$ghost,
    #stunned: _f$stunned,
    #invulnerable: _f$invulnerable,
    #hp: _f$hp,
    #aspect: _f$aspect,
    #hunterKind: _f$hunterKind,
    #blinded: _f$blinded,
    #femboy: _f$femboy,
    #facing: _f$facing,
  };

  static PlayerDto _instantiate(DecodingData data) {
    return PlayerDto(
      id: data.dec(_f$id),
      slot: data.dec(_f$slot),
      role: data.dec(_f$role),
      x: data.dec(_f$x),
      y: data.dec(_f$y),
      score: data.dec(_f$score),
      powered: data.dec(_f$powered),
      ghost: data.dec(_f$ghost),
      stunned: data.dec(_f$stunned),
      invulnerable: data.dec(_f$invulnerable),
      hp: data.dec(_f$hp),
      aspect: data.dec(_f$aspect),
      hunterKind: data.dec(_f$hunterKind),
      blinded: data.dec(_f$blinded),
      femboy: data.dec(_f$femboy),
      facing: data.dec(_f$facing),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PlayerDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PlayerDto>(map);
  }

  static PlayerDto fromJson(String json) {
    return ensureInitialized().decodeJson<PlayerDto>(json);
  }
}

mixin PlayerDtoMappable {
  String toJson() {
    return PlayerDtoMapper.ensureInitialized().encodeJson<PlayerDto>(
      this as PlayerDto,
    );
  }

  Map<String, dynamic> toMap() {
    return PlayerDtoMapper.ensureInitialized().encodeMap<PlayerDto>(
      this as PlayerDto,
    );
  }

  PlayerDtoCopyWith<PlayerDto, PlayerDto, PlayerDto> get copyWith =>
      _PlayerDtoCopyWithImpl<PlayerDto, PlayerDto>(
        this as PlayerDto,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return PlayerDtoMapper.ensureInitialized().stringifyValue(
      this as PlayerDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return PlayerDtoMapper.ensureInitialized().equalsValue(
      this as PlayerDto,
      other,
    );
  }

  @override
  int get hashCode {
    return PlayerDtoMapper.ensureInitialized().hashValue(this as PlayerDto);
  }
}

extension PlayerDtoValueCopy<$R, $Out> on ObjectCopyWith<$R, PlayerDto, $Out> {
  PlayerDtoCopyWith<$R, PlayerDto, $Out> get $asPlayerDto =>
      $base.as((v, t, t2) => _PlayerDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class PlayerDtoCopyWith<$R, $In extends PlayerDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    String? id,
    int? slot,
    PlayerRole? role,
    double? x,
    double? y,
    int? score,
    bool? powered,
    bool? ghost,
    bool? stunned,
    bool? invulnerable,
    int? hp,
    LehaAspect? aspect,
    HunterKind? hunterKind,
    bool? blinded,
    bool? femboy,
    MoveDirection? facing,
  });
  PlayerDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _PlayerDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PlayerDto, $Out>
    implements PlayerDtoCopyWith<$R, PlayerDto, $Out> {
  _PlayerDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PlayerDto> $mapper =
      PlayerDtoMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    Object? slot = $none,
    PlayerRole? role,
    double? x,
    double? y,
    int? score,
    bool? powered,
    bool? ghost,
    bool? stunned,
    bool? invulnerable,
    int? hp,
    Object? aspect = $none,
    Object? hunterKind = $none,
    bool? blinded,
    bool? femboy,
    Object? facing = $none,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (slot != $none) #slot: slot,
      if (role != null) #role: role,
      if (x != null) #x: x,
      if (y != null) #y: y,
      if (score != null) #score: score,
      if (powered != null) #powered: powered,
      if (ghost != null) #ghost: ghost,
      if (stunned != null) #stunned: stunned,
      if (invulnerable != null) #invulnerable: invulnerable,
      if (hp != null) #hp: hp,
      if (aspect != $none) #aspect: aspect,
      if (hunterKind != $none) #hunterKind: hunterKind,
      if (blinded != null) #blinded: blinded,
      if (femboy != null) #femboy: femboy,
      if (facing != $none) #facing: facing,
    }),
  );
  @override
  PlayerDto $make(CopyWithData data) => PlayerDto(
    id: data.get(#id, or: $value.id),
    slot: data.get(#slot, or: $value.slot),
    role: data.get(#role, or: $value.role),
    x: data.get(#x, or: $value.x),
    y: data.get(#y, or: $value.y),
    score: data.get(#score, or: $value.score),
    powered: data.get(#powered, or: $value.powered),
    ghost: data.get(#ghost, or: $value.ghost),
    stunned: data.get(#stunned, or: $value.stunned),
    invulnerable: data.get(#invulnerable, or: $value.invulnerable),
    hp: data.get(#hp, or: $value.hp),
    aspect: data.get(#aspect, or: $value.aspect),
    hunterKind: data.get(#hunterKind, or: $value.hunterKind),
    blinded: data.get(#blinded, or: $value.blinded),
    femboy: data.get(#femboy, or: $value.femboy),
    facing: data.get(#facing, or: $value.facing),
  );

  @override
  PlayerDtoCopyWith<$R2, PlayerDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _PlayerDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class LogoDtoMapper extends ClassMapperBase<LogoDto> {
  LogoDtoMapper._();

  static LogoDtoMapper? _instance;
  static LogoDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LogoDtoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'LogoDto';

  static int _$x(LogoDto v) => v.x;
  static const Field<LogoDto, int> _f$x = Field('x', _$x);
  static int _$y(LogoDto v) => v.y;
  static const Field<LogoDto, int> _f$y = Field('y', _$y);
  static bool _$power(LogoDto v) => v.power;
  static const Field<LogoDto, bool> _f$power = Field('power', _$power);

  @override
  final MappableFields<LogoDto> fields = const {
    #x: _f$x,
    #y: _f$y,
    #power: _f$power,
  };

  static LogoDto _instantiate(DecodingData data) {
    return LogoDto(
      x: data.dec(_f$x),
      y: data.dec(_f$y),
      power: data.dec(_f$power),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static LogoDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<LogoDto>(map);
  }

  static LogoDto fromJson(String json) {
    return ensureInitialized().decodeJson<LogoDto>(json);
  }
}

mixin LogoDtoMappable {
  String toJson() {
    return LogoDtoMapper.ensureInitialized().encodeJson<LogoDto>(
      this as LogoDto,
    );
  }

  Map<String, dynamic> toMap() {
    return LogoDtoMapper.ensureInitialized().encodeMap<LogoDto>(
      this as LogoDto,
    );
  }

  LogoDtoCopyWith<LogoDto, LogoDto, LogoDto> get copyWith =>
      _LogoDtoCopyWithImpl<LogoDto, LogoDto>(
        this as LogoDto,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return LogoDtoMapper.ensureInitialized().stringifyValue(this as LogoDto);
  }

  @override
  bool operator ==(Object other) {
    return LogoDtoMapper.ensureInitialized().equalsValue(
      this as LogoDto,
      other,
    );
  }

  @override
  int get hashCode {
    return LogoDtoMapper.ensureInitialized().hashValue(this as LogoDto);
  }
}

extension LogoDtoValueCopy<$R, $Out> on ObjectCopyWith<$R, LogoDto, $Out> {
  LogoDtoCopyWith<$R, LogoDto, $Out> get $asLogoDto =>
      $base.as((v, t, t2) => _LogoDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class LogoDtoCopyWith<$R, $In extends LogoDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? x, int? y, bool? power});
  LogoDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _LogoDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LogoDto, $Out>
    implements LogoDtoCopyWith<$R, LogoDto, $Out> {
  _LogoDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LogoDto> $mapper =
      LogoDtoMapper.ensureInitialized();
  @override
  $R call({int? x, int? y, bool? power}) => $apply(
    FieldCopyWithData({
      if (x != null) #x: x,
      if (y != null) #y: y,
      if (power != null) #power: power,
    }),
  );
  @override
  LogoDto $make(CopyWithData data) => LogoDto(
    x: data.get(#x, or: $value.x),
    y: data.get(#y, or: $value.y),
    power: data.get(#power, or: $value.power),
  );

  @override
  LogoDtoCopyWith<$R2, LogoDto, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _LogoDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class TrapDtoMapper extends ClassMapperBase<TrapDto> {
  TrapDtoMapper._();

  static TrapDtoMapper? _instance;
  static TrapDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TrapDtoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'TrapDto';

  static int _$x(TrapDto v) => v.x;
  static const Field<TrapDto, int> _f$x = Field('x', _$x);
  static int _$y(TrapDto v) => v.y;
  static const Field<TrapDto, int> _f$y = Field('y', _$y);
  static int _$placedAt(TrapDto v) => v.placedAt;
  static const Field<TrapDto, int> _f$placedAt = Field('placedAt', _$placedAt);
  static int _$expiresAt(TrapDto v) => v.expiresAt;
  static const Field<TrapDto, int> _f$expiresAt = Field(
    'expiresAt',
    _$expiresAt,
  );
  static bool _$triggered(TrapDto v) => v.triggered;
  static const Field<TrapDto, bool> _f$triggered = Field(
    'triggered',
    _$triggered,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<TrapDto> fields = const {
    #x: _f$x,
    #y: _f$y,
    #placedAt: _f$placedAt,
    #expiresAt: _f$expiresAt,
    #triggered: _f$triggered,
  };

  static TrapDto _instantiate(DecodingData data) {
    return TrapDto(
      x: data.dec(_f$x),
      y: data.dec(_f$y),
      placedAt: data.dec(_f$placedAt),
      expiresAt: data.dec(_f$expiresAt),
      triggered: data.dec(_f$triggered),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static TrapDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<TrapDto>(map);
  }

  static TrapDto fromJson(String json) {
    return ensureInitialized().decodeJson<TrapDto>(json);
  }
}

mixin TrapDtoMappable {
  String toJson() {
    return TrapDtoMapper.ensureInitialized().encodeJson<TrapDto>(
      this as TrapDto,
    );
  }

  Map<String, dynamic> toMap() {
    return TrapDtoMapper.ensureInitialized().encodeMap<TrapDto>(
      this as TrapDto,
    );
  }

  TrapDtoCopyWith<TrapDto, TrapDto, TrapDto> get copyWith =>
      _TrapDtoCopyWithImpl<TrapDto, TrapDto>(
        this as TrapDto,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return TrapDtoMapper.ensureInitialized().stringifyValue(this as TrapDto);
  }

  @override
  bool operator ==(Object other) {
    return TrapDtoMapper.ensureInitialized().equalsValue(
      this as TrapDto,
      other,
    );
  }

  @override
  int get hashCode {
    return TrapDtoMapper.ensureInitialized().hashValue(this as TrapDto);
  }
}

extension TrapDtoValueCopy<$R, $Out> on ObjectCopyWith<$R, TrapDto, $Out> {
  TrapDtoCopyWith<$R, TrapDto, $Out> get $asTrapDto =>
      $base.as((v, t, t2) => _TrapDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class TrapDtoCopyWith<$R, $In extends TrapDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? x, int? y, int? placedAt, int? expiresAt, bool? triggered});
  TrapDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _TrapDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, TrapDto, $Out>
    implements TrapDtoCopyWith<$R, TrapDto, $Out> {
  _TrapDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<TrapDto> $mapper =
      TrapDtoMapper.ensureInitialized();
  @override
  $R call({int? x, int? y, int? placedAt, int? expiresAt, bool? triggered}) =>
      $apply(
        FieldCopyWithData({
          if (x != null) #x: x,
          if (y != null) #y: y,
          if (placedAt != null) #placedAt: placedAt,
          if (expiresAt != null) #expiresAt: expiresAt,
          if (triggered != null) #triggered: triggered,
        }),
      );
  @override
  TrapDto $make(CopyWithData data) => TrapDto(
    x: data.get(#x, or: $value.x),
    y: data.get(#y, or: $value.y),
    placedAt: data.get(#placedAt, or: $value.placedAt),
    expiresAt: data.get(#expiresAt, or: $value.expiresAt),
    triggered: data.get(#triggered, or: $value.triggered),
  );

  @override
  TrapDtoCopyWith<$R2, TrapDto, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _TrapDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class WebDtoMapper extends ClassMapperBase<WebDto> {
  WebDtoMapper._();

  static WebDtoMapper? _instance;
  static WebDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = WebDtoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'WebDto';

  static int _$x(WebDto v) => v.x;
  static const Field<WebDto, int> _f$x = Field('x', _$x);
  static int _$y(WebDto v) => v.y;
  static const Field<WebDto, int> _f$y = Field('y', _$y);

  @override
  final MappableFields<WebDto> fields = const {#x: _f$x, #y: _f$y};

  static WebDto _instantiate(DecodingData data) {
    return WebDto(x: data.dec(_f$x), y: data.dec(_f$y));
  }

  @override
  final Function instantiate = _instantiate;

  static WebDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<WebDto>(map);
  }

  static WebDto fromJson(String json) {
    return ensureInitialized().decodeJson<WebDto>(json);
  }
}

mixin WebDtoMappable {
  String toJson() {
    return WebDtoMapper.ensureInitialized().encodeJson<WebDto>(this as WebDto);
  }

  Map<String, dynamic> toMap() {
    return WebDtoMapper.ensureInitialized().encodeMap<WebDto>(this as WebDto);
  }

  WebDtoCopyWith<WebDto, WebDto, WebDto> get copyWith =>
      _WebDtoCopyWithImpl<WebDto, WebDto>(this as WebDto, $identity, $identity);
  @override
  String toString() {
    return WebDtoMapper.ensureInitialized().stringifyValue(this as WebDto);
  }

  @override
  bool operator ==(Object other) {
    return WebDtoMapper.ensureInitialized().equalsValue(this as WebDto, other);
  }

  @override
  int get hashCode {
    return WebDtoMapper.ensureInitialized().hashValue(this as WebDto);
  }
}

extension WebDtoValueCopy<$R, $Out> on ObjectCopyWith<$R, WebDto, $Out> {
  WebDtoCopyWith<$R, WebDto, $Out> get $asWebDto =>
      $base.as((v, t, t2) => _WebDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class WebDtoCopyWith<$R, $In extends WebDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? x, int? y});
  WebDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _WebDtoCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, WebDto, $Out>
    implements WebDtoCopyWith<$R, WebDto, $Out> {
  _WebDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<WebDto> $mapper = WebDtoMapper.ensureInitialized();
  @override
  $R call({int? x, int? y}) =>
      $apply(FieldCopyWithData({if (x != null) #x: x, if (y != null) #y: y}));
  @override
  WebDto $make(CopyWithData data) => WebDto(
    x: data.get(#x, or: $value.x),
    y: data.get(#y, or: $value.y),
  );

  @override
  WebDtoCopyWith<$R2, WebDto, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _WebDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class BarrelDtoMapper extends ClassMapperBase<BarrelDto> {
  BarrelDtoMapper._();

  static BarrelDtoMapper? _instance;
  static BarrelDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = BarrelDtoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'BarrelDto';

  static double _$x(BarrelDto v) => v.x;
  static const Field<BarrelDto, double> _f$x = Field('x', _$x);
  static double _$y(BarrelDto v) => v.y;
  static const Field<BarrelDto, double> _f$y = Field('y', _$y);
  static double _$dirX(BarrelDto v) => v.dirX;
  static const Field<BarrelDto, double> _f$dirX = Field('dirX', _$dirX);
  static double _$dirY(BarrelDto v) => v.dirY;
  static const Field<BarrelDto, double> _f$dirY = Field('dirY', _$dirY);

  @override
  final MappableFields<BarrelDto> fields = const {
    #x: _f$x,
    #y: _f$y,
    #dirX: _f$dirX,
    #dirY: _f$dirY,
  };

  static BarrelDto _instantiate(DecodingData data) {
    return BarrelDto(
      x: data.dec(_f$x),
      y: data.dec(_f$y),
      dirX: data.dec(_f$dirX),
      dirY: data.dec(_f$dirY),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static BarrelDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<BarrelDto>(map);
  }

  static BarrelDto fromJson(String json) {
    return ensureInitialized().decodeJson<BarrelDto>(json);
  }
}

mixin BarrelDtoMappable {
  String toJson() {
    return BarrelDtoMapper.ensureInitialized().encodeJson<BarrelDto>(
      this as BarrelDto,
    );
  }

  Map<String, dynamic> toMap() {
    return BarrelDtoMapper.ensureInitialized().encodeMap<BarrelDto>(
      this as BarrelDto,
    );
  }

  BarrelDtoCopyWith<BarrelDto, BarrelDto, BarrelDto> get copyWith =>
      _BarrelDtoCopyWithImpl<BarrelDto, BarrelDto>(
        this as BarrelDto,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return BarrelDtoMapper.ensureInitialized().stringifyValue(
      this as BarrelDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return BarrelDtoMapper.ensureInitialized().equalsValue(
      this as BarrelDto,
      other,
    );
  }

  @override
  int get hashCode {
    return BarrelDtoMapper.ensureInitialized().hashValue(this as BarrelDto);
  }
}

extension BarrelDtoValueCopy<$R, $Out> on ObjectCopyWith<$R, BarrelDto, $Out> {
  BarrelDtoCopyWith<$R, BarrelDto, $Out> get $asBarrelDto =>
      $base.as((v, t, t2) => _BarrelDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class BarrelDtoCopyWith<$R, $In extends BarrelDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({double? x, double? y, double? dirX, double? dirY});
  BarrelDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _BarrelDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, BarrelDto, $Out>
    implements BarrelDtoCopyWith<$R, BarrelDto, $Out> {
  _BarrelDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<BarrelDto> $mapper =
      BarrelDtoMapper.ensureInitialized();
  @override
  $R call({double? x, double? y, double? dirX, double? dirY}) => $apply(
    FieldCopyWithData({
      if (x != null) #x: x,
      if (y != null) #y: y,
      if (dirX != null) #dirX: dirX,
      if (dirY != null) #dirY: dirY,
    }),
  );
  @override
  BarrelDto $make(CopyWithData data) => BarrelDto(
    x: data.get(#x, or: $value.x),
    y: data.get(#y, or: $value.y),
    dirX: data.get(#dirX, or: $value.dirX),
    dirY: data.get(#dirY, or: $value.dirY),
  );

  @override
  BarrelDtoCopyWith<$R2, BarrelDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _BarrelDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class PortalDtoMapper extends ClassMapperBase<PortalDto> {
  PortalDtoMapper._();

  static PortalDtoMapper? _instance;
  static PortalDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = PortalDtoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'PortalDto';

  static int _$x(PortalDto v) => v.x;
  static const Field<PortalDto, int> _f$x = Field('x', _$x);
  static int _$y(PortalDto v) => v.y;
  static const Field<PortalDto, int> _f$y = Field('y', _$y);
  static int _$index(PortalDto v) => v.index;
  static const Field<PortalDto, int> _f$index = Field('index', _$index);
  static bool _$active(PortalDto v) => v.active;
  static const Field<PortalDto, bool> _f$active = Field('active', _$active);

  @override
  final MappableFields<PortalDto> fields = const {
    #x: _f$x,
    #y: _f$y,
    #index: _f$index,
    #active: _f$active,
  };

  static PortalDto _instantiate(DecodingData data) {
    return PortalDto(
      x: data.dec(_f$x),
      y: data.dec(_f$y),
      index: data.dec(_f$index),
      active: data.dec(_f$active),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static PortalDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<PortalDto>(map);
  }

  static PortalDto fromJson(String json) {
    return ensureInitialized().decodeJson<PortalDto>(json);
  }
}

mixin PortalDtoMappable {
  String toJson() {
    return PortalDtoMapper.ensureInitialized().encodeJson<PortalDto>(
      this as PortalDto,
    );
  }

  Map<String, dynamic> toMap() {
    return PortalDtoMapper.ensureInitialized().encodeMap<PortalDto>(
      this as PortalDto,
    );
  }

  PortalDtoCopyWith<PortalDto, PortalDto, PortalDto> get copyWith =>
      _PortalDtoCopyWithImpl<PortalDto, PortalDto>(
        this as PortalDto,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return PortalDtoMapper.ensureInitialized().stringifyValue(
      this as PortalDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return PortalDtoMapper.ensureInitialized().equalsValue(
      this as PortalDto,
      other,
    );
  }

  @override
  int get hashCode {
    return PortalDtoMapper.ensureInitialized().hashValue(this as PortalDto);
  }
}

extension PortalDtoValueCopy<$R, $Out> on ObjectCopyWith<$R, PortalDto, $Out> {
  PortalDtoCopyWith<$R, PortalDto, $Out> get $asPortalDto =>
      $base.as((v, t, t2) => _PortalDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class PortalDtoCopyWith<$R, $In extends PortalDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? x, int? y, int? index, bool? active});
  PortalDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _PortalDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, PortalDto, $Out>
    implements PortalDtoCopyWith<$R, PortalDto, $Out> {
  _PortalDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<PortalDto> $mapper =
      PortalDtoMapper.ensureInitialized();
  @override
  $R call({int? x, int? y, int? index, bool? active}) => $apply(
    FieldCopyWithData({
      if (x != null) #x: x,
      if (y != null) #y: y,
      if (index != null) #index: index,
      if (active != null) #active: active,
    }),
  );
  @override
  PortalDto $make(CopyWithData data) => PortalDto(
    x: data.get(#x, or: $value.x),
    y: data.get(#y, or: $value.y),
    index: data.get(#index, or: $value.index),
    active: data.get(#active, or: $value.active),
  );

  @override
  PortalDtoCopyWith<$R2, PortalDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _PortalDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class MagicCrystalDtoMapper extends ClassMapperBase<MagicCrystalDto> {
  MagicCrystalDtoMapper._();

  static MagicCrystalDtoMapper? _instance;
  static MagicCrystalDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = MagicCrystalDtoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'MagicCrystalDto';

  static int _$id(MagicCrystalDto v) => v.id;
  static const Field<MagicCrystalDto, int> _f$id = Field('id', _$id);
  static int _$x(MagicCrystalDto v) => v.x;
  static const Field<MagicCrystalDto, int> _f$x = Field('x', _$x);
  static int _$y(MagicCrystalDto v) => v.y;
  static const Field<MagicCrystalDto, int> _f$y = Field('y', _$y);
  static bool _$fallen(MagicCrystalDto v) => v.fallen;
  static const Field<MagicCrystalDto, bool> _f$fallen = Field(
    'fallen',
    _$fallen,
  );
  static double _$burstProgress(MagicCrystalDto v) => v.burstProgress;
  static const Field<MagicCrystalDto, double> _f$burstProgress = Field(
    'burstProgress',
    _$burstProgress,
    opt: true,
    def: 1,
  );

  @override
  final MappableFields<MagicCrystalDto> fields = const {
    #id: _f$id,
    #x: _f$x,
    #y: _f$y,
    #fallen: _f$fallen,
    #burstProgress: _f$burstProgress,
  };

  static MagicCrystalDto _instantiate(DecodingData data) {
    return MagicCrystalDto(
      id: data.dec(_f$id),
      x: data.dec(_f$x),
      y: data.dec(_f$y),
      fallen: data.dec(_f$fallen),
      burstProgress: data.dec(_f$burstProgress),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static MagicCrystalDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<MagicCrystalDto>(map);
  }

  static MagicCrystalDto fromJson(String json) {
    return ensureInitialized().decodeJson<MagicCrystalDto>(json);
  }
}

mixin MagicCrystalDtoMappable {
  String toJson() {
    return MagicCrystalDtoMapper.ensureInitialized()
        .encodeJson<MagicCrystalDto>(this as MagicCrystalDto);
  }

  Map<String, dynamic> toMap() {
    return MagicCrystalDtoMapper.ensureInitialized().encodeMap<MagicCrystalDto>(
      this as MagicCrystalDto,
    );
  }

  MagicCrystalDtoCopyWith<MagicCrystalDto, MagicCrystalDto, MagicCrystalDto>
  get copyWith =>
      _MagicCrystalDtoCopyWithImpl<MagicCrystalDto, MagicCrystalDto>(
        this as MagicCrystalDto,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return MagicCrystalDtoMapper.ensureInitialized().stringifyValue(
      this as MagicCrystalDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return MagicCrystalDtoMapper.ensureInitialized().equalsValue(
      this as MagicCrystalDto,
      other,
    );
  }

  @override
  int get hashCode {
    return MagicCrystalDtoMapper.ensureInitialized().hashValue(
      this as MagicCrystalDto,
    );
  }
}

extension MagicCrystalDtoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, MagicCrystalDto, $Out> {
  MagicCrystalDtoCopyWith<$R, MagicCrystalDto, $Out> get $asMagicCrystalDto =>
      $base.as((v, t, t2) => _MagicCrystalDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class MagicCrystalDtoCopyWith<$R, $In extends MagicCrystalDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? id, int? x, int? y, bool? fallen, double? burstProgress});
  MagicCrystalDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _MagicCrystalDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, MagicCrystalDto, $Out>
    implements MagicCrystalDtoCopyWith<$R, MagicCrystalDto, $Out> {
  _MagicCrystalDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<MagicCrystalDto> $mapper =
      MagicCrystalDtoMapper.ensureInitialized();
  @override
  $R call({int? id, int? x, int? y, bool? fallen, double? burstProgress}) =>
      $apply(
        FieldCopyWithData({
          if (id != null) #id: id,
          if (x != null) #x: x,
          if (y != null) #y: y,
          if (fallen != null) #fallen: fallen,
          if (burstProgress != null) #burstProgress: burstProgress,
        }),
      );
  @override
  MagicCrystalDto $make(CopyWithData data) => MagicCrystalDto(
    id: data.get(#id, or: $value.id),
    x: data.get(#x, or: $value.x),
    y: data.get(#y, or: $value.y),
    fallen: data.get(#fallen, or: $value.fallen),
    burstProgress: data.get(#burstProgress, or: $value.burstProgress),
  );

  @override
  MagicCrystalDtoCopyWith<$R2, MagicCrystalDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _MagicCrystalDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class MagicChainDtoMapper extends ClassMapperBase<MagicChainDto> {
  MagicChainDtoMapper._();

  static MagicChainDtoMapper? _instance;
  static MagicChainDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = MagicChainDtoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'MagicChainDto';

  static int _$id(MagicChainDto v) => v.id;
  static const Field<MagicChainDto, int> _f$id = Field('id', _$id);
  static List<List<int>> _$contours(MagicChainDto v) => v.contours;
  static const Field<MagicChainDto, List<List<int>>> _f$contours = Field(
    'contours',
    _$contours,
  );

  @override
  final MappableFields<MagicChainDto> fields = const {
    #id: _f$id,
    #contours: _f$contours,
  };

  static MagicChainDto _instantiate(DecodingData data) {
    return MagicChainDto(id: data.dec(_f$id), contours: data.dec(_f$contours));
  }

  @override
  final Function instantiate = _instantiate;

  static MagicChainDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<MagicChainDto>(map);
  }

  static MagicChainDto fromJson(String json) {
    return ensureInitialized().decodeJson<MagicChainDto>(json);
  }
}

mixin MagicChainDtoMappable {
  String toJson() {
    return MagicChainDtoMapper.ensureInitialized().encodeJson<MagicChainDto>(
      this as MagicChainDto,
    );
  }

  Map<String, dynamic> toMap() {
    return MagicChainDtoMapper.ensureInitialized().encodeMap<MagicChainDto>(
      this as MagicChainDto,
    );
  }

  MagicChainDtoCopyWith<MagicChainDto, MagicChainDto, MagicChainDto>
  get copyWith => _MagicChainDtoCopyWithImpl<MagicChainDto, MagicChainDto>(
    this as MagicChainDto,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return MagicChainDtoMapper.ensureInitialized().stringifyValue(
      this as MagicChainDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return MagicChainDtoMapper.ensureInitialized().equalsValue(
      this as MagicChainDto,
      other,
    );
  }

  @override
  int get hashCode {
    return MagicChainDtoMapper.ensureInitialized().hashValue(
      this as MagicChainDto,
    );
  }
}

extension MagicChainDtoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, MagicChainDto, $Out> {
  MagicChainDtoCopyWith<$R, MagicChainDto, $Out> get $asMagicChainDto =>
      $base.as((v, t, t2) => _MagicChainDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class MagicChainDtoCopyWith<$R, $In extends MagicChainDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, List<int>, ObjectCopyWith<$R, List<int>, List<int>>>
  get contours;
  $R call({int? id, List<List<int>>? contours});
  MagicChainDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _MagicChainDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, MagicChainDto, $Out>
    implements MagicChainDtoCopyWith<$R, MagicChainDto, $Out> {
  _MagicChainDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<MagicChainDto> $mapper =
      MagicChainDtoMapper.ensureInitialized();
  @override
  ListCopyWith<$R, List<int>, ObjectCopyWith<$R, List<int>, List<int>>>
  get contours => ListCopyWith(
    $value.contours,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(contours: v),
  );
  @override
  $R call({int? id, List<List<int>>? contours}) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (contours != null) #contours: contours,
    }),
  );
  @override
  MagicChainDto $make(CopyWithData data) => MagicChainDto(
    id: data.get(#id, or: $value.id),
    contours: data.get(#contours, or: $value.contours),
  );

  @override
  MagicChainDtoCopyWith<$R2, MagicChainDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _MagicChainDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class IllusionDtoMapper extends ClassMapperBase<IllusionDto> {
  IllusionDtoMapper._();

  static IllusionDtoMapper? _instance;
  static IllusionDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = IllusionDtoMapper._());
      LehaAspectMapper.ensureInitialized();
      HunterKindMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'IllusionDto';

  static double _$x(IllusionDto v) => v.x;
  static const Field<IllusionDto, double> _f$x = Field('x', _$x);
  static double _$y(IllusionDto v) => v.y;
  static const Field<IllusionDto, double> _f$y = Field('y', _$y);
  static int? _$slot(IllusionDto v) => v.slot;
  static const Field<IllusionDto, int> _f$slot = Field('slot', _$slot);
  static double _$opacity(IllusionDto v) => v.opacity;
  static const Field<IllusionDto, double> _f$opacity = Field(
    'opacity',
    _$opacity,
  );
  static LehaAspect? _$aspect(IllusionDto v) => v.aspect;
  static const Field<IllusionDto, LehaAspect> _f$aspect = Field(
    'aspect',
    _$aspect,
    opt: true,
  );
  static HunterKind? _$hunterKind(IllusionDto v) => v.hunterKind;
  static const Field<IllusionDto, HunterKind> _f$hunterKind = Field(
    'hunterKind',
    _$hunterKind,
    opt: true,
  );
  static bool _$powered(IllusionDto v) => v.powered;
  static const Field<IllusionDto, bool> _f$powered = Field(
    'powered',
    _$powered,
    opt: true,
    def: false,
  );
  static bool _$femboy(IllusionDto v) => v.femboy;
  static const Field<IllusionDto, bool> _f$femboy = Field(
    'femboy',
    _$femboy,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<IllusionDto> fields = const {
    #x: _f$x,
    #y: _f$y,
    #slot: _f$slot,
    #opacity: _f$opacity,
    #aspect: _f$aspect,
    #hunterKind: _f$hunterKind,
    #powered: _f$powered,
    #femboy: _f$femboy,
  };

  static IllusionDto _instantiate(DecodingData data) {
    return IllusionDto(
      x: data.dec(_f$x),
      y: data.dec(_f$y),
      slot: data.dec(_f$slot),
      opacity: data.dec(_f$opacity),
      aspect: data.dec(_f$aspect),
      hunterKind: data.dec(_f$hunterKind),
      powered: data.dec(_f$powered),
      femboy: data.dec(_f$femboy),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static IllusionDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<IllusionDto>(map);
  }

  static IllusionDto fromJson(String json) {
    return ensureInitialized().decodeJson<IllusionDto>(json);
  }
}

mixin IllusionDtoMappable {
  String toJson() {
    return IllusionDtoMapper.ensureInitialized().encodeJson<IllusionDto>(
      this as IllusionDto,
    );
  }

  Map<String, dynamic> toMap() {
    return IllusionDtoMapper.ensureInitialized().encodeMap<IllusionDto>(
      this as IllusionDto,
    );
  }

  IllusionDtoCopyWith<IllusionDto, IllusionDto, IllusionDto> get copyWith =>
      _IllusionDtoCopyWithImpl<IllusionDto, IllusionDto>(
        this as IllusionDto,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return IllusionDtoMapper.ensureInitialized().stringifyValue(
      this as IllusionDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return IllusionDtoMapper.ensureInitialized().equalsValue(
      this as IllusionDto,
      other,
    );
  }

  @override
  int get hashCode {
    return IllusionDtoMapper.ensureInitialized().hashValue(this as IllusionDto);
  }
}

extension IllusionDtoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, IllusionDto, $Out> {
  IllusionDtoCopyWith<$R, IllusionDto, $Out> get $asIllusionDto =>
      $base.as((v, t, t2) => _IllusionDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class IllusionDtoCopyWith<$R, $In extends IllusionDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    double? x,
    double? y,
    int? slot,
    double? opacity,
    LehaAspect? aspect,
    HunterKind? hunterKind,
    bool? powered,
    bool? femboy,
  });
  IllusionDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _IllusionDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, IllusionDto, $Out>
    implements IllusionDtoCopyWith<$R, IllusionDto, $Out> {
  _IllusionDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<IllusionDto> $mapper =
      IllusionDtoMapper.ensureInitialized();
  @override
  $R call({
    double? x,
    double? y,
    Object? slot = $none,
    double? opacity,
    Object? aspect = $none,
    Object? hunterKind = $none,
    bool? powered,
    bool? femboy,
  }) => $apply(
    FieldCopyWithData({
      if (x != null) #x: x,
      if (y != null) #y: y,
      if (slot != $none) #slot: slot,
      if (opacity != null) #opacity: opacity,
      if (aspect != $none) #aspect: aspect,
      if (hunterKind != $none) #hunterKind: hunterKind,
      if (powered != null) #powered: powered,
      if (femboy != null) #femboy: femboy,
    }),
  );
  @override
  IllusionDto $make(CopyWithData data) => IllusionDto(
    x: data.get(#x, or: $value.x),
    y: data.get(#y, or: $value.y),
    slot: data.get(#slot, or: $value.slot),
    opacity: data.get(#opacity, or: $value.opacity),
    aspect: data.get(#aspect, or: $value.aspect),
    hunterKind: data.get(#hunterKind, or: $value.hunterKind),
    powered: data.get(#powered, or: $value.powered),
    femboy: data.get(#femboy, or: $value.femboy),
  );

  @override
  IllusionDtoCopyWith<$R2, IllusionDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _IllusionDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class SarcophagusDtoMapper extends ClassMapperBase<SarcophagusDto> {
  SarcophagusDtoMapper._();

  static SarcophagusDtoMapper? _instance;
  static SarcophagusDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SarcophagusDtoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'SarcophagusDto';

  static int _$x(SarcophagusDto v) => v.x;
  static const Field<SarcophagusDto, int> _f$x = Field('x', _$x);
  static int _$y(SarcophagusDto v) => v.y;
  static const Field<SarcophagusDto, int> _f$y = Field('y', _$y);
  static bool _$cracked(SarcophagusDto v) => v.cracked;
  static const Field<SarcophagusDto, bool> _f$cracked = Field(
    'cracked',
    _$cracked,
  );
  static bool _$hasMummy(SarcophagusDto v) => v.hasMummy;
  static const Field<SarcophagusDto, bool> _f$hasMummy = Field(
    'hasMummy',
    _$hasMummy,
  );

  @override
  final MappableFields<SarcophagusDto> fields = const {
    #x: _f$x,
    #y: _f$y,
    #cracked: _f$cracked,
    #hasMummy: _f$hasMummy,
  };

  static SarcophagusDto _instantiate(DecodingData data) {
    return SarcophagusDto(
      x: data.dec(_f$x),
      y: data.dec(_f$y),
      cracked: data.dec(_f$cracked),
      hasMummy: data.dec(_f$hasMummy),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static SarcophagusDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<SarcophagusDto>(map);
  }

  static SarcophagusDto fromJson(String json) {
    return ensureInitialized().decodeJson<SarcophagusDto>(json);
  }
}

mixin SarcophagusDtoMappable {
  String toJson() {
    return SarcophagusDtoMapper.ensureInitialized().encodeJson<SarcophagusDto>(
      this as SarcophagusDto,
    );
  }

  Map<String, dynamic> toMap() {
    return SarcophagusDtoMapper.ensureInitialized().encodeMap<SarcophagusDto>(
      this as SarcophagusDto,
    );
  }

  SarcophagusDtoCopyWith<SarcophagusDto, SarcophagusDto, SarcophagusDto>
  get copyWith => _SarcophagusDtoCopyWithImpl<SarcophagusDto, SarcophagusDto>(
    this as SarcophagusDto,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return SarcophagusDtoMapper.ensureInitialized().stringifyValue(
      this as SarcophagusDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return SarcophagusDtoMapper.ensureInitialized().equalsValue(
      this as SarcophagusDto,
      other,
    );
  }

  @override
  int get hashCode {
    return SarcophagusDtoMapper.ensureInitialized().hashValue(
      this as SarcophagusDto,
    );
  }
}

extension SarcophagusDtoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, SarcophagusDto, $Out> {
  SarcophagusDtoCopyWith<$R, SarcophagusDto, $Out> get $asSarcophagusDto =>
      $base.as((v, t, t2) => _SarcophagusDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class SarcophagusDtoCopyWith<$R, $In extends SarcophagusDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? x, int? y, bool? cracked, bool? hasMummy});
  SarcophagusDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _SarcophagusDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, SarcophagusDto, $Out>
    implements SarcophagusDtoCopyWith<$R, SarcophagusDto, $Out> {
  _SarcophagusDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<SarcophagusDto> $mapper =
      SarcophagusDtoMapper.ensureInitialized();
  @override
  $R call({int? x, int? y, bool? cracked, bool? hasMummy}) => $apply(
    FieldCopyWithData({
      if (x != null) #x: x,
      if (y != null) #y: y,
      if (cracked != null) #cracked: cracked,
      if (hasMummy != null) #hasMummy: hasMummy,
    }),
  );
  @override
  SarcophagusDto $make(CopyWithData data) => SarcophagusDto(
    x: data.get(#x, or: $value.x),
    y: data.get(#y, or: $value.y),
    cracked: data.get(#cracked, or: $value.cracked),
    hasMummy: data.get(#hasMummy, or: $value.hasMummy),
  );

  @override
  SarcophagusDtoCopyWith<$R2, SarcophagusDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _SarcophagusDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class MummyDtoMapper extends ClassMapperBase<MummyDto> {
  MummyDtoMapper._();

  static MummyDtoMapper? _instance;
  static MummyDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = MummyDtoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'MummyDto';

  static double _$x(MummyDto v) => v.x;
  static const Field<MummyDto, double> _f$x = Field('x', _$x);
  static double _$y(MummyDto v) => v.y;
  static const Field<MummyDto, double> _f$y = Field('y', _$y);
  static bool _$fleeing(MummyDto v) => v.fleeing;
  static const Field<MummyDto, bool> _f$fleeing = Field('fleeing', _$fleeing);

  @override
  final MappableFields<MummyDto> fields = const {
    #x: _f$x,
    #y: _f$y,
    #fleeing: _f$fleeing,
  };

  static MummyDto _instantiate(DecodingData data) {
    return MummyDto(
      x: data.dec(_f$x),
      y: data.dec(_f$y),
      fleeing: data.dec(_f$fleeing),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static MummyDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<MummyDto>(map);
  }

  static MummyDto fromJson(String json) {
    return ensureInitialized().decodeJson<MummyDto>(json);
  }
}

mixin MummyDtoMappable {
  String toJson() {
    return MummyDtoMapper.ensureInitialized().encodeJson<MummyDto>(
      this as MummyDto,
    );
  }

  Map<String, dynamic> toMap() {
    return MummyDtoMapper.ensureInitialized().encodeMap<MummyDto>(
      this as MummyDto,
    );
  }

  MummyDtoCopyWith<MummyDto, MummyDto, MummyDto> get copyWith =>
      _MummyDtoCopyWithImpl<MummyDto, MummyDto>(
        this as MummyDto,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return MummyDtoMapper.ensureInitialized().stringifyValue(this as MummyDto);
  }

  @override
  bool operator ==(Object other) {
    return MummyDtoMapper.ensureInitialized().equalsValue(
      this as MummyDto,
      other,
    );
  }

  @override
  int get hashCode {
    return MummyDtoMapper.ensureInitialized().hashValue(this as MummyDto);
  }
}

extension MummyDtoValueCopy<$R, $Out> on ObjectCopyWith<$R, MummyDto, $Out> {
  MummyDtoCopyWith<$R, MummyDto, $Out> get $asMummyDto =>
      $base.as((v, t, t2) => _MummyDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class MummyDtoCopyWith<$R, $In extends MummyDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({double? x, double? y, bool? fleeing});
  MummyDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _MummyDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, MummyDto, $Out>
    implements MummyDtoCopyWith<$R, MummyDto, $Out> {
  _MummyDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<MummyDto> $mapper =
      MummyDtoMapper.ensureInitialized();
  @override
  $R call({double? x, double? y, bool? fleeing}) => $apply(
    FieldCopyWithData({
      if (x != null) #x: x,
      if (y != null) #y: y,
      if (fleeing != null) #fleeing: fleeing,
    }),
  );
  @override
  MummyDto $make(CopyWithData data) => MummyDto(
    x: data.get(#x, or: $value.x),
    y: data.get(#y, or: $value.y),
    fleeing: data.get(#fleeing, or: $value.fleeing),
  );

  @override
  MummyDtoCopyWith<$R2, MummyDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _MummyDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ChimeDtoMapper extends ClassMapperBase<ChimeDto> {
  ChimeDtoMapper._();

  static ChimeDtoMapper? _instance;
  static ChimeDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ChimeDtoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ChimeDto';

  static double _$x(ChimeDto v) => v.x;
  static const Field<ChimeDto, double> _f$x = Field('x', _$x);
  static double _$y(ChimeDto v) => v.y;
  static const Field<ChimeDto, double> _f$y = Field('y', _$y);
  static double _$progress(ChimeDto v) => v.progress;
  static const Field<ChimeDto, double> _f$progress = Field(
    'progress',
    _$progress,
  );

  @override
  final MappableFields<ChimeDto> fields = const {
    #x: _f$x,
    #y: _f$y,
    #progress: _f$progress,
  };

  static ChimeDto _instantiate(DecodingData data) {
    return ChimeDto(
      x: data.dec(_f$x),
      y: data.dec(_f$y),
      progress: data.dec(_f$progress),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ChimeDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ChimeDto>(map);
  }

  static ChimeDto fromJson(String json) {
    return ensureInitialized().decodeJson<ChimeDto>(json);
  }
}

mixin ChimeDtoMappable {
  String toJson() {
    return ChimeDtoMapper.ensureInitialized().encodeJson<ChimeDto>(
      this as ChimeDto,
    );
  }

  Map<String, dynamic> toMap() {
    return ChimeDtoMapper.ensureInitialized().encodeMap<ChimeDto>(
      this as ChimeDto,
    );
  }

  ChimeDtoCopyWith<ChimeDto, ChimeDto, ChimeDto> get copyWith =>
      _ChimeDtoCopyWithImpl<ChimeDto, ChimeDto>(
        this as ChimeDto,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ChimeDtoMapper.ensureInitialized().stringifyValue(this as ChimeDto);
  }

  @override
  bool operator ==(Object other) {
    return ChimeDtoMapper.ensureInitialized().equalsValue(
      this as ChimeDto,
      other,
    );
  }

  @override
  int get hashCode {
    return ChimeDtoMapper.ensureInitialized().hashValue(this as ChimeDto);
  }
}

extension ChimeDtoValueCopy<$R, $Out> on ObjectCopyWith<$R, ChimeDto, $Out> {
  ChimeDtoCopyWith<$R, ChimeDto, $Out> get $asChimeDto =>
      $base.as((v, t, t2) => _ChimeDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ChimeDtoCopyWith<$R, $In extends ChimeDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({double? x, double? y, double? progress});
  ChimeDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ChimeDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ChimeDto, $Out>
    implements ChimeDtoCopyWith<$R, ChimeDto, $Out> {
  _ChimeDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ChimeDto> $mapper =
      ChimeDtoMapper.ensureInitialized();
  @override
  $R call({double? x, double? y, double? progress}) => $apply(
    FieldCopyWithData({
      if (x != null) #x: x,
      if (y != null) #y: y,
      if (progress != null) #progress: progress,
    }),
  );
  @override
  ChimeDto $make(CopyWithData data) => ChimeDto(
    x: data.get(#x, or: $value.x),
    y: data.get(#y, or: $value.y),
    progress: data.get(#progress, or: $value.progress),
  );

  @override
  ChimeDtoCopyWith<$R2, ChimeDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ChimeDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class MushroomDtoMapper extends ClassMapperBase<MushroomDto> {
  MushroomDtoMapper._();

  static MushroomDtoMapper? _instance;
  static MushroomDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = MushroomDtoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'MushroomDto';

  static int _$x(MushroomDto v) => v.x;
  static const Field<MushroomDto, int> _f$x = Field('x', _$x);
  static int _$y(MushroomDto v) => v.y;
  static const Field<MushroomDto, int> _f$y = Field('y', _$y);
  static int _$stage(MushroomDto v) => v.stage;
  static const Field<MushroomDto, int> _f$stage = Field('stage', _$stage);

  @override
  final MappableFields<MushroomDto> fields = const {
    #x: _f$x,
    #y: _f$y,
    #stage: _f$stage,
  };

  static MushroomDto _instantiate(DecodingData data) {
    return MushroomDto(
      x: data.dec(_f$x),
      y: data.dec(_f$y),
      stage: data.dec(_f$stage),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static MushroomDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<MushroomDto>(map);
  }

  static MushroomDto fromJson(String json) {
    return ensureInitialized().decodeJson<MushroomDto>(json);
  }
}

mixin MushroomDtoMappable {
  String toJson() {
    return MushroomDtoMapper.ensureInitialized().encodeJson<MushroomDto>(
      this as MushroomDto,
    );
  }

  Map<String, dynamic> toMap() {
    return MushroomDtoMapper.ensureInitialized().encodeMap<MushroomDto>(
      this as MushroomDto,
    );
  }

  MushroomDtoCopyWith<MushroomDto, MushroomDto, MushroomDto> get copyWith =>
      _MushroomDtoCopyWithImpl<MushroomDto, MushroomDto>(
        this as MushroomDto,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return MushroomDtoMapper.ensureInitialized().stringifyValue(
      this as MushroomDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return MushroomDtoMapper.ensureInitialized().equalsValue(
      this as MushroomDto,
      other,
    );
  }

  @override
  int get hashCode {
    return MushroomDtoMapper.ensureInitialized().hashValue(this as MushroomDto);
  }
}

extension MushroomDtoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, MushroomDto, $Out> {
  MushroomDtoCopyWith<$R, MushroomDto, $Out> get $asMushroomDto =>
      $base.as((v, t, t2) => _MushroomDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class MushroomDtoCopyWith<$R, $In extends MushroomDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? x, int? y, int? stage});
  MushroomDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _MushroomDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, MushroomDto, $Out>
    implements MushroomDtoCopyWith<$R, MushroomDto, $Out> {
  _MushroomDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<MushroomDto> $mapper =
      MushroomDtoMapper.ensureInitialized();
  @override
  $R call({int? x, int? y, int? stage}) => $apply(
    FieldCopyWithData({
      if (x != null) #x: x,
      if (y != null) #y: y,
      if (stage != null) #stage: stage,
    }),
  );
  @override
  MushroomDto $make(CopyWithData data) => MushroomDto(
    x: data.get(#x, or: $value.x),
    y: data.get(#y, or: $value.y),
    stage: data.get(#stage, or: $value.stage),
  );

  @override
  MushroomDtoCopyWith<$R2, MushroomDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _MushroomDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ClutchDtoMapper extends ClassMapperBase<ClutchDto> {
  ClutchDtoMapper._();

  static ClutchDtoMapper? _instance;
  static ClutchDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ClutchDtoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'ClutchDto';

  static int _$x(ClutchDto v) => v.x;
  static const Field<ClutchDto, int> _f$x = Field('x', _$x);
  static int _$y(ClutchDto v) => v.y;
  static const Field<ClutchDto, int> _f$y = Field('y', _$y);
  static int _$hatchMs(ClutchDto v) => v.hatchMs;
  static const Field<ClutchDto, int> _f$hatchMs = Field('hatchMs', _$hatchMs);

  @override
  final MappableFields<ClutchDto> fields = const {
    #x: _f$x,
    #y: _f$y,
    #hatchMs: _f$hatchMs,
  };

  static ClutchDto _instantiate(DecodingData data) {
    return ClutchDto(
      x: data.dec(_f$x),
      y: data.dec(_f$y),
      hatchMs: data.dec(_f$hatchMs),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ClutchDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ClutchDto>(map);
  }

  static ClutchDto fromJson(String json) {
    return ensureInitialized().decodeJson<ClutchDto>(json);
  }
}

mixin ClutchDtoMappable {
  String toJson() {
    return ClutchDtoMapper.ensureInitialized().encodeJson<ClutchDto>(
      this as ClutchDto,
    );
  }

  Map<String, dynamic> toMap() {
    return ClutchDtoMapper.ensureInitialized().encodeMap<ClutchDto>(
      this as ClutchDto,
    );
  }

  ClutchDtoCopyWith<ClutchDto, ClutchDto, ClutchDto> get copyWith =>
      _ClutchDtoCopyWithImpl<ClutchDto, ClutchDto>(
        this as ClutchDto,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ClutchDtoMapper.ensureInitialized().stringifyValue(
      this as ClutchDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return ClutchDtoMapper.ensureInitialized().equalsValue(
      this as ClutchDto,
      other,
    );
  }

  @override
  int get hashCode {
    return ClutchDtoMapper.ensureInitialized().hashValue(this as ClutchDto);
  }
}

extension ClutchDtoValueCopy<$R, $Out> on ObjectCopyWith<$R, ClutchDto, $Out> {
  ClutchDtoCopyWith<$R, ClutchDto, $Out> get $asClutchDto =>
      $base.as((v, t, t2) => _ClutchDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ClutchDtoCopyWith<$R, $In extends ClutchDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({int? x, int? y, int? hatchMs});
  ClutchDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ClutchDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ClutchDto, $Out>
    implements ClutchDtoCopyWith<$R, ClutchDto, $Out> {
  _ClutchDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ClutchDto> $mapper =
      ClutchDtoMapper.ensureInitialized();
  @override
  $R call({int? x, int? y, int? hatchMs}) => $apply(
    FieldCopyWithData({
      if (x != null) #x: x,
      if (y != null) #y: y,
      if (hatchMs != null) #hatchMs: hatchMs,
    }),
  );
  @override
  ClutchDto $make(CopyWithData data) => ClutchDto(
    x: data.get(#x, or: $value.x),
    y: data.get(#y, or: $value.y),
    hatchMs: data.get(#hatchMs, or: $value.hatchMs),
  );

  @override
  ClutchDtoCopyWith<$R2, ClutchDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ClutchDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class TrailPointDtoMapper extends ClassMapperBase<TrailPointDto> {
  TrailPointDtoMapper._();

  static TrailPointDtoMapper? _instance;
  static TrailPointDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TrailPointDtoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'TrailPointDto';

  static double _$x(TrailPointDto v) => v.x;
  static const Field<TrailPointDto, double> _f$x = Field('x', _$x);
  static double _$y(TrailPointDto v) => v.y;
  static const Field<TrailPointDto, double> _f$y = Field('y', _$y);
  static double _$alpha(TrailPointDto v) => v.alpha;
  static const Field<TrailPointDto, double> _f$alpha = Field('alpha', _$alpha);

  @override
  final MappableFields<TrailPointDto> fields = const {
    #x: _f$x,
    #y: _f$y,
    #alpha: _f$alpha,
  };

  static TrailPointDto _instantiate(DecodingData data) {
    return TrailPointDto(
      x: data.dec(_f$x),
      y: data.dec(_f$y),
      alpha: data.dec(_f$alpha),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static TrailPointDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<TrailPointDto>(map);
  }

  static TrailPointDto fromJson(String json) {
    return ensureInitialized().decodeJson<TrailPointDto>(json);
  }
}

mixin TrailPointDtoMappable {
  String toJson() {
    return TrailPointDtoMapper.ensureInitialized().encodeJson<TrailPointDto>(
      this as TrailPointDto,
    );
  }

  Map<String, dynamic> toMap() {
    return TrailPointDtoMapper.ensureInitialized().encodeMap<TrailPointDto>(
      this as TrailPointDto,
    );
  }

  TrailPointDtoCopyWith<TrailPointDto, TrailPointDto, TrailPointDto>
  get copyWith => _TrailPointDtoCopyWithImpl<TrailPointDto, TrailPointDto>(
    this as TrailPointDto,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return TrailPointDtoMapper.ensureInitialized().stringifyValue(
      this as TrailPointDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return TrailPointDtoMapper.ensureInitialized().equalsValue(
      this as TrailPointDto,
      other,
    );
  }

  @override
  int get hashCode {
    return TrailPointDtoMapper.ensureInitialized().hashValue(
      this as TrailPointDto,
    );
  }
}

extension TrailPointDtoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, TrailPointDto, $Out> {
  TrailPointDtoCopyWith<$R, TrailPointDto, $Out> get $asTrailPointDto =>
      $base.as((v, t, t2) => _TrailPointDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class TrailPointDtoCopyWith<$R, $In extends TrailPointDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({double? x, double? y, double? alpha});
  TrailPointDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _TrailPointDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, TrailPointDto, $Out>
    implements TrailPointDtoCopyWith<$R, TrailPointDto, $Out> {
  _TrailPointDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<TrailPointDto> $mapper =
      TrailPointDtoMapper.ensureInitialized();
  @override
  $R call({double? x, double? y, double? alpha}) => $apply(
    FieldCopyWithData({
      if (x != null) #x: x,
      if (y != null) #y: y,
      if (alpha != null) #alpha: alpha,
    }),
  );
  @override
  TrailPointDto $make(CopyWithData data) => TrailPointDto(
    x: data.get(#x, or: $value.x),
    y: data.get(#y, or: $value.y),
    alpha: data.get(#alpha, or: $value.alpha),
  );

  @override
  TrailPointDtoCopyWith<$R2, TrailPointDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _TrailPointDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class ScoreDtoMapper extends ClassMapperBase<ScoreDto> {
  ScoreDtoMapper._();

  static ScoreDtoMapper? _instance;
  static ScoreDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ScoreDtoMapper._());
      PlayerRoleMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ScoreDto';

  static String _$id(ScoreDto v) => v.id;
  static const Field<ScoreDto, String> _f$id = Field('id', _$id);
  static int? _$slot(ScoreDto v) => v.slot;
  static const Field<ScoreDto, int> _f$slot = Field('slot', _$slot);
  static PlayerRole? _$role(ScoreDto v) => v.role;
  static const Field<ScoreDto, PlayerRole> _f$role = Field('role', _$role);
  static int _$score(ScoreDto v) => v.score;
  static const Field<ScoreDto, int> _f$score = Field('score', _$score);

  @override
  final MappableFields<ScoreDto> fields = const {
    #id: _f$id,
    #slot: _f$slot,
    #role: _f$role,
    #score: _f$score,
  };

  static ScoreDto _instantiate(DecodingData data) {
    return ScoreDto(
      id: data.dec(_f$id),
      slot: data.dec(_f$slot),
      role: data.dec(_f$role),
      score: data.dec(_f$score),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ScoreDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ScoreDto>(map);
  }

  static ScoreDto fromJson(String json) {
    return ensureInitialized().decodeJson<ScoreDto>(json);
  }
}

mixin ScoreDtoMappable {
  String toJson() {
    return ScoreDtoMapper.ensureInitialized().encodeJson<ScoreDto>(
      this as ScoreDto,
    );
  }

  Map<String, dynamic> toMap() {
    return ScoreDtoMapper.ensureInitialized().encodeMap<ScoreDto>(
      this as ScoreDto,
    );
  }

  ScoreDtoCopyWith<ScoreDto, ScoreDto, ScoreDto> get copyWith =>
      _ScoreDtoCopyWithImpl<ScoreDto, ScoreDto>(
        this as ScoreDto,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return ScoreDtoMapper.ensureInitialized().stringifyValue(this as ScoreDto);
  }

  @override
  bool operator ==(Object other) {
    return ScoreDtoMapper.ensureInitialized().equalsValue(
      this as ScoreDto,
      other,
    );
  }

  @override
  int get hashCode {
    return ScoreDtoMapper.ensureInitialized().hashValue(this as ScoreDto);
  }
}

extension ScoreDtoValueCopy<$R, $Out> on ObjectCopyWith<$R, ScoreDto, $Out> {
  ScoreDtoCopyWith<$R, ScoreDto, $Out> get $asScoreDto =>
      $base.as((v, t, t2) => _ScoreDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ScoreDtoCopyWith<$R, $In extends ScoreDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? id, int? slot, PlayerRole? role, int? score});
  ScoreDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ScoreDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ScoreDto, $Out>
    implements ScoreDtoCopyWith<$R, ScoreDto, $Out> {
  _ScoreDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ScoreDto> $mapper =
      ScoreDtoMapper.ensureInitialized();
  @override
  $R call({
    String? id,
    Object? slot = $none,
    Object? role = $none,
    int? score,
  }) => $apply(
    FieldCopyWithData({
      if (id != null) #id: id,
      if (slot != $none) #slot: slot,
      if (role != $none) #role: role,
      if (score != null) #score: score,
    }),
  );
  @override
  ScoreDto $make(CopyWithData data) => ScoreDto(
    id: data.get(#id, or: $value.id),
    slot: data.get(#slot, or: $value.slot),
    role: data.get(#role, or: $value.role),
    score: data.get(#score, or: $value.score),
  );

  @override
  ScoreDtoCopyWith<$R2, ScoreDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ScoreDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class RoleStateDtoMapper extends ClassMapperBase<RoleStateDto> {
  RoleStateDtoMapper._();

  static RoleStateDtoMapper? _instance;
  static RoleStateDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = RoleStateDtoMapper._());
      PlayerRoleMapper.ensureInitialized();
      LehaAspectMapper.ensureInitialized();
      HunterKindMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'RoleStateDto';

  static PlayerRole _$role(RoleStateDto v) => v.role;
  static const Field<RoleStateDto, PlayerRole> _f$role = Field('role', _$role);
  static int _$slot(RoleStateDto v) => v.slot;
  static const Field<RoleStateDto, int> _f$slot = Field('slot', _$slot);
  static bool _$taken(RoleStateDto v) => v.taken;
  static const Field<RoleStateDto, bool> _f$taken = Field('taken', _$taken);
  static bool _$ready(RoleStateDto v) => v.ready;
  static const Field<RoleStateDto, bool> _f$ready = Field('ready', _$ready);
  static String? _$playerId(RoleStateDto v) => v.playerId;
  static const Field<RoleStateDto, String> _f$playerId = Field(
    'playerId',
    _$playerId,
  );
  static LehaAspect? _$aspect(RoleStateDto v) => v.aspect;
  static const Field<RoleStateDto, LehaAspect> _f$aspect = Field(
    'aspect',
    _$aspect,
  );
  static HunterKind? _$hunterKind(RoleStateDto v) => v.hunterKind;
  static const Field<RoleStateDto, HunterKind> _f$hunterKind = Field(
    'hunterKind',
    _$hunterKind,
    opt: true,
  );
  static bool _$bot(RoleStateDto v) => v.bot;
  static const Field<RoleStateDto, bool> _f$bot = Field(
    'bot',
    _$bot,
    opt: true,
    def: false,
  );
  static int? _$readyTimeoutMs(RoleStateDto v) => v.readyTimeoutMs;
  static const Field<RoleStateDto, int> _f$readyTimeoutMs = Field(
    'readyTimeoutMs',
    _$readyTimeoutMs,
    opt: true,
  );

  @override
  final MappableFields<RoleStateDto> fields = const {
    #role: _f$role,
    #slot: _f$slot,
    #taken: _f$taken,
    #ready: _f$ready,
    #playerId: _f$playerId,
    #aspect: _f$aspect,
    #hunterKind: _f$hunterKind,
    #bot: _f$bot,
    #readyTimeoutMs: _f$readyTimeoutMs,
  };

  static RoleStateDto _instantiate(DecodingData data) {
    return RoleStateDto(
      role: data.dec(_f$role),
      slot: data.dec(_f$slot),
      taken: data.dec(_f$taken),
      ready: data.dec(_f$ready),
      playerId: data.dec(_f$playerId),
      aspect: data.dec(_f$aspect),
      hunterKind: data.dec(_f$hunterKind),
      bot: data.dec(_f$bot),
      readyTimeoutMs: data.dec(_f$readyTimeoutMs),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static RoleStateDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<RoleStateDto>(map);
  }

  static RoleStateDto fromJson(String json) {
    return ensureInitialized().decodeJson<RoleStateDto>(json);
  }
}

mixin RoleStateDtoMappable {
  String toJson() {
    return RoleStateDtoMapper.ensureInitialized().encodeJson<RoleStateDto>(
      this as RoleStateDto,
    );
  }

  Map<String, dynamic> toMap() {
    return RoleStateDtoMapper.ensureInitialized().encodeMap<RoleStateDto>(
      this as RoleStateDto,
    );
  }

  RoleStateDtoCopyWith<RoleStateDto, RoleStateDto, RoleStateDto> get copyWith =>
      _RoleStateDtoCopyWithImpl<RoleStateDto, RoleStateDto>(
        this as RoleStateDto,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return RoleStateDtoMapper.ensureInitialized().stringifyValue(
      this as RoleStateDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return RoleStateDtoMapper.ensureInitialized().equalsValue(
      this as RoleStateDto,
      other,
    );
  }

  @override
  int get hashCode {
    return RoleStateDtoMapper.ensureInitialized().hashValue(
      this as RoleStateDto,
    );
  }
}

extension RoleStateDtoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, RoleStateDto, $Out> {
  RoleStateDtoCopyWith<$R, RoleStateDto, $Out> get $asRoleStateDto =>
      $base.as((v, t, t2) => _RoleStateDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class RoleStateDtoCopyWith<$R, $In extends RoleStateDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    PlayerRole? role,
    int? slot,
    bool? taken,
    bool? ready,
    String? playerId,
    LehaAspect? aspect,
    HunterKind? hunterKind,
    bool? bot,
    int? readyTimeoutMs,
  });
  RoleStateDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _RoleStateDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, RoleStateDto, $Out>
    implements RoleStateDtoCopyWith<$R, RoleStateDto, $Out> {
  _RoleStateDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<RoleStateDto> $mapper =
      RoleStateDtoMapper.ensureInitialized();
  @override
  $R call({
    PlayerRole? role,
    int? slot,
    bool? taken,
    bool? ready,
    Object? playerId = $none,
    Object? aspect = $none,
    Object? hunterKind = $none,
    bool? bot,
    Object? readyTimeoutMs = $none,
  }) => $apply(
    FieldCopyWithData({
      if (role != null) #role: role,
      if (slot != null) #slot: slot,
      if (taken != null) #taken: taken,
      if (ready != null) #ready: ready,
      if (playerId != $none) #playerId: playerId,
      if (aspect != $none) #aspect: aspect,
      if (hunterKind != $none) #hunterKind: hunterKind,
      if (bot != null) #bot: bot,
      if (readyTimeoutMs != $none) #readyTimeoutMs: readyTimeoutMs,
    }),
  );
  @override
  RoleStateDto $make(CopyWithData data) => RoleStateDto(
    role: data.get(#role, or: $value.role),
    slot: data.get(#slot, or: $value.slot),
    taken: data.get(#taken, or: $value.taken),
    ready: data.get(#ready, or: $value.ready),
    playerId: data.get(#playerId, or: $value.playerId),
    aspect: data.get(#aspect, or: $value.aspect),
    hunterKind: data.get(#hunterKind, or: $value.hunterKind),
    bot: data.get(#bot, or: $value.bot),
    readyTimeoutMs: data.get(#readyTimeoutMs, or: $value.readyTimeoutMs),
  );

  @override
  RoleStateDtoCopyWith<$R2, RoleStateDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _RoleStateDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class LobbyDtoMapper extends ClassMapperBase<LobbyDto> {
  LobbyDtoMapper._();

  static LobbyDtoMapper? _instance;
  static LobbyDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = LobbyDtoMapper._());
      RoleStateDtoMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'LobbyDto';

  static List<RoleStateDto> _$roles(LobbyDto v) => v.roles;
  static const Field<LobbyDto, List<RoleStateDto>> _f$roles = Field(
    'roles',
    _$roles,
  );
  static int _$spectators(LobbyDto v) => v.spectators;
  static const Field<LobbyDto, int> _f$spectators = Field(
    'spectators',
    _$spectators,
  );

  @override
  final MappableFields<LobbyDto> fields = const {
    #roles: _f$roles,
    #spectators: _f$spectators,
  };

  static LobbyDto _instantiate(DecodingData data) {
    return LobbyDto(
      roles: data.dec(_f$roles),
      spectators: data.dec(_f$spectators),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static LobbyDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<LobbyDto>(map);
  }

  static LobbyDto fromJson(String json) {
    return ensureInitialized().decodeJson<LobbyDto>(json);
  }
}

mixin LobbyDtoMappable {
  String toJson() {
    return LobbyDtoMapper.ensureInitialized().encodeJson<LobbyDto>(
      this as LobbyDto,
    );
  }

  Map<String, dynamic> toMap() {
    return LobbyDtoMapper.ensureInitialized().encodeMap<LobbyDto>(
      this as LobbyDto,
    );
  }

  LobbyDtoCopyWith<LobbyDto, LobbyDto, LobbyDto> get copyWith =>
      _LobbyDtoCopyWithImpl<LobbyDto, LobbyDto>(
        this as LobbyDto,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return LobbyDtoMapper.ensureInitialized().stringifyValue(this as LobbyDto);
  }

  @override
  bool operator ==(Object other) {
    return LobbyDtoMapper.ensureInitialized().equalsValue(
      this as LobbyDto,
      other,
    );
  }

  @override
  int get hashCode {
    return LobbyDtoMapper.ensureInitialized().hashValue(this as LobbyDto);
  }
}

extension LobbyDtoValueCopy<$R, $Out> on ObjectCopyWith<$R, LobbyDto, $Out> {
  LobbyDtoCopyWith<$R, LobbyDto, $Out> get $asLobbyDto =>
      $base.as((v, t, t2) => _LobbyDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class LobbyDtoCopyWith<$R, $In extends LobbyDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<
    $R,
    RoleStateDto,
    RoleStateDtoCopyWith<$R, RoleStateDto, RoleStateDto>
  >
  get roles;
  $R call({List<RoleStateDto>? roles, int? spectators});
  LobbyDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _LobbyDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, LobbyDto, $Out>
    implements LobbyDtoCopyWith<$R, LobbyDto, $Out> {
  _LobbyDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<LobbyDto> $mapper =
      LobbyDtoMapper.ensureInitialized();
  @override
  ListCopyWith<
    $R,
    RoleStateDto,
    RoleStateDtoCopyWith<$R, RoleStateDto, RoleStateDto>
  >
  get roles => ListCopyWith(
    $value.roles,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(roles: v),
  );
  @override
  $R call({List<RoleStateDto>? roles, int? spectators}) => $apply(
    FieldCopyWithData({
      if (roles != null) #roles: roles,
      if (spectators != null) #spectators: spectators,
    }),
  );
  @override
  LobbyDto $make(CopyWithData data) => LobbyDto(
    roles: data.get(#roles, or: $value.roles),
    spectators: data.get(#spectators, or: $value.spectators),
  );

  @override
  LobbyDtoCopyWith<$R2, LobbyDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _LobbyDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class GameInfoDtoMapper extends ClassMapperBase<GameInfoDto> {
  GameInfoDtoMapper._();

  static GameInfoDtoMapper? _instance;
  static GameInfoDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GameInfoDtoMapper._());
      GamePhaseMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'GameInfoDto';

  static GamePhase _$phase(GameInfoDto v) => v.phase;
  static const Field<GameInfoDto, GamePhase> _f$phase = Field('phase', _$phase);
  static int? _$winnerSlot(GameInfoDto v) => v.winnerSlot;
  static const Field<GameInfoDto, int> _f$winnerSlot = Field(
    'winnerSlot',
    _$winnerSlot,
  );
  static String _$reason(GameInfoDto v) => v.reason;
  static const Field<GameInfoDto, String> _f$reason = Field('reason', _$reason);
  static int _$timeLeftMs(GameInfoDto v) => v.timeLeftMs;
  static const Field<GameInfoDto, int> _f$timeLeftMs = Field(
    'timeLeftMs',
    _$timeLeftMs,
  );
  static bool _$lehaPowered(GameInfoDto v) => v.lehaPowered;
  static const Field<GameInfoDto, bool> _f$lehaPowered = Field(
    'lehaPowered',
    _$lehaPowered,
  );
  static int _$powerLeftMs(GameInfoDto v) => v.powerLeftMs;
  static const Field<GameInfoDto, int> _f$powerLeftMs = Field(
    'powerLeftMs',
    _$powerLeftMs,
  );
  static bool _$trapAvailable(GameInfoDto v) => v.trapAvailable;
  static const Field<GameInfoDto, bool> _f$trapAvailable = Field(
    'trapAvailable',
    _$trapAvailable,
  );
  static int _$trapCooldownMs(GameInfoDto v) => v.trapCooldownMs;
  static const Field<GameInfoDto, int> _f$trapCooldownMs = Field(
    'trapCooldownMs',
    _$trapCooldownMs,
  );
  static bool _$trapActive(GameInfoDto v) => v.trapActive;
  static const Field<GameInfoDto, bool> _f$trapActive = Field(
    'trapActive',
    _$trapActive,
  );
  static int _$trapCharges(GameInfoDto v) => v.trapCharges;
  static const Field<GameInfoDto, int> _f$trapCharges = Field(
    'trapCharges',
    _$trapCharges,
  );
  static bool _$abilityAvailable(GameInfoDto v) => v.abilityAvailable;
  static const Field<GameInfoDto, bool> _f$abilityAvailable = Field(
    'abilityAvailable',
    _$abilityAvailable,
  );
  static int _$abilityCooldownMs(GameInfoDto v) => v.abilityCooldownMs;
  static const Field<GameInfoDto, int> _f$abilityCooldownMs = Field(
    'abilityCooldownMs',
    _$abilityCooldownMs,
  );
  static int _$abilityCharges(GameInfoDto v) => v.abilityCharges;
  static const Field<GameInfoDto, int> _f$abilityCharges = Field(
    'abilityCharges',
    _$abilityCharges,
  );
  static bool _$barrelAvailable(GameInfoDto v) => v.barrelAvailable;
  static const Field<GameInfoDto, bool> _f$barrelAvailable = Field(
    'barrelAvailable',
    _$barrelAvailable,
    opt: true,
    def: false,
  );
  static int _$barrelCooldownMs(GameInfoDto v) => v.barrelCooldownMs;
  static const Field<GameInfoDto, int> _f$barrelCooldownMs = Field(
    'barrelCooldownMs',
    _$barrelCooldownMs,
    opt: true,
    def: 0,
  );
  static bool _$femboyAvailable(GameInfoDto v) => v.femboyAvailable;
  static const Field<GameInfoDto, bool> _f$femboyAvailable = Field(
    'femboyAvailable',
    _$femboyAvailable,
    opt: true,
    def: false,
  );
  static int _$femboyCooldownMs(GameInfoDto v) => v.femboyCooldownMs;
  static const Field<GameInfoDto, int> _f$femboyCooldownMs = Field(
    'femboyCooldownMs',
    _$femboyCooldownMs,
    opt: true,
    def: 0,
  );
  static bool _$spiderMode(GameInfoDto v) => v.spiderMode;
  static const Field<GameInfoDto, bool> _f$spiderMode = Field(
    'spiderMode',
    _$spiderMode,
    opt: true,
    def: false,
  );
  static int _$rafaelkiEaten(GameInfoDto v) => v.rafaelkiEaten;
  static const Field<GameInfoDto, int> _f$rafaelkiEaten = Field(
    'rafaelkiEaten',
    _$rafaelkiEaten,
    opt: true,
    def: 0,
  );
  static int _$rafaelkiNeeded(GameInfoDto v) => v.rafaelkiNeeded;
  static const Field<GameInfoDto, int> _f$rafaelkiNeeded = Field(
    'rafaelkiNeeded',
    _$rafaelkiNeeded,
    opt: true,
    def: 0,
  );
  static bool _$clutchAvailable(GameInfoDto v) => v.clutchAvailable;
  static const Field<GameInfoDto, bool> _f$clutchAvailable = Field(
    'clutchAvailable',
    _$clutchAvailable,
    opt: true,
    def: false,
  );
  static bool _$clutchActive(GameInfoDto v) => v.clutchActive;
  static const Field<GameInfoDto, bool> _f$clutchActive = Field(
    'clutchActive',
    _$clutchActive,
    opt: true,
    def: false,
  );
  static int _$clutchHatchMs(GameInfoDto v) => v.clutchHatchMs;
  static const Field<GameInfoDto, int> _f$clutchHatchMs = Field(
    'clutchHatchMs',
    _$clutchHatchMs,
    opt: true,
    def: 0,
  );
  static double _$wizardSaturation(GameInfoDto v) => v.wizardSaturation;
  static const Field<GameInfoDto, double> _f$wizardSaturation = Field(
    'wizardSaturation',
    _$wizardSaturation,
    opt: true,
    def: 0,
  );
  static int _$magicChainCooldownMs(GameInfoDto v) => v.magicChainCooldownMs;
  static const Field<GameInfoDto, int> _f$magicChainCooldownMs = Field(
    'magicChainCooldownMs',
    _$magicChainCooldownMs,
    opt: true,
    def: 0,
  );
  static int _$magicCrystalCharges(GameInfoDto v) => v.magicCrystalCharges;
  static const Field<GameInfoDto, int> _f$magicCrystalCharges = Field(
    'magicCrystalCharges',
    _$magicCrystalCharges,
    opt: true,
    def: 0,
  );
  static bool _$magicCrystalAvailable(GameInfoDto v) => v.magicCrystalAvailable;
  static const Field<GameInfoDto, bool> _f$magicCrystalAvailable = Field(
    'magicCrystalAvailable',
    _$magicCrystalAvailable,
    opt: true,
    def: false,
  );

  @override
  final MappableFields<GameInfoDto> fields = const {
    #phase: _f$phase,
    #winnerSlot: _f$winnerSlot,
    #reason: _f$reason,
    #timeLeftMs: _f$timeLeftMs,
    #lehaPowered: _f$lehaPowered,
    #powerLeftMs: _f$powerLeftMs,
    #trapAvailable: _f$trapAvailable,
    #trapCooldownMs: _f$trapCooldownMs,
    #trapActive: _f$trapActive,
    #trapCharges: _f$trapCharges,
    #abilityAvailable: _f$abilityAvailable,
    #abilityCooldownMs: _f$abilityCooldownMs,
    #abilityCharges: _f$abilityCharges,
    #barrelAvailable: _f$barrelAvailable,
    #barrelCooldownMs: _f$barrelCooldownMs,
    #femboyAvailable: _f$femboyAvailable,
    #femboyCooldownMs: _f$femboyCooldownMs,
    #spiderMode: _f$spiderMode,
    #rafaelkiEaten: _f$rafaelkiEaten,
    #rafaelkiNeeded: _f$rafaelkiNeeded,
    #clutchAvailable: _f$clutchAvailable,
    #clutchActive: _f$clutchActive,
    #clutchHatchMs: _f$clutchHatchMs,
    #wizardSaturation: _f$wizardSaturation,
    #magicChainCooldownMs: _f$magicChainCooldownMs,
    #magicCrystalCharges: _f$magicCrystalCharges,
    #magicCrystalAvailable: _f$magicCrystalAvailable,
  };

  static GameInfoDto _instantiate(DecodingData data) {
    return GameInfoDto(
      phase: data.dec(_f$phase),
      winnerSlot: data.dec(_f$winnerSlot),
      reason: data.dec(_f$reason),
      timeLeftMs: data.dec(_f$timeLeftMs),
      lehaPowered: data.dec(_f$lehaPowered),
      powerLeftMs: data.dec(_f$powerLeftMs),
      trapAvailable: data.dec(_f$trapAvailable),
      trapCooldownMs: data.dec(_f$trapCooldownMs),
      trapActive: data.dec(_f$trapActive),
      trapCharges: data.dec(_f$trapCharges),
      abilityAvailable: data.dec(_f$abilityAvailable),
      abilityCooldownMs: data.dec(_f$abilityCooldownMs),
      abilityCharges: data.dec(_f$abilityCharges),
      barrelAvailable: data.dec(_f$barrelAvailable),
      barrelCooldownMs: data.dec(_f$barrelCooldownMs),
      femboyAvailable: data.dec(_f$femboyAvailable),
      femboyCooldownMs: data.dec(_f$femboyCooldownMs),
      spiderMode: data.dec(_f$spiderMode),
      rafaelkiEaten: data.dec(_f$rafaelkiEaten),
      rafaelkiNeeded: data.dec(_f$rafaelkiNeeded),
      clutchAvailable: data.dec(_f$clutchAvailable),
      clutchActive: data.dec(_f$clutchActive),
      clutchHatchMs: data.dec(_f$clutchHatchMs),
      wizardSaturation: data.dec(_f$wizardSaturation),
      magicChainCooldownMs: data.dec(_f$magicChainCooldownMs),
      magicCrystalCharges: data.dec(_f$magicCrystalCharges),
      magicCrystalAvailable: data.dec(_f$magicCrystalAvailable),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static GameInfoDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GameInfoDto>(map);
  }

  static GameInfoDto fromJson(String json) {
    return ensureInitialized().decodeJson<GameInfoDto>(json);
  }
}

mixin GameInfoDtoMappable {
  String toJson() {
    return GameInfoDtoMapper.ensureInitialized().encodeJson<GameInfoDto>(
      this as GameInfoDto,
    );
  }

  Map<String, dynamic> toMap() {
    return GameInfoDtoMapper.ensureInitialized().encodeMap<GameInfoDto>(
      this as GameInfoDto,
    );
  }

  GameInfoDtoCopyWith<GameInfoDto, GameInfoDto, GameInfoDto> get copyWith =>
      _GameInfoDtoCopyWithImpl<GameInfoDto, GameInfoDto>(
        this as GameInfoDto,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return GameInfoDtoMapper.ensureInitialized().stringifyValue(
      this as GameInfoDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return GameInfoDtoMapper.ensureInitialized().equalsValue(
      this as GameInfoDto,
      other,
    );
  }

  @override
  int get hashCode {
    return GameInfoDtoMapper.ensureInitialized().hashValue(this as GameInfoDto);
  }
}

extension GameInfoDtoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GameInfoDto, $Out> {
  GameInfoDtoCopyWith<$R, GameInfoDto, $Out> get $asGameInfoDto =>
      $base.as((v, t, t2) => _GameInfoDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class GameInfoDtoCopyWith<$R, $In extends GameInfoDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    GamePhase? phase,
    int? winnerSlot,
    String? reason,
    int? timeLeftMs,
    bool? lehaPowered,
    int? powerLeftMs,
    bool? trapAvailable,
    int? trapCooldownMs,
    bool? trapActive,
    int? trapCharges,
    bool? abilityAvailable,
    int? abilityCooldownMs,
    int? abilityCharges,
    bool? barrelAvailable,
    int? barrelCooldownMs,
    bool? femboyAvailable,
    int? femboyCooldownMs,
    bool? spiderMode,
    int? rafaelkiEaten,
    int? rafaelkiNeeded,
    bool? clutchAvailable,
    bool? clutchActive,
    int? clutchHatchMs,
    double? wizardSaturation,
    int? magicChainCooldownMs,
    int? magicCrystalCharges,
    bool? magicCrystalAvailable,
  });
  GameInfoDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _GameInfoDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GameInfoDto, $Out>
    implements GameInfoDtoCopyWith<$R, GameInfoDto, $Out> {
  _GameInfoDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GameInfoDto> $mapper =
      GameInfoDtoMapper.ensureInitialized();
  @override
  $R call({
    GamePhase? phase,
    Object? winnerSlot = $none,
    String? reason,
    int? timeLeftMs,
    bool? lehaPowered,
    int? powerLeftMs,
    bool? trapAvailable,
    int? trapCooldownMs,
    bool? trapActive,
    int? trapCharges,
    bool? abilityAvailable,
    int? abilityCooldownMs,
    int? abilityCharges,
    bool? barrelAvailable,
    int? barrelCooldownMs,
    bool? femboyAvailable,
    int? femboyCooldownMs,
    bool? spiderMode,
    int? rafaelkiEaten,
    int? rafaelkiNeeded,
    bool? clutchAvailable,
    bool? clutchActive,
    int? clutchHatchMs,
    double? wizardSaturation,
    int? magicChainCooldownMs,
    int? magicCrystalCharges,
    bool? magicCrystalAvailable,
  }) => $apply(
    FieldCopyWithData({
      if (phase != null) #phase: phase,
      if (winnerSlot != $none) #winnerSlot: winnerSlot,
      if (reason != null) #reason: reason,
      if (timeLeftMs != null) #timeLeftMs: timeLeftMs,
      if (lehaPowered != null) #lehaPowered: lehaPowered,
      if (powerLeftMs != null) #powerLeftMs: powerLeftMs,
      if (trapAvailable != null) #trapAvailable: trapAvailable,
      if (trapCooldownMs != null) #trapCooldownMs: trapCooldownMs,
      if (trapActive != null) #trapActive: trapActive,
      if (trapCharges != null) #trapCharges: trapCharges,
      if (abilityAvailable != null) #abilityAvailable: abilityAvailable,
      if (abilityCooldownMs != null) #abilityCooldownMs: abilityCooldownMs,
      if (abilityCharges != null) #abilityCharges: abilityCharges,
      if (barrelAvailable != null) #barrelAvailable: barrelAvailable,
      if (barrelCooldownMs != null) #barrelCooldownMs: barrelCooldownMs,
      if (femboyAvailable != null) #femboyAvailable: femboyAvailable,
      if (femboyCooldownMs != null) #femboyCooldownMs: femboyCooldownMs,
      if (spiderMode != null) #spiderMode: spiderMode,
      if (rafaelkiEaten != null) #rafaelkiEaten: rafaelkiEaten,
      if (rafaelkiNeeded != null) #rafaelkiNeeded: rafaelkiNeeded,
      if (clutchAvailable != null) #clutchAvailable: clutchAvailable,
      if (clutchActive != null) #clutchActive: clutchActive,
      if (clutchHatchMs != null) #clutchHatchMs: clutchHatchMs,
      if (wizardSaturation != null) #wizardSaturation: wizardSaturation,
      if (magicChainCooldownMs != null)
        #magicChainCooldownMs: magicChainCooldownMs,
      if (magicCrystalCharges != null)
        #magicCrystalCharges: magicCrystalCharges,
      if (magicCrystalAvailable != null)
        #magicCrystalAvailable: magicCrystalAvailable,
    }),
  );
  @override
  GameInfoDto $make(CopyWithData data) => GameInfoDto(
    phase: data.get(#phase, or: $value.phase),
    winnerSlot: data.get(#winnerSlot, or: $value.winnerSlot),
    reason: data.get(#reason, or: $value.reason),
    timeLeftMs: data.get(#timeLeftMs, or: $value.timeLeftMs),
    lehaPowered: data.get(#lehaPowered, or: $value.lehaPowered),
    powerLeftMs: data.get(#powerLeftMs, or: $value.powerLeftMs),
    trapAvailable: data.get(#trapAvailable, or: $value.trapAvailable),
    trapCooldownMs: data.get(#trapCooldownMs, or: $value.trapCooldownMs),
    trapActive: data.get(#trapActive, or: $value.trapActive),
    trapCharges: data.get(#trapCharges, or: $value.trapCharges),
    abilityAvailable: data.get(#abilityAvailable, or: $value.abilityAvailable),
    abilityCooldownMs: data.get(
      #abilityCooldownMs,
      or: $value.abilityCooldownMs,
    ),
    abilityCharges: data.get(#abilityCharges, or: $value.abilityCharges),
    barrelAvailable: data.get(#barrelAvailable, or: $value.barrelAvailable),
    barrelCooldownMs: data.get(#barrelCooldownMs, or: $value.barrelCooldownMs),
    femboyAvailable: data.get(#femboyAvailable, or: $value.femboyAvailable),
    femboyCooldownMs: data.get(#femboyCooldownMs, or: $value.femboyCooldownMs),
    spiderMode: data.get(#spiderMode, or: $value.spiderMode),
    rafaelkiEaten: data.get(#rafaelkiEaten, or: $value.rafaelkiEaten),
    rafaelkiNeeded: data.get(#rafaelkiNeeded, or: $value.rafaelkiNeeded),
    clutchAvailable: data.get(#clutchAvailable, or: $value.clutchAvailable),
    clutchActive: data.get(#clutchActive, or: $value.clutchActive),
    clutchHatchMs: data.get(#clutchHatchMs, or: $value.clutchHatchMs),
    wizardSaturation: data.get(#wizardSaturation, or: $value.wizardSaturation),
    magicChainCooldownMs: data.get(
      #magicChainCooldownMs,
      or: $value.magicChainCooldownMs,
    ),
    magicCrystalCharges: data.get(
      #magicCrystalCharges,
      or: $value.magicCrystalCharges,
    ),
    magicCrystalAvailable: data.get(
      #magicCrystalAvailable,
      or: $value.magicCrystalAvailable,
    ),
  );

  @override
  GameInfoDtoCopyWith<$R2, GameInfoDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _GameInfoDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class YouDtoMapper extends ClassMapperBase<YouDto> {
  YouDtoMapper._();

  static YouDtoMapper? _instance;
  static YouDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = YouDtoMapper._());
      PlayerRoleMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'YouDto';

  static String _$id(YouDto v) => v.id;
  static const Field<YouDto, String> _f$id = Field('id', _$id);
  static int? _$slot(YouDto v) => v.slot;
  static const Field<YouDto, int> _f$slot = Field('slot', _$slot);
  static PlayerRole _$role(YouDto v) => v.role;
  static const Field<YouDto, PlayerRole> _f$role = Field('role', _$role);
  static String _$name(YouDto v) => v.name;
  static const Field<YouDto, String> _f$name = Field(
    'name',
    _$name,
    opt: true,
    def: '',
  );

  @override
  final MappableFields<YouDto> fields = const {
    #id: _f$id,
    #slot: _f$slot,
    #role: _f$role,
    #name: _f$name,
  };

  static YouDto _instantiate(DecodingData data) {
    return YouDto(
      id: data.dec(_f$id),
      slot: data.dec(_f$slot),
      role: data.dec(_f$role),
      name: data.dec(_f$name),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static YouDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<YouDto>(map);
  }

  static YouDto fromJson(String json) {
    return ensureInitialized().decodeJson<YouDto>(json);
  }
}

mixin YouDtoMappable {
  String toJson() {
    return YouDtoMapper.ensureInitialized().encodeJson<YouDto>(this as YouDto);
  }

  Map<String, dynamic> toMap() {
    return YouDtoMapper.ensureInitialized().encodeMap<YouDto>(this as YouDto);
  }

  YouDtoCopyWith<YouDto, YouDto, YouDto> get copyWith =>
      _YouDtoCopyWithImpl<YouDto, YouDto>(this as YouDto, $identity, $identity);
  @override
  String toString() {
    return YouDtoMapper.ensureInitialized().stringifyValue(this as YouDto);
  }

  @override
  bool operator ==(Object other) {
    return YouDtoMapper.ensureInitialized().equalsValue(this as YouDto, other);
  }

  @override
  int get hashCode {
    return YouDtoMapper.ensureInitialized().hashValue(this as YouDto);
  }
}

extension YouDtoValueCopy<$R, $Out> on ObjectCopyWith<$R, YouDto, $Out> {
  YouDtoCopyWith<$R, YouDto, $Out> get $asYouDto =>
      $base.as((v, t, t2) => _YouDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class YouDtoCopyWith<$R, $In extends YouDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? id, int? slot, PlayerRole? role, String? name});
  YouDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _YouDtoCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, YouDto, $Out>
    implements YouDtoCopyWith<$R, YouDto, $Out> {
  _YouDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<YouDto> $mapper = YouDtoMapper.ensureInitialized();
  @override
  $R call({String? id, Object? slot = $none, PlayerRole? role, String? name}) =>
      $apply(
        FieldCopyWithData({
          if (id != null) #id: id,
          if (slot != $none) #slot: slot,
          if (role != null) #role: role,
          if (name != null) #name: name,
        }),
      );
  @override
  YouDto $make(CopyWithData data) => YouDto(
    id: data.get(#id, or: $value.id),
    slot: data.get(#slot, or: $value.slot),
    role: data.get(#role, or: $value.role),
    name: data.get(#name, or: $value.name),
  );

  @override
  YouDtoCopyWith<$R2, YouDto, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _YouDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class UserStatsDtoMapper extends ClassMapperBase<UserStatsDto> {
  UserStatsDtoMapper._();

  static UserStatsDtoMapper? _instance;
  static UserStatsDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = UserStatsDtoMapper._());
    }
    return _instance!;
  }

  @override
  final String id = 'UserStatsDto';

  static String _$name(UserStatsDto v) => v.name;
  static const Field<UserStatsDto, String> _f$name = Field('name', _$name);
  static int _$wins(UserStatsDto v) => v.wins;
  static const Field<UserStatsDto, int> _f$wins = Field('wins', _$wins);
  static int _$losses(UserStatsDto v) => v.losses;
  static const Field<UserStatsDto, int> _f$losses = Field('losses', _$losses);

  @override
  final MappableFields<UserStatsDto> fields = const {
    #name: _f$name,
    #wins: _f$wins,
    #losses: _f$losses,
  };

  static UserStatsDto _instantiate(DecodingData data) {
    return UserStatsDto(
      name: data.dec(_f$name),
      wins: data.dec(_f$wins),
      losses: data.dec(_f$losses),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static UserStatsDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<UserStatsDto>(map);
  }

  static UserStatsDto fromJson(String json) {
    return ensureInitialized().decodeJson<UserStatsDto>(json);
  }
}

mixin UserStatsDtoMappable {
  String toJson() {
    return UserStatsDtoMapper.ensureInitialized().encodeJson<UserStatsDto>(
      this as UserStatsDto,
    );
  }

  Map<String, dynamic> toMap() {
    return UserStatsDtoMapper.ensureInitialized().encodeMap<UserStatsDto>(
      this as UserStatsDto,
    );
  }

  UserStatsDtoCopyWith<UserStatsDto, UserStatsDto, UserStatsDto> get copyWith =>
      _UserStatsDtoCopyWithImpl<UserStatsDto, UserStatsDto>(
        this as UserStatsDto,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return UserStatsDtoMapper.ensureInitialized().stringifyValue(
      this as UserStatsDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return UserStatsDtoMapper.ensureInitialized().equalsValue(
      this as UserStatsDto,
      other,
    );
  }

  @override
  int get hashCode {
    return UserStatsDtoMapper.ensureInitialized().hashValue(
      this as UserStatsDto,
    );
  }
}

extension UserStatsDtoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, UserStatsDto, $Out> {
  UserStatsDtoCopyWith<$R, UserStatsDto, $Out> get $asUserStatsDto =>
      $base.as((v, t, t2) => _UserStatsDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class UserStatsDtoCopyWith<$R, $In extends UserStatsDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({String? name, int? wins, int? losses});
  UserStatsDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _UserStatsDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, UserStatsDto, $Out>
    implements UserStatsDtoCopyWith<$R, UserStatsDto, $Out> {
  _UserStatsDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<UserStatsDto> $mapper =
      UserStatsDtoMapper.ensureInitialized();
  @override
  $R call({String? name, int? wins, int? losses}) => $apply(
    FieldCopyWithData({
      if (name != null) #name: name,
      if (wins != null) #wins: wins,
      if (losses != null) #losses: losses,
    }),
  );
  @override
  UserStatsDto $make(CopyWithData data) => UserStatsDto(
    name: data.get(#name, or: $value.name),
    wins: data.get(#wins, or: $value.wins),
    losses: data.get(#losses, or: $value.losses),
  );

  @override
  UserStatsDtoCopyWith<$R2, UserStatsDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _UserStatsDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

class GameSnapshotDtoMapper extends ClassMapperBase<GameSnapshotDto> {
  GameSnapshotDtoMapper._();

  static GameSnapshotDtoMapper? _instance;
  static GameSnapshotDtoMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = GameSnapshotDtoMapper._());
      YouDtoMapper.ensureInitialized();
      Vec2iMapper.ensureInitialized();
      CaveBiomeMapper.ensureInitialized();
      ChimeDtoMapper.ensureInitialized();
      MushroomDtoMapper.ensureInitialized();
      IllusionDtoMapper.ensureInitialized();
      SarcophagusDtoMapper.ensureInitialized();
      MummyDtoMapper.ensureInitialized();
      LogoDtoMapper.ensureInitialized();
      TrapDtoMapper.ensureInitialized();
      WebDtoMapper.ensureInitialized();
      BarrelDtoMapper.ensureInitialized();
      PortalDtoMapper.ensureInitialized();
      MagicCrystalDtoMapper.ensureInitialized();
      MagicChainDtoMapper.ensureInitialized();
      ClutchDtoMapper.ensureInitialized();
      TrailPointDtoMapper.ensureInitialized();
      PlayerDtoMapper.ensureInitialized();
      ScoreDtoMapper.ensureInitialized();
      LobbyDtoMapper.ensureInitialized();
      GameInfoDtoMapper.ensureInitialized();
      UserStatsDtoMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'GameSnapshotDto';

  static String _$type(GameSnapshotDto v) => v.type;
  static const Field<GameSnapshotDto, String> _f$type = Field('type', _$type);
  static YouDto _$you(GameSnapshotDto v) => v.you;
  static const Field<GameSnapshotDto, YouDto> _f$you = Field('you', _$you);
  static int _$rows(GameSnapshotDto v) => v.rows;
  static const Field<GameSnapshotDto, int> _f$rows = Field('rows', _$rows);
  static int _$cols(GameSnapshotDto v) => v.cols;
  static const Field<GameSnapshotDto, int> _f$cols = Field('cols', _$cols);
  static List<String> _$maze(GameSnapshotDto v) => v.maze;
  static const Field<GameSnapshotDto, List<String>> _f$maze = Field(
    'maze',
    _$maze,
  );
  static List<Vec2i> _$bushes(GameSnapshotDto v) => v.bushes;
  static const Field<GameSnapshotDto, List<Vec2i>> _f$bushes = Field(
    'bushes',
    _$bushes,
    opt: true,
    def: const [],
  );
  static List<Vec2i> _$crackedWalls(GameSnapshotDto v) => v.crackedWalls;
  static const Field<GameSnapshotDto, List<Vec2i>> _f$crackedWalls = Field(
    'crackedWalls',
    _$crackedWalls,
    opt: true,
    def: const [],
  );
  static CaveBiome _$biome(GameSnapshotDto v) => v.biome;
  static const Field<GameSnapshotDto, CaveBiome> _f$biome = Field(
    'biome',
    _$biome,
    opt: true,
    def: CaveBiome.forest,
  );
  static int _$stoneSeed(GameSnapshotDto v) => v.stoneSeed;
  static const Field<GameSnapshotDto, int> _f$stoneSeed = Field(
    'stoneSeed',
    _$stoneSeed,
    opt: true,
    def: 0,
  );
  static List<Vec2i> _$crystals(GameSnapshotDto v) => v.crystals;
  static const Field<GameSnapshotDto, List<Vec2i>> _f$crystals = Field(
    'crystals',
    _$crystals,
    opt: true,
    def: const [],
  );
  static List<Vec2i> _$quicksand(GameSnapshotDto v) => v.quicksand;
  static const Field<GameSnapshotDto, List<Vec2i>> _f$quicksand = Field(
    'quicksand',
    _$quicksand,
    opt: true,
    def: const [],
  );
  static List<Vec2i> _$amethystWalls(GameSnapshotDto v) => v.amethystWalls;
  static const Field<GameSnapshotDto, List<Vec2i>> _f$amethystWalls = Field(
    'amethystWalls',
    _$amethystWalls,
    opt: true,
    def: const [],
  );
  static List<Vec2i> _$amethystShards(GameSnapshotDto v) => v.amethystShards;
  static const Field<GameSnapshotDto, List<Vec2i>> _f$amethystShards = Field(
    'amethystShards',
    _$amethystShards,
    opt: true,
    def: const [],
  );
  static List<ChimeDto> _$chimes(GameSnapshotDto v) => v.chimes;
  static const Field<GameSnapshotDto, List<ChimeDto>> _f$chimes = Field(
    'chimes',
    _$chimes,
    opt: true,
    def: const [],
  );
  static List<MushroomDto> _$mushrooms(GameSnapshotDto v) => v.mushrooms;
  static const Field<GameSnapshotDto, List<MushroomDto>> _f$mushrooms = Field(
    'mushrooms',
    _$mushrooms,
    opt: true,
    def: const [],
  );
  static List<Vec2i> _$spores(GameSnapshotDto v) => v.spores;
  static const Field<GameSnapshotDto, List<Vec2i>> _f$spores = Field(
    'spores',
    _$spores,
    opt: true,
    def: const [],
  );
  static List<IllusionDto> _$illusions(GameSnapshotDto v) => v.illusions;
  static const Field<GameSnapshotDto, List<IllusionDto>> _f$illusions = Field(
    'illusions',
    _$illusions,
    opt: true,
    def: const [],
  );
  static List<SarcophagusDto> _$sarcophagi(GameSnapshotDto v) => v.sarcophagi;
  static const Field<GameSnapshotDto, List<SarcophagusDto>> _f$sarcophagi =
      Field('sarcophagi', _$sarcophagi, opt: true, def: const []);
  static List<MummyDto> _$mummies(GameSnapshotDto v) => v.mummies;
  static const Field<GameSnapshotDto, List<MummyDto>> _f$mummies = Field(
    'mummies',
    _$mummies,
    opt: true,
    def: const [],
  );
  static List<CaveBiome> _$enabledBiomes(GameSnapshotDto v) => v.enabledBiomes;
  static const Field<GameSnapshotDto, List<CaveBiome>> _f$enabledBiomes = Field(
    'enabledBiomes',
    _$enabledBiomes,
    opt: true,
    def: const [],
  );
  static bool _$sandboxMode(GameSnapshotDto v) => v.sandboxMode;
  static const Field<GameSnapshotDto, bool> _f$sandboxMode = Field(
    'sandboxMode',
    _$sandboxMode,
    opt: true,
    def: false,
  );
  static List<LogoDto> _$logos(GameSnapshotDto v) => v.logos;
  static const Field<GameSnapshotDto, List<LogoDto>> _f$logos = Field(
    'logos',
    _$logos,
  );
  static List<TrapDto> _$traps(GameSnapshotDto v) => v.traps;
  static const Field<GameSnapshotDto, List<TrapDto>> _f$traps = Field(
    'traps',
    _$traps,
  );
  static List<WebDto> _$webs(GameSnapshotDto v) => v.webs;
  static const Field<GameSnapshotDto, List<WebDto>> _f$webs = Field(
    'webs',
    _$webs,
  );
  static List<BarrelDto> _$barrels(GameSnapshotDto v) => v.barrels;
  static const Field<GameSnapshotDto, List<BarrelDto>> _f$barrels = Field(
    'barrels',
    _$barrels,
  );
  static List<PortalDto> _$portals(GameSnapshotDto v) => v.portals;
  static const Field<GameSnapshotDto, List<PortalDto>> _f$portals = Field(
    'portals',
    _$portals,
  );
  static List<MagicCrystalDto> _$magicCrystals(GameSnapshotDto v) =>
      v.magicCrystals;
  static const Field<GameSnapshotDto, List<MagicCrystalDto>> _f$magicCrystals =
      Field('magicCrystals', _$magicCrystals, opt: true, def: const []);
  static List<MagicChainDto> _$magicChains(GameSnapshotDto v) => v.magicChains;
  static const Field<GameSnapshotDto, List<MagicChainDto>> _f$magicChains =
      Field('magicChains', _$magicChains, opt: true, def: const []);
  static ClutchDto? _$clutch(GameSnapshotDto v) => v.clutch;
  static const Field<GameSnapshotDto, ClutchDto> _f$clutch = Field(
    'clutch',
    _$clutch,
    opt: true,
  );
  static List<TrailPointDto> _$trail(GameSnapshotDto v) => v.trail;
  static const Field<GameSnapshotDto, List<TrailPointDto>> _f$trail = Field(
    'trail',
    _$trail,
  );
  static List<PlayerDto> _$players(GameSnapshotDto v) => v.players;
  static const Field<GameSnapshotDto, List<PlayerDto>> _f$players = Field(
    'players',
    _$players,
  );
  static List<ScoreDto> _$scores(GameSnapshotDto v) => v.scores;
  static const Field<GameSnapshotDto, List<ScoreDto>> _f$scores = Field(
    'scores',
    _$scores,
  );
  static int _$connectedPlayers(GameSnapshotDto v) => v.connectedPlayers;
  static const Field<GameSnapshotDto, int> _f$connectedPlayers = Field(
    'connectedPlayers',
    _$connectedPlayers,
  );
  static LobbyDto _$lobby(GameSnapshotDto v) => v.lobby;
  static const Field<GameSnapshotDto, LobbyDto> _f$lobby = Field(
    'lobby',
    _$lobby,
  );
  static GameInfoDto _$game(GameSnapshotDto v) => v.game;
  static const Field<GameSnapshotDto, GameInfoDto> _f$game = Field(
    'game',
    _$game,
  );
  static String _$status(GameSnapshotDto v) => v.status;
  static const Field<GameSnapshotDto, String> _f$status = Field(
    'status',
    _$status,
  );
  static List<UserStatsDto> _$leaderboard(GameSnapshotDto v) => v.leaderboard;
  static const Field<GameSnapshotDto, List<UserStatsDto>> _f$leaderboard =
      Field('leaderboard', _$leaderboard, opt: true, def: const []);
  static UserStatsDto? _$yourStats(GameSnapshotDto v) => v.yourStats;
  static const Field<GameSnapshotDto, UserStatsDto> _f$yourStats = Field(
    'yourStats',
    _$yourStats,
    opt: true,
  );

  @override
  final MappableFields<GameSnapshotDto> fields = const {
    #type: _f$type,
    #you: _f$you,
    #rows: _f$rows,
    #cols: _f$cols,
    #maze: _f$maze,
    #bushes: _f$bushes,
    #crackedWalls: _f$crackedWalls,
    #biome: _f$biome,
    #stoneSeed: _f$stoneSeed,
    #crystals: _f$crystals,
    #quicksand: _f$quicksand,
    #amethystWalls: _f$amethystWalls,
    #amethystShards: _f$amethystShards,
    #chimes: _f$chimes,
    #mushrooms: _f$mushrooms,
    #spores: _f$spores,
    #illusions: _f$illusions,
    #sarcophagi: _f$sarcophagi,
    #mummies: _f$mummies,
    #enabledBiomes: _f$enabledBiomes,
    #sandboxMode: _f$sandboxMode,
    #logos: _f$logos,
    #traps: _f$traps,
    #webs: _f$webs,
    #barrels: _f$barrels,
    #portals: _f$portals,
    #magicCrystals: _f$magicCrystals,
    #magicChains: _f$magicChains,
    #clutch: _f$clutch,
    #trail: _f$trail,
    #players: _f$players,
    #scores: _f$scores,
    #connectedPlayers: _f$connectedPlayers,
    #lobby: _f$lobby,
    #game: _f$game,
    #status: _f$status,
    #leaderboard: _f$leaderboard,
    #yourStats: _f$yourStats,
  };

  static GameSnapshotDto _instantiate(DecodingData data) {
    return GameSnapshotDto(
      type: data.dec(_f$type),
      you: data.dec(_f$you),
      rows: data.dec(_f$rows),
      cols: data.dec(_f$cols),
      maze: data.dec(_f$maze),
      bushes: data.dec(_f$bushes),
      crackedWalls: data.dec(_f$crackedWalls),
      biome: data.dec(_f$biome),
      stoneSeed: data.dec(_f$stoneSeed),
      crystals: data.dec(_f$crystals),
      quicksand: data.dec(_f$quicksand),
      amethystWalls: data.dec(_f$amethystWalls),
      amethystShards: data.dec(_f$amethystShards),
      chimes: data.dec(_f$chimes),
      mushrooms: data.dec(_f$mushrooms),
      spores: data.dec(_f$spores),
      illusions: data.dec(_f$illusions),
      sarcophagi: data.dec(_f$sarcophagi),
      mummies: data.dec(_f$mummies),
      enabledBiomes: data.dec(_f$enabledBiomes),
      sandboxMode: data.dec(_f$sandboxMode),
      logos: data.dec(_f$logos),
      traps: data.dec(_f$traps),
      webs: data.dec(_f$webs),
      barrels: data.dec(_f$barrels),
      portals: data.dec(_f$portals),
      magicCrystals: data.dec(_f$magicCrystals),
      magicChains: data.dec(_f$magicChains),
      clutch: data.dec(_f$clutch),
      trail: data.dec(_f$trail),
      players: data.dec(_f$players),
      scores: data.dec(_f$scores),
      connectedPlayers: data.dec(_f$connectedPlayers),
      lobby: data.dec(_f$lobby),
      game: data.dec(_f$game),
      status: data.dec(_f$status),
      leaderboard: data.dec(_f$leaderboard),
      yourStats: data.dec(_f$yourStats),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static GameSnapshotDto fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<GameSnapshotDto>(map);
  }

  static GameSnapshotDto fromJson(String json) {
    return ensureInitialized().decodeJson<GameSnapshotDto>(json);
  }
}

mixin GameSnapshotDtoMappable {
  String toJson() {
    return GameSnapshotDtoMapper.ensureInitialized()
        .encodeJson<GameSnapshotDto>(this as GameSnapshotDto);
  }

  Map<String, dynamic> toMap() {
    return GameSnapshotDtoMapper.ensureInitialized().encodeMap<GameSnapshotDto>(
      this as GameSnapshotDto,
    );
  }

  GameSnapshotDtoCopyWith<GameSnapshotDto, GameSnapshotDto, GameSnapshotDto>
  get copyWith =>
      _GameSnapshotDtoCopyWithImpl<GameSnapshotDto, GameSnapshotDto>(
        this as GameSnapshotDto,
        $identity,
        $identity,
      );
  @override
  String toString() {
    return GameSnapshotDtoMapper.ensureInitialized().stringifyValue(
      this as GameSnapshotDto,
    );
  }

  @override
  bool operator ==(Object other) {
    return GameSnapshotDtoMapper.ensureInitialized().equalsValue(
      this as GameSnapshotDto,
      other,
    );
  }

  @override
  int get hashCode {
    return GameSnapshotDtoMapper.ensureInitialized().hashValue(
      this as GameSnapshotDto,
    );
  }
}

extension GameSnapshotDtoValueCopy<$R, $Out>
    on ObjectCopyWith<$R, GameSnapshotDto, $Out> {
  GameSnapshotDtoCopyWith<$R, GameSnapshotDto, $Out> get $asGameSnapshotDto =>
      $base.as((v, t, t2) => _GameSnapshotDtoCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class GameSnapshotDtoCopyWith<$R, $In extends GameSnapshotDto, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  YouDtoCopyWith<$R, YouDto, YouDto> get you;
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get maze;
  ListCopyWith<$R, Vec2i, Vec2iCopyWith<$R, Vec2i, Vec2i>> get bushes;
  ListCopyWith<$R, Vec2i, Vec2iCopyWith<$R, Vec2i, Vec2i>> get crackedWalls;
  ListCopyWith<$R, Vec2i, Vec2iCopyWith<$R, Vec2i, Vec2i>> get crystals;
  ListCopyWith<$R, Vec2i, Vec2iCopyWith<$R, Vec2i, Vec2i>> get quicksand;
  ListCopyWith<$R, Vec2i, Vec2iCopyWith<$R, Vec2i, Vec2i>> get amethystWalls;
  ListCopyWith<$R, Vec2i, Vec2iCopyWith<$R, Vec2i, Vec2i>> get amethystShards;
  ListCopyWith<$R, ChimeDto, ChimeDtoCopyWith<$R, ChimeDto, ChimeDto>>
  get chimes;
  ListCopyWith<
    $R,
    MushroomDto,
    MushroomDtoCopyWith<$R, MushroomDto, MushroomDto>
  >
  get mushrooms;
  ListCopyWith<$R, Vec2i, Vec2iCopyWith<$R, Vec2i, Vec2i>> get spores;
  ListCopyWith<
    $R,
    IllusionDto,
    IllusionDtoCopyWith<$R, IllusionDto, IllusionDto>
  >
  get illusions;
  ListCopyWith<
    $R,
    SarcophagusDto,
    SarcophagusDtoCopyWith<$R, SarcophagusDto, SarcophagusDto>
  >
  get sarcophagi;
  ListCopyWith<$R, MummyDto, MummyDtoCopyWith<$R, MummyDto, MummyDto>>
  get mummies;
  ListCopyWith<$R, CaveBiome, ObjectCopyWith<$R, CaveBiome, CaveBiome>>
  get enabledBiomes;
  ListCopyWith<$R, LogoDto, LogoDtoCopyWith<$R, LogoDto, LogoDto>> get logos;
  ListCopyWith<$R, TrapDto, TrapDtoCopyWith<$R, TrapDto, TrapDto>> get traps;
  ListCopyWith<$R, WebDto, WebDtoCopyWith<$R, WebDto, WebDto>> get webs;
  ListCopyWith<$R, BarrelDto, BarrelDtoCopyWith<$R, BarrelDto, BarrelDto>>
  get barrels;
  ListCopyWith<$R, PortalDto, PortalDtoCopyWith<$R, PortalDto, PortalDto>>
  get portals;
  ListCopyWith<
    $R,
    MagicCrystalDto,
    MagicCrystalDtoCopyWith<$R, MagicCrystalDto, MagicCrystalDto>
  >
  get magicCrystals;
  ListCopyWith<
    $R,
    MagicChainDto,
    MagicChainDtoCopyWith<$R, MagicChainDto, MagicChainDto>
  >
  get magicChains;
  ClutchDtoCopyWith<$R, ClutchDto, ClutchDto>? get clutch;
  ListCopyWith<
    $R,
    TrailPointDto,
    TrailPointDtoCopyWith<$R, TrailPointDto, TrailPointDto>
  >
  get trail;
  ListCopyWith<$R, PlayerDto, PlayerDtoCopyWith<$R, PlayerDto, PlayerDto>>
  get players;
  ListCopyWith<$R, ScoreDto, ScoreDtoCopyWith<$R, ScoreDto, ScoreDto>>
  get scores;
  LobbyDtoCopyWith<$R, LobbyDto, LobbyDto> get lobby;
  GameInfoDtoCopyWith<$R, GameInfoDto, GameInfoDto> get game;
  ListCopyWith<
    $R,
    UserStatsDto,
    UserStatsDtoCopyWith<$R, UserStatsDto, UserStatsDto>
  >
  get leaderboard;
  UserStatsDtoCopyWith<$R, UserStatsDto, UserStatsDto>? get yourStats;
  $R call({
    String? type,
    YouDto? you,
    int? rows,
    int? cols,
    List<String>? maze,
    List<Vec2i>? bushes,
    List<Vec2i>? crackedWalls,
    CaveBiome? biome,
    int? stoneSeed,
    List<Vec2i>? crystals,
    List<Vec2i>? quicksand,
    List<Vec2i>? amethystWalls,
    List<Vec2i>? amethystShards,
    List<ChimeDto>? chimes,
    List<MushroomDto>? mushrooms,
    List<Vec2i>? spores,
    List<IllusionDto>? illusions,
    List<SarcophagusDto>? sarcophagi,
    List<MummyDto>? mummies,
    List<CaveBiome>? enabledBiomes,
    bool? sandboxMode,
    List<LogoDto>? logos,
    List<TrapDto>? traps,
    List<WebDto>? webs,
    List<BarrelDto>? barrels,
    List<PortalDto>? portals,
    List<MagicCrystalDto>? magicCrystals,
    List<MagicChainDto>? magicChains,
    ClutchDto? clutch,
    List<TrailPointDto>? trail,
    List<PlayerDto>? players,
    List<ScoreDto>? scores,
    int? connectedPlayers,
    LobbyDto? lobby,
    GameInfoDto? game,
    String? status,
    List<UserStatsDto>? leaderboard,
    UserStatsDto? yourStats,
  });
  GameSnapshotDtoCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  );
}

class _GameSnapshotDtoCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, GameSnapshotDto, $Out>
    implements GameSnapshotDtoCopyWith<$R, GameSnapshotDto, $Out> {
  _GameSnapshotDtoCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<GameSnapshotDto> $mapper =
      GameSnapshotDtoMapper.ensureInitialized();
  @override
  YouDtoCopyWith<$R, YouDto, YouDto> get you =>
      $value.you.copyWith.$chain((v) => call(you: v));
  @override
  ListCopyWith<$R, String, ObjectCopyWith<$R, String, String>> get maze =>
      ListCopyWith(
        $value.maze,
        (v, t) => ObjectCopyWith(v, $identity, t),
        (v) => call(maze: v),
      );
  @override
  ListCopyWith<$R, Vec2i, Vec2iCopyWith<$R, Vec2i, Vec2i>> get bushes =>
      ListCopyWith(
        $value.bushes,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(bushes: v),
      );
  @override
  ListCopyWith<$R, Vec2i, Vec2iCopyWith<$R, Vec2i, Vec2i>> get crackedWalls =>
      ListCopyWith(
        $value.crackedWalls,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(crackedWalls: v),
      );
  @override
  ListCopyWith<$R, Vec2i, Vec2iCopyWith<$R, Vec2i, Vec2i>> get crystals =>
      ListCopyWith(
        $value.crystals,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(crystals: v),
      );
  @override
  ListCopyWith<$R, Vec2i, Vec2iCopyWith<$R, Vec2i, Vec2i>> get quicksand =>
      ListCopyWith(
        $value.quicksand,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(quicksand: v),
      );
  @override
  ListCopyWith<$R, Vec2i, Vec2iCopyWith<$R, Vec2i, Vec2i>> get amethystWalls =>
      ListCopyWith(
        $value.amethystWalls,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(amethystWalls: v),
      );
  @override
  ListCopyWith<$R, Vec2i, Vec2iCopyWith<$R, Vec2i, Vec2i>> get amethystShards =>
      ListCopyWith(
        $value.amethystShards,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(amethystShards: v),
      );
  @override
  ListCopyWith<$R, ChimeDto, ChimeDtoCopyWith<$R, ChimeDto, ChimeDto>>
  get chimes => ListCopyWith(
    $value.chimes,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(chimes: v),
  );
  @override
  ListCopyWith<
    $R,
    MushroomDto,
    MushroomDtoCopyWith<$R, MushroomDto, MushroomDto>
  >
  get mushrooms => ListCopyWith(
    $value.mushrooms,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(mushrooms: v),
  );
  @override
  ListCopyWith<$R, Vec2i, Vec2iCopyWith<$R, Vec2i, Vec2i>> get spores =>
      ListCopyWith(
        $value.spores,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(spores: v),
      );
  @override
  ListCopyWith<
    $R,
    IllusionDto,
    IllusionDtoCopyWith<$R, IllusionDto, IllusionDto>
  >
  get illusions => ListCopyWith(
    $value.illusions,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(illusions: v),
  );
  @override
  ListCopyWith<
    $R,
    SarcophagusDto,
    SarcophagusDtoCopyWith<$R, SarcophagusDto, SarcophagusDto>
  >
  get sarcophagi => ListCopyWith(
    $value.sarcophagi,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(sarcophagi: v),
  );
  @override
  ListCopyWith<$R, MummyDto, MummyDtoCopyWith<$R, MummyDto, MummyDto>>
  get mummies => ListCopyWith(
    $value.mummies,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(mummies: v),
  );
  @override
  ListCopyWith<$R, CaveBiome, ObjectCopyWith<$R, CaveBiome, CaveBiome>>
  get enabledBiomes => ListCopyWith(
    $value.enabledBiomes,
    (v, t) => ObjectCopyWith(v, $identity, t),
    (v) => call(enabledBiomes: v),
  );
  @override
  ListCopyWith<$R, LogoDto, LogoDtoCopyWith<$R, LogoDto, LogoDto>> get logos =>
      ListCopyWith(
        $value.logos,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(logos: v),
      );
  @override
  ListCopyWith<$R, TrapDto, TrapDtoCopyWith<$R, TrapDto, TrapDto>> get traps =>
      ListCopyWith(
        $value.traps,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(traps: v),
      );
  @override
  ListCopyWith<$R, WebDto, WebDtoCopyWith<$R, WebDto, WebDto>> get webs =>
      ListCopyWith(
        $value.webs,
        (v, t) => v.copyWith.$chain(t),
        (v) => call(webs: v),
      );
  @override
  ListCopyWith<$R, BarrelDto, BarrelDtoCopyWith<$R, BarrelDto, BarrelDto>>
  get barrels => ListCopyWith(
    $value.barrels,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(barrels: v),
  );
  @override
  ListCopyWith<$R, PortalDto, PortalDtoCopyWith<$R, PortalDto, PortalDto>>
  get portals => ListCopyWith(
    $value.portals,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(portals: v),
  );
  @override
  ListCopyWith<
    $R,
    MagicCrystalDto,
    MagicCrystalDtoCopyWith<$R, MagicCrystalDto, MagicCrystalDto>
  >
  get magicCrystals => ListCopyWith(
    $value.magicCrystals,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(magicCrystals: v),
  );
  @override
  ListCopyWith<
    $R,
    MagicChainDto,
    MagicChainDtoCopyWith<$R, MagicChainDto, MagicChainDto>
  >
  get magicChains => ListCopyWith(
    $value.magicChains,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(magicChains: v),
  );
  @override
  ClutchDtoCopyWith<$R, ClutchDto, ClutchDto>? get clutch =>
      $value.clutch?.copyWith.$chain((v) => call(clutch: v));
  @override
  ListCopyWith<
    $R,
    TrailPointDto,
    TrailPointDtoCopyWith<$R, TrailPointDto, TrailPointDto>
  >
  get trail => ListCopyWith(
    $value.trail,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(trail: v),
  );
  @override
  ListCopyWith<$R, PlayerDto, PlayerDtoCopyWith<$R, PlayerDto, PlayerDto>>
  get players => ListCopyWith(
    $value.players,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(players: v),
  );
  @override
  ListCopyWith<$R, ScoreDto, ScoreDtoCopyWith<$R, ScoreDto, ScoreDto>>
  get scores => ListCopyWith(
    $value.scores,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(scores: v),
  );
  @override
  LobbyDtoCopyWith<$R, LobbyDto, LobbyDto> get lobby =>
      $value.lobby.copyWith.$chain((v) => call(lobby: v));
  @override
  GameInfoDtoCopyWith<$R, GameInfoDto, GameInfoDto> get game =>
      $value.game.copyWith.$chain((v) => call(game: v));
  @override
  ListCopyWith<
    $R,
    UserStatsDto,
    UserStatsDtoCopyWith<$R, UserStatsDto, UserStatsDto>
  >
  get leaderboard => ListCopyWith(
    $value.leaderboard,
    (v, t) => v.copyWith.$chain(t),
    (v) => call(leaderboard: v),
  );
  @override
  UserStatsDtoCopyWith<$R, UserStatsDto, UserStatsDto>? get yourStats =>
      $value.yourStats?.copyWith.$chain((v) => call(yourStats: v));
  @override
  $R call({
    String? type,
    YouDto? you,
    int? rows,
    int? cols,
    List<String>? maze,
    List<Vec2i>? bushes,
    List<Vec2i>? crackedWalls,
    CaveBiome? biome,
    int? stoneSeed,
    List<Vec2i>? crystals,
    List<Vec2i>? quicksand,
    List<Vec2i>? amethystWalls,
    List<Vec2i>? amethystShards,
    List<ChimeDto>? chimes,
    List<MushroomDto>? mushrooms,
    List<Vec2i>? spores,
    List<IllusionDto>? illusions,
    List<SarcophagusDto>? sarcophagi,
    List<MummyDto>? mummies,
    List<CaveBiome>? enabledBiomes,
    bool? sandboxMode,
    List<LogoDto>? logos,
    List<TrapDto>? traps,
    List<WebDto>? webs,
    List<BarrelDto>? barrels,
    List<PortalDto>? portals,
    List<MagicCrystalDto>? magicCrystals,
    List<MagicChainDto>? magicChains,
    Object? clutch = $none,
    List<TrailPointDto>? trail,
    List<PlayerDto>? players,
    List<ScoreDto>? scores,
    int? connectedPlayers,
    LobbyDto? lobby,
    GameInfoDto? game,
    String? status,
    List<UserStatsDto>? leaderboard,
    Object? yourStats = $none,
  }) => $apply(
    FieldCopyWithData({
      if (type != null) #type: type,
      if (you != null) #you: you,
      if (rows != null) #rows: rows,
      if (cols != null) #cols: cols,
      if (maze != null) #maze: maze,
      if (bushes != null) #bushes: bushes,
      if (crackedWalls != null) #crackedWalls: crackedWalls,
      if (biome != null) #biome: biome,
      if (stoneSeed != null) #stoneSeed: stoneSeed,
      if (crystals != null) #crystals: crystals,
      if (quicksand != null) #quicksand: quicksand,
      if (amethystWalls != null) #amethystWalls: amethystWalls,
      if (amethystShards != null) #amethystShards: amethystShards,
      if (chimes != null) #chimes: chimes,
      if (mushrooms != null) #mushrooms: mushrooms,
      if (spores != null) #spores: spores,
      if (illusions != null) #illusions: illusions,
      if (sarcophagi != null) #sarcophagi: sarcophagi,
      if (mummies != null) #mummies: mummies,
      if (enabledBiomes != null) #enabledBiomes: enabledBiomes,
      if (sandboxMode != null) #sandboxMode: sandboxMode,
      if (logos != null) #logos: logos,
      if (traps != null) #traps: traps,
      if (webs != null) #webs: webs,
      if (barrels != null) #barrels: barrels,
      if (portals != null) #portals: portals,
      if (magicCrystals != null) #magicCrystals: magicCrystals,
      if (magicChains != null) #magicChains: magicChains,
      if (clutch != $none) #clutch: clutch,
      if (trail != null) #trail: trail,
      if (players != null) #players: players,
      if (scores != null) #scores: scores,
      if (connectedPlayers != null) #connectedPlayers: connectedPlayers,
      if (lobby != null) #lobby: lobby,
      if (game != null) #game: game,
      if (status != null) #status: status,
      if (leaderboard != null) #leaderboard: leaderboard,
      if (yourStats != $none) #yourStats: yourStats,
    }),
  );
  @override
  GameSnapshotDto $make(CopyWithData data) => GameSnapshotDto(
    type: data.get(#type, or: $value.type),
    you: data.get(#you, or: $value.you),
    rows: data.get(#rows, or: $value.rows),
    cols: data.get(#cols, or: $value.cols),
    maze: data.get(#maze, or: $value.maze),
    bushes: data.get(#bushes, or: $value.bushes),
    crackedWalls: data.get(#crackedWalls, or: $value.crackedWalls),
    biome: data.get(#biome, or: $value.biome),
    stoneSeed: data.get(#stoneSeed, or: $value.stoneSeed),
    crystals: data.get(#crystals, or: $value.crystals),
    quicksand: data.get(#quicksand, or: $value.quicksand),
    amethystWalls: data.get(#amethystWalls, or: $value.amethystWalls),
    amethystShards: data.get(#amethystShards, or: $value.amethystShards),
    chimes: data.get(#chimes, or: $value.chimes),
    mushrooms: data.get(#mushrooms, or: $value.mushrooms),
    spores: data.get(#spores, or: $value.spores),
    illusions: data.get(#illusions, or: $value.illusions),
    sarcophagi: data.get(#sarcophagi, or: $value.sarcophagi),
    mummies: data.get(#mummies, or: $value.mummies),
    enabledBiomes: data.get(#enabledBiomes, or: $value.enabledBiomes),
    sandboxMode: data.get(#sandboxMode, or: $value.sandboxMode),
    logos: data.get(#logos, or: $value.logos),
    traps: data.get(#traps, or: $value.traps),
    webs: data.get(#webs, or: $value.webs),
    barrels: data.get(#barrels, or: $value.barrels),
    portals: data.get(#portals, or: $value.portals),
    magicCrystals: data.get(#magicCrystals, or: $value.magicCrystals),
    magicChains: data.get(#magicChains, or: $value.magicChains),
    clutch: data.get(#clutch, or: $value.clutch),
    trail: data.get(#trail, or: $value.trail),
    players: data.get(#players, or: $value.players),
    scores: data.get(#scores, or: $value.scores),
    connectedPlayers: data.get(#connectedPlayers, or: $value.connectedPlayers),
    lobby: data.get(#lobby, or: $value.lobby),
    game: data.get(#game, or: $value.game),
    status: data.get(#status, or: $value.status),
    leaderboard: data.get(#leaderboard, or: $value.leaderboard),
    yourStats: data.get(#yourStats, or: $value.yourStats),
  );

  @override
  GameSnapshotDtoCopyWith<$R2, GameSnapshotDto, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _GameSnapshotDtoCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

