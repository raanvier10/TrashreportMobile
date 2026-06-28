// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trashreport_mobile/main.dart';
import 'package:trashreport_mobile/features/auth/screens/login_screen.dart';

void main() {
  testWidgets('App should load LoginScreen by default', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Berikan initialScreen berupa LoginScreen untuk testing
    await tester.pumpWidget(MyApp());

    // Verify bahwa tulisan 'TrashReport Mobile' (yang ada di LoginScreen) muncul
    expect(find.text('TrashReport Mobile'), findsOneWidget);
  });
}
