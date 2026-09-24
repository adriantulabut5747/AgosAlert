import 'package:flutter_test/flutter_test.dart';

import 'package:agosalert/main.dart';

void main() {
  testWidgets('App starts on the login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AgosAlertApp());
    // pump() not pumpAndSettle(): the logo glow animation repeats forever,
    // so the app never "settles".
    await tester.pump();

    expect(find.text('Login to your account'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
