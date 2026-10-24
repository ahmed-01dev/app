import 'package:flutter_test/flutter_test.dart';
import 'package:fajr/app.dart';

void main() {
  testWidgets('Fajr app starts successfully in local mode', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FajrApp(isLocalMode: true));

    expect(find.text('فَجْر'), findsOneWidget);
  });
}
