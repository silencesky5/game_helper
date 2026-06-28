import 'package:flutter_test/flutter_test.dart';
import 'package:game_helper/app/app.dart';

void main() {
  testWidgets('GameHelperApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GameHelperApp());

    expect(find.byType(GameHelperApp), findsOneWidget);
  });
}
