import 'package:flutter_test/flutter_test.dart';

import 'package:dreamjob/main.dart';

void main() {
  testWidgets('arranca en el splash y pasa al login', (WidgetTester tester) async {
    await tester.pumpWidget(const DreamJobApp());
    expect(find.text('dreamJob'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('LoginScreen'), findsOneWidget);
  });
}
