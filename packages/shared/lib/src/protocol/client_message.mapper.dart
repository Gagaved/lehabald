// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'client_message.dart';

class ClientMessageTypeMapper extends EnumMapper<ClientMessageType> {
  ClientMessageTypeMapper._();

  static ClientMessageTypeMapper? _instance;
  static ClientMessageTypeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ClientMessageTypeMapper._());
    }
    return _instance!;
  }

  static ClientMessageType fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  ClientMessageType decode(dynamic value) {
    switch (value) {
      case r'input':
        return ClientMessageType.input;
      case r'stop':
        return ClientMessageType.stop;
      case r'selectRole':
        return ClientMessageType.selectRole;
      case r'ready':
        return ClientMessageType.ready;
      case r'spectate':
        return ClientMessageType.spectate;
      case r'placeTrap':
        return ClientMessageType.placeTrap;
      case r'useAbility':
        return ClientMessageType.useAbility;
      case r'selectAspect':
        return ClientMessageType.selectAspect;
      case r'restart':
        return ClientMessageType.restart;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(ClientMessageType self) {
    switch (self) {
      case ClientMessageType.input:
        return r'input';
      case ClientMessageType.stop:
        return r'stop';
      case ClientMessageType.selectRole:
        return r'selectRole';
      case ClientMessageType.ready:
        return r'ready';
      case ClientMessageType.spectate:
        return r'spectate';
      case ClientMessageType.placeTrap:
        return r'placeTrap';
      case ClientMessageType.useAbility:
        return r'useAbility';
      case ClientMessageType.selectAspect:
        return r'selectAspect';
      case ClientMessageType.restart:
        return r'restart';
    }
  }
}

extension ClientMessageTypeMapperExtension on ClientMessageType {
  String toValue() {
    ClientMessageTypeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<ClientMessageType>(this) as String;
  }
}

class ClientMessageMapper extends ClassMapperBase<ClientMessage> {
  ClientMessageMapper._();

  static ClientMessageMapper? _instance;
  static ClientMessageMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = ClientMessageMapper._());
      ClientMessageTypeMapper.ensureInitialized();
      MoveDirectionMapper.ensureInitialized();
      PlayerRoleMapper.ensureInitialized();
      LehaAspectMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'ClientMessage';

  static ClientMessageType _$type(ClientMessage v) => v.type;
  static const Field<ClientMessage, ClientMessageType> _f$type = Field(
    'type',
    _$type,
  );
  static MoveDirection? _$direction(ClientMessage v) => v.direction;
  static const Field<ClientMessage, MoveDirection> _f$direction = Field(
    'direction',
    _$direction,
    opt: true,
  );
  static PlayerRole? _$role(ClientMessage v) => v.role;
  static const Field<ClientMessage, PlayerRole> _f$role = Field(
    'role',
    _$role,
    opt: true,
  );
  static LehaAspect? _$aspect(ClientMessage v) => v.aspect;
  static const Field<ClientMessage, LehaAspect> _f$aspect = Field(
    'aspect',
    _$aspect,
    opt: true,
  );
  static bool? _$ready(ClientMessage v) => v.ready;
  static const Field<ClientMessage, bool> _f$ready = Field(
    'ready',
    _$ready,
    opt: true,
  );

  @override
  final MappableFields<ClientMessage> fields = const {
    #type: _f$type,
    #direction: _f$direction,
    #role: _f$role,
    #aspect: _f$aspect,
    #ready: _f$ready,
  };

  static ClientMessage _instantiate(DecodingData data) {
    return ClientMessage(
      type: data.dec(_f$type),
      direction: data.dec(_f$direction),
      role: data.dec(_f$role),
      aspect: data.dec(_f$aspect),
      ready: data.dec(_f$ready),
    );
  }

  @override
  final Function instantiate = _instantiate;

  static ClientMessage fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<ClientMessage>(map);
  }

  static ClientMessage fromJson(String json) {
    return ensureInitialized().decodeJson<ClientMessage>(json);
  }
}

mixin ClientMessageMappable {
  String toJson() {
    return ClientMessageMapper.ensureInitialized().encodeJson<ClientMessage>(
      this as ClientMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return ClientMessageMapper.ensureInitialized().encodeMap<ClientMessage>(
      this as ClientMessage,
    );
  }

  ClientMessageCopyWith<ClientMessage, ClientMessage, ClientMessage>
  get copyWith => _ClientMessageCopyWithImpl<ClientMessage, ClientMessage>(
    this as ClientMessage,
    $identity,
    $identity,
  );
  @override
  String toString() {
    return ClientMessageMapper.ensureInitialized().stringifyValue(
      this as ClientMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    return ClientMessageMapper.ensureInitialized().equalsValue(
      this as ClientMessage,
      other,
    );
  }

  @override
  int get hashCode {
    return ClientMessageMapper.ensureInitialized().hashValue(
      this as ClientMessage,
    );
  }
}

extension ClientMessageValueCopy<$R, $Out>
    on ObjectCopyWith<$R, ClientMessage, $Out> {
  ClientMessageCopyWith<$R, ClientMessage, $Out> get $asClientMessage =>
      $base.as((v, t, t2) => _ClientMessageCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class ClientMessageCopyWith<$R, $In extends ClientMessage, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  $R call({
    ClientMessageType? type,
    MoveDirection? direction,
    PlayerRole? role,
    LehaAspect? aspect,
    bool? ready,
  });
  ClientMessageCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _ClientMessageCopyWithImpl<$R, $Out>
    extends ClassCopyWithBase<$R, ClientMessage, $Out>
    implements ClientMessageCopyWith<$R, ClientMessage, $Out> {
  _ClientMessageCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<ClientMessage> $mapper =
      ClientMessageMapper.ensureInitialized();
  @override
  $R call({
    ClientMessageType? type,
    Object? direction = $none,
    Object? role = $none,
    Object? aspect = $none,
    Object? ready = $none,
  }) => $apply(
    FieldCopyWithData({
      if (type != null) #type: type,
      if (direction != $none) #direction: direction,
      if (role != $none) #role: role,
      if (aspect != $none) #aspect: aspect,
      if (ready != $none) #ready: ready,
    }),
  );
  @override
  ClientMessage $make(CopyWithData data) => ClientMessage(
    type: data.get(#type, or: $value.type),
    direction: data.get(#direction, or: $value.direction),
    role: data.get(#role, or: $value.role),
    aspect: data.get(#aspect, or: $value.aspect),
    ready: data.get(#ready, or: $value.ready),
  );

  @override
  ClientMessageCopyWith<$R2, ClientMessage, $Out2> $chain<$R2, $Out2>(
    Then<$Out2, $R2> t,
  ) => _ClientMessageCopyWithImpl<$R2, $Out2>($value, $cast, t);
}

