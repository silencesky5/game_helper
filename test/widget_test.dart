import 'package:flutter_test/flutter_test.dart';
import 'package:game_helper/app/app.dart';

void main() {
  testWidgets(
    'GameHelperApp shows the desktop console and device session cards',
    (WidgetTester tester) async {
      await tester.pumpWidget(const GameHelperApp());
      await tester.pumpAndSettle();

      expect(find.byType(GameHelperApp), findsOneWidget);
      expect(find.text('Game Helper Desktop Console'), findsOneWidget);
      expect(find.text('Device Sessions'), findsOneWidget);
      expect(find.text('Start Automation'), findsOneWidget);
      expect(find.textContaining('Session 1'), findsOneWidget);
      expect(find.textContaining('Current Plugin'), findsWidgets);
      expect(find.textContaining('Current Workflow'), findsWidgets);
    },
  );
}
