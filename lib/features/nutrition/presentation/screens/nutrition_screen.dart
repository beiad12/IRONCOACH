import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/segmented_tabs.dart';
import '../../domain/entities/meal_entry.dart';
import '../../domain/entities/nutrition_goals.dart';
import '../providers/nutrition_providers.dart';
import '../widgets/calorie_ring.dart';

enum _NutritionTab { tracker, calories, scanner }

class NutritionScreen extends HookConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = useState(_NutritionTab.tracker);
    final today = DateTime.now();
    final normalizedDate = DateTime(today.year, today.month, today.day);
    final summaryAsync = ref.watch(dailyNutritionSummaryControllerProvider(normalizedDate));
    final mealsAsync = ref.watch(mealsForDateProvider(normalizedDate));

    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailyNutritionSummaryControllerProvider);
          ref.invalidate(mealsForDateProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SegmentedTabs<_NutritionTab>(
              selected: tab.value,
              onChanged: (v) => tab.value = v,
              options: const [
                SegmentedTabOption(value: _NutritionTab.tracker, label: 'Tracker'),
                SegmentedTabOption(value: _NutritionTab.calories, label: 'Calories'),
                SegmentedTabOption(value: _NutritionTab.scanner, label: 'Scanner'),
              ],
            ),
            const SizedBox(height: 20),
            switch (tab.value) {
              _NutritionTab.tracker => _TrackerTab(mealsAsync: mealsAsync, summaryAsync: summaryAsync),
              _NutritionTab.calories => AsyncValueWidget(
                  value: summaryAsync,
                  data: (summary) => _CaloriesTab(summary: summary),
                ),
              _NutritionTab.scanner => const _ScannerTab(),
            },
          ],
        ),
      ),
    );
  }
}

class _TrackerTab extends ConsumerWidget {
  const _TrackerTab({required this.mealsAsync, required this.summaryAsync});
  final AsyncValue<List<MealEntry>> mealsAsync;
  final AsyncValue<DailyNutritionSummary> summaryAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        summaryAsync.when(
          data: (summary) => AppCard(
            child: Row(
              children: [
                const Icon(Icons.water_drop, color: AppColors.water),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${summary.waterMl} / ${summary.goals.waterMl} ml',
                    style: const TextStyle(color: AppColors.darkTextPrimary, fontSize: 13),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.water),
                  onPressed: () async {
                    final today = DateTime.now();
                    await ref.read(nutritionRepositoryProvider).logWater(250);
                    ref.invalidate(waterForDateProvider(DateTime(today.year, today.month, today.day)));
                  },
                ),
              ],
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Today's meals", style: Theme.of(context).textTheme.titleMedium),
            TextButton.icon(
              onPressed: () => context.push(RoutePaths.logMeal),
              icon: const Icon(Icons.add),
              label: const Text('Log meal'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AsyncValueWidget(
          value: mealsAsync,
          data: (meals) {
            if (meals.isEmpty) {
              return const EmptyState(icon: Icons.restaurant_outlined, title: 'No meals logged yet');
            }
            return Column(children: meals.map((m) => _MealTile(meal: m)).toList());
          },
        ),
      ],
    );
  }
}

class _CaloriesTab extends StatelessWidget {
  const _CaloriesTab({required this.summary});
  final DailyNutritionSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(child: CalorieRing(consumed: summary.calories, goal: summary.goals.calories)),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _MacroStat(
                label: 'Protein',
                value: '${summary.proteinG.round()}g',
                color: AppColors.protein,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MacroStat(label: 'Carbs', value: '${summary.carbsG.round()}g', color: AppColors.carbs),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MacroStat(label: 'Fat', value: '${summary.fatG.round()}g', color: AppColors.fat),
            ),
          ],
        ),
      ],
    );
  }
}

class _MacroStat extends StatelessWidget {
  const _MacroStat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 10, letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }
}

class _ScannerTab extends StatelessWidget {
  const _ScannerTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 260,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.darkBorder, width: 2),
            borderRadius: BorderRadius.circular(20),
            color: AppColors.darkTrack,
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_camera_outlined, size: 36, color: AppColors.darkTextTertiary),
                SizedBox(height: 12),
                Text('point camera at meal', style: TextStyle(color: AppColors.darkTextTertiary, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GradientButton(label: 'Scan Meal', onPressed: () => context.push(RoutePaths.barcodeScanner)),
      ],
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({required this.meal});
  final MealEntry meal;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.electricBlue.withValues(alpha: 0.15),
            child: Text(meal.mealType.label[0], style: const TextStyle(color: AppColors.electricBlue)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.mealType.label, style: const TextStyle(color: AppColors.darkTextPrimary, fontWeight: FontWeight.w600)),
                Text(
                  '${meal.items.length} items',
                  style: const TextStyle(color: AppColors.darkTextTertiary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${meal.totalCalories.round()} kcal',
            style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
