import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironcoach/core/widgets/primary_button.dart';

void main() {
  testWidgets('shows a spinner and disables tap while loading', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Continue',
            isLoading: true,
            onPressed: () => tapCount++,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Continue'), findsNothing);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(tapCount, 0);
  });

  testWidgets('shows its label and responds to taps when not loading',
      (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            label: 'Continue',
            onPressed: () => tapCount++,
          ),
        ),
      ),
    );

    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    expect(tapCount, 1);
  });
}
