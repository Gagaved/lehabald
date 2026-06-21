import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leha_bald_client/src/ui/session_flow.dart';
import 'package:leha_bald_shared/leha_bald_shared.dart';

void main() {
  testWidgets('match score shows totals and active streak separately',
      (tester) async {
    final session = SessionStateDto(
      id: 's1',
      name: 'Test',
      phase: SessionPhase.playing,
      round: 8,
      players: const [
        MatchPlayerDto(
            id: 'a',
            name: 'Аня',
            role: PlayerRole.leha,
            roundWins: 4,
            pickLocked: true,
            rematch: false),
        MatchPlayerDto(
            id: 'b',
            name: 'Борис',
            role: PlayerRole.hunter,
            roundWins: 3,
            pickLocked: true,
            rematch: false),
      ],
      streakOwnerId: 'a',
      streakRole: PlayerRole.leha,
      history: const [],
      matchWinnerId: null,
      technical: false,
    );

    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MatchScore(session: session))));

    expect(find.text('Аня'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Борис'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Серия 1/2'), findsOneWidget);
    expect(find.text('Серия 0/2'), findsOneWidget);
  });
}
