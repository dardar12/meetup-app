import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chinese_talk/main.dart';

void main() {
  testWidgets('HSK 1 App Home Screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: HSKClassHomePage()));

    // Verify that our HSK 1 title is found.
    expect(find.text('HSK 1 Video Class (တရုတ်စာ အတန်း)'), findsOneWidget);

    // Verify that the Join button is found.
    expect(find.text('Join Class (အတန်းသို့ဝင်မည်)'), findsOneWidget);
  });
}