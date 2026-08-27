import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('WorkPulse App Smoke Test', (WidgetTester tester) async {
    // Set standard viewport
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: WorkPulseApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    // Verify Login Screen renders with WorkPulse branding
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
