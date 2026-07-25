import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/segmented_tabs.dart';
import '../../domain/entities/body_measurement.dart';
import '../providers/progress_providers.dart';

enum _ProgressTab { weight, measurements }

class ProgressScreen extends HookConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = useState(_ProgressTab.weight);
    final measurementsAsync = ref.watch(bodyMeasurementsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            onPressed: () => context.push(RoutePaths.personalRecords),
          ),
          IconButton(
            icon: const Icon(Icons.photo_camera_outlined),
            onPressed: () => context.push(RoutePaths.progressPhotos),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedTabs<_ProgressTab>(
            selected: tab.value,
            onChanged: (v) => tab.value = v,
            options: const [
              SegmentedTabOption(value: _ProgressTab.weight, label: 'Weight'),
              SegmentedTabOption(value: _ProgressTab.measurements, label: 'Measurements'),
            ],
          ),
          const SizedBox(height: 20),
          AsyncValueWidget(
            value: measurementsAsync,
            onRetry: () => ref.invalidate(bodyMeasurementsProvider),
            data: (measurements) => tab.value == _ProgressTab.weight
                ? _WeightTab(measurements: measurements)
                : _MeasurementsTab(measurements: measurements),
          ),
        ],
      ),
    );
  }
}

class _WeightTab extends StatelessWidget {
  const _WeightTab({required this.measurements});
  final List<BodyMeasurement> measurements;

  @override
  Widget build(BuildContext context) {
    final withWeight = measurements.where((m) => m.weightKg != null).toList().reversed.toList();

    if (withWeight.isEmpty) {
      return Column(
        children: [
          const EmptyState(icon: Icons.monitor_weight_outlined, title: 'No weigh-ins yet'),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.push(RoutePaths.logMeasurement),
            child: const Text('+ Log Weight'),
          ),
        ],
      );
    }

    final current = withWeight.last.weightKg!;
    final delta = withWeight.first.weightKg! - current;

    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CURRENT', style: TextStyle(color: AppColors.darkTextTertiary, fontSize: 11)),
                      Text('${current.toStringAsFixed(1)}kg', style: Theme.of(context).textTheme.headlineSmall),
                    ],
                  ),
                  Text(
                    '${delta >= 0 ? "-" : "+"}${delta.abs().toStringAsFixed(1)}kg',
                    style: const TextStyle(color: AppColors.emerald, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        color: AppColors.electricBlue,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        spots: [
                          for (var i = 0; i < withWeight.length; i++)
                            FlSpot(i.toDouble(), withWeight[i].weightKg!),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => context.push(RoutePaths.logMeasurement),
          child: const Text('+ Log Weight'),
        ),
      ],
    );
  }
}

class _MeasurementsTab extends StatelessWidget {
  const _MeasurementsTab({required this.measurements});
  final List<BodyMeasurement> measurements;

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
      return Column(
        children: [
          const EmptyState(icon: Icons.straighten_outlined, title: 'No measurements yet'),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.push(RoutePaths.logMeasurement),
            child: const Text('+ Log measurement'),
          ),
        ],
      );
    }

    final latest = measurements.first;
    final previous = measurements.length > 1 ? measurements[1] : null;

    final rows = <(String, double?, double?)>[
      ('Chest', latest.chestCm, previous?.chestCm),
      ('Waist', latest.waistCm, previous?.waistCm),
      ('Hips', latest.hipsCm, previous?.hipsCm),
      ('Bicep', latest.bicepCm, previous?.bicepCm),
      ('Thigh', latest.thighCm, previous?.thighCm),
      ('Neck', latest.neckCm, previous?.neckCm),
    ].where((r) => r.$2 != null).toList();

    return Column(
      children: [
        for (final row in rows)
          AppCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(row.$1, style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 14)),
                Row(
                  children: [
                    Text(
                      '${row.$2!.toStringAsFixed(1)}cm',
                      style: const TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    if (row.$3 != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _delta(row.$2!, row.$3!),
                        style: const TextStyle(color: AppColors.emerald, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        OutlinedButton(
          onPressed: () => context.push(RoutePaths.logMeasurement),
          child: const Text('+ Log measurement'),
        ),
      ],
    );
  }

  String _delta(double current, double previous) {
    final diff = current - previous;
    final sign = diff >= 0 ? '+' : '';
    return '$sign${diff.toStringAsFixed(1)}';
  }
}
