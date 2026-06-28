import 'package:flutter_test/flutter_test.dart';
import 'package:game_helper/app/app.dart';

void main() {
  testWidgets(
    'GameHelperApp shows the dashboard start action',
    (WidgetTester tester) async {
      await tester.pumpWidget(const GameHelperApp());
      await tester.pumpAndSettle();

      expect(find.byType(GameHelperApp), findsOneWidget);
      expect(find.text('Game Helper Dashboard'), findsOneWidget);
      expect(find.text('Start Automation'), findsOneWidget);
    },
  );
}
