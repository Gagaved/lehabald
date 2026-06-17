// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
// ignore_for_file: type=lint
// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'direction.dart';

class MoveDirectionMapper extends EnumMapper<MoveDirection> {
  MoveDirectionMapper._();

  static MoveDirectionMapper? _instance;
  static MoveDirectionMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = MoveDirectionMapper._());
    }
    return _instance!;
  }

  static MoveDirection fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  MoveDirection decode(dynamic value) {
    switch (value) {
      case r'up':
        return MoveDirection.up;
      case r'down':
        return MoveDirection.down;
      case r'left':
        return MoveDirection.left;
      case r'right':
        return MoveDirection.right;
      default:
        throw MapperException.unknownEnumValue(value);
    }
  }

  @override
  dynamic encode(MoveDirection self) {
    switch (self) {
      case MoveDirection.up:
        return r'up';
      case MoveDirection.down:
        return r'down';
      case MoveDirection.left:
        return r'left';
      case MoveDirection.right:
        return r'right';
    }
  }
}

extension MoveDirectionMapperExtension on MoveDirection {
  String toValue() {
    MoveDirectionMapper.ensureInitialized();
    return MapperContainer.globals.toValue<MoveDirection>(this) as String;
  }
}

