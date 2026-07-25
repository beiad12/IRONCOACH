import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/personal_record.dart';
import '../providers/progress_providers.dart';

class PersonalRecordsScreen extends ConsumerWidget {
  const PersonalRecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(personalRecordsProvider);
    final dateFormat = DateFormat('MMM d, y');

    return Scaffold(
      appBar: AppBar(title: const Text('Personal records')),
      body: AsyncValueWidget(
        value: recordsAsync,
        onRetry: () => ref.invalidate(personalRecordsProvider),
        data: (records) {
          if (records.isEmpty) {
            return const EmptyState(
                icon: Icons.emoji_events_outlined,
                title: 'No records yet — go lift!');
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            itemBuilder: (context, i) {
              final record = records[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.emoji_events, color: Colors.amber),
                  title: Text(record.exerciseName),
                  subtitle: Text(
                      '${record.recordType.label} · ${dateFormat.format(record.achievedAt)}'),
                  trailing: Text(
                    record.recordType == RecordType.maxReps
                        ? '${record.value.round()} reps'
                        : '${record.value.round()} kg',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
