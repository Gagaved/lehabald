import 'package:flutter_test/flutter_test.dart';
import 'package:leha_bald_client/src/net/client_log_event.dart';

void main() {
  test('client logs are typed and classified by event family', () {
    expect(ClientLogEvent.create('connect'), isA<ConnectionLogEvent>());
    expect(ClientLogEvent.create('snapshot-gap'), isA<NetworkLogEvent>());
    expect(ClientLogEvent.create('render-stats'), isA<PerformanceLogEvent>());
    expect(ClientLogEvent.create('protocol-error'), isA<ProtocolLogEvent>());
    expect(ClientLogEvent.create('game-finished'), isA<GameplayLogEvent>());
    expect(ClientLogEvent.create('custom'), isA<DiagnosticLogEvent>());
  });

  test('formatted log retains structured fields', () {
    final event = ClientLogEvent.create('ping', {'ms': 17});

    expect(event.category, ClientLogCategory.network);
    expect(event.fields, {'ms': 17});
    expect(event.formatted, contains('ping ms=17'));
  });
}
