// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:shopping_list_app/main.dart';

void main() {
  testWidgets('App starts and shows either Login or Home', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(milliseconds: 1));

    final login = find.text('Login');
    final home = find.text('Home');
    expect(login.evaluate().isNotEmpty || home.evaluate().isNotEmpty, true);
  });
}
