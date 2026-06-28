import 'package:flutter_test/flutter_test.dart';
import 'package:game_helper/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'GameHelperApp shows the localized desktop console',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      await tester.pumpWidget(const GameHelperApp());
      await tester.pumpAndSettle();

      expect(find.byType(GameHelperApp), findsOneWidget);
      expect(find.text('Game Helper 桌面控制台'), findsOneWidget);
      expect(find.text('裝置工作階段'), findsOneWidget);
      expect(find.text('開始自動化'), findsOneWidget);
      expect(find.text('語言'), findsOneWidget);
    },
  );
}
