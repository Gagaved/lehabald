import 'package:flutter_test/flutter_test.dart';
import 'package:leha_bald_client/main.dart';

void main() {
  test('uses localhost websocket by default', () {
    expect(defaultServerUrl(), 'ws://127.0.0.1:4173/ws');
  });
}
