import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironcoach/core/widgets/empty_state.dart';

void main() {
  testWidgets('renders title, optional message, and action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.fitness_center,
            title: 'No workouts yet',
            message: 'Generate one to get started.',
            action: const Text('Generate'),
          ),
        ),
      ),
    );

    expect(find.text('No workouts yet'), findsOneWidget);
    expect(find.text('Generate one to get started.'), findsOneWidget);
    expect(find.text('Generate'), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);
  });
}
