import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/progress_providers.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final measurementsAsync = ref.watch(bodyMeasurementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () => context.push(RoutePaths.logMeasurement),
                  child: const Text('Log measurement'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push(RoutePaths.progressPhotos),
                  child: const Text('Photos'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.push(RoutePaths.personalRecords),
            child: const Text('Personal records'),
          ),
          const SizedBox(height: 24),
          Text('Body weight', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: AsyncValueWidget(
              value: measurementsAsync,
              onRetry: () => ref.invalidate(bodyMeasurementsProvider),
              data: (measurements) {
                final withWeight = measurements.where((m) => m.weightKg != null).toList().reversed.toList();
                if (withWeight.isEmpty) {
                  return const EmptyState(icon: Icons.monitor_weight_outlined, title: 'No weigh-ins yet');
                }
                return LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: Theme.of(context).colorScheme.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        spots: [
                          for (var i = 0; i < withWeight.length; i++)
                            FlSpot(i.toDouble(), withWeight[i].weightKg!),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
