import 'src/protocol/client_message.dart';
import 'src/protocol/direction.dart';
import 'src/protocol/game_snapshot.dart';
import 'src/protocol/game_types.dart';

export 'src/protocol/client_message.dart';
export 'src/protocol/direction.dart';
export 'src/protocol/game_snapshot.dart';
export 'src/protocol/game_types.dart';

void ensureProtocolMappersInitialized() {
  MoveDirectionMapper.ensureInitialized();
  PlayerRoleMapper.ensureInitialized();
  LehaAspectMapper.ensureInitialized();
  GamePhaseMapper.ensureInitialized();
  Vec2iMapper.ensureInitialized();
  Vec2dMapper.ensureInitialized();
  ClientMessageTypeMapper.ensureInitialized();
  ClientMessageMapper.ensureInitialized();
  PlayerDtoMapper.ensureInitialized();
  LogoDtoMapper.ensureInitialized();
  TrapDtoMapper.ensureInitialized();
  WebDtoMapper.ensureInitialized();
  PortalDtoMapper.ensureInitialized();
  TrailPointDtoMapper.ensureInitialized();
  ScoreDtoMapper.ensureInitialized();
  RoleStateDtoMapper.ensureInitialized();
  LobbyDtoMapper.ensureInitialized();
  GameInfoDtoMapper.ensureInitialized();
  YouDtoMapper.ensureInitialized();
  GameSnapshotDtoMapper.ensureInitialized();
}
