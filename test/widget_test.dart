import 'package:flutter_test/flutter_test.dart';
import 'package:game_helper/app/app.dart';

void main() {
  testWidgets(
    'GameHelperApp shows installed plugins',
    (WidgetTester tester) async {
      await tester.pumpWidget(const GameHelperApp());
      await tester.pumpAndSettle();

      expect(find.byType(GameHelperApp), findsOneWidget);
      expect(find.text('Installed Plugins'), findsOneWidget);
      expect(find.text('Mine Journey'), findsOneWidget);
      expect(find.text('Version 1.0'), findsOneWidget);
      expect(find.text('Enabled'), findsOneWidget);
    },
  );
}
