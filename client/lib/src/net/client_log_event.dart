enum ClientLogCategory {
  connection('Соединение'),
  network('Сеть'),
  performance('Производительность'),
  protocol('Протокол'),
  gameplay('Игра'),
  diagnostic('Диагностика');

  const ClientLogCategory(this.label);
  final String label;
}

/// Typed base object for every entry shown in the client console.
sealed class ClientLogEvent {
  const ClientLogEvent({
    required this.timestamp,
    required this.event,
    required this.fields,
  });

  final DateTime timestamp;
  final String event;
  final Map<String, Object?> fields;
  ClientLogCategory get category;

  String get formatted {
    final time = timestamp.toIso8601String().substring(11, 23);
    final suffix = fields.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
    return suffix.isEmpty ? '$time $event' : '$time $event $suffix';
  }

  static ClientLogEvent create(
    String event, [
    Map<String, Object?> fields = const {},
  ]) {
    final args = (timestamp: DateTime.now(), event: event, fields: fields);
    if (event.contains('connect') || event.contains('watchdog')) {
      return ConnectionLogEvent(
          timestamp: args.timestamp, event: event, fields: fields);
    }
    if (event.contains('snapshot') || event.contains('ping')) {
      return NetworkLogEvent(
          timestamp: args.timestamp, event: event, fields: fields);
    }
    if (event.contains('render') || event.contains('motion')) {
      return PerformanceLogEvent(
          timestamp: args.timestamp, event: event, fields: fields);
    }
    if (event.contains('protocol') || event.contains('error')) {
      return ProtocolLogEvent(
          timestamp: args.timestamp, event: event, fields: fields);
    }
    if (event.contains('game') || event.contains('ability')) {
      return GameplayLogEvent(
          timestamp: args.timestamp, event: event, fields: fields);
    }
    return DiagnosticLogEvent(
        timestamp: args.timestamp, event: event, fields: fields);
  }
}

final class ConnectionLogEvent extends ClientLogEvent {
  const ConnectionLogEvent(
      {required super.timestamp, required super.event, required super.fields});
  @override
  ClientLogCategory get category => ClientLogCategory.connection;
}

final class NetworkLogEvent extends ClientLogEvent {
  const NetworkLogEvent(
      {required super.timestamp, required super.event, required super.fields});
  @override
  ClientLogCategory get category => ClientLogCategory.network;
}

final class PerformanceLogEvent extends ClientLogEvent {
  const PerformanceLogEvent(
      {required super.timestamp, required super.event, required super.fields});
  @override
  ClientLogCategory get category => ClientLogCategory.performance;
}

final class ProtocolLogEvent extends ClientLogEvent {
  const ProtocolLogEvent(
      {required super.timestamp, required super.event, required super.fields});
  @override
  ClientLogCategory get category => ClientLogCategory.protocol;
}

final class GameplayLogEvent extends ClientLogEvent {
  const GameplayLogEvent(
      {required super.timestamp, required super.event, required super.fields});
  @override
  ClientLogCategory get category => ClientLogCategory.gameplay;
}

final class DiagnosticLogEvent extends ClientLogEvent {
  const DiagnosticLogEvent(
      {required super.timestamp, required super.event, required super.fields});
  @override
  ClientLogCategory get category => ClientLogCategory.diagnostic;
}
