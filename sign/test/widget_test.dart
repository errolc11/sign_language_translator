import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign/main.dart';

void main() {
  testWidgets('Home screen displays "Basic Signs" title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the home screen shows the "Basic Signs" title.
    expect(find.text('Basic Signs'), findsOneWidget);
  });
}
