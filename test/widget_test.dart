import 'package:flutter_test/flutter_test.dart';

import 'package:scrambled_tts_app/main.dart';

void main() {
  testWidgets('Home screen renders title and start button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ScrambleCapstoneApp());
    await tester.pumpAndSettle();

    // Verify the app title is visible.
    expect(find.text('Scramble'), findsOneWidget);

    // Verify the Start button exists.
    expect(find.text('Start'), findsOneWidget);

    // Verify the How to Play button exists.
    expect(find.text('How to Play'), findsOneWidget);
  });
}
