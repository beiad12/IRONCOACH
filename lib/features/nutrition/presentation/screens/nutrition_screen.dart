import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../domain/entities/meal_entry.dart';
import '../providers/nutrition_providers.dart';
import '../widgets/calorie_ring.dart';
import '../widgets/macro_bar.dart';

class NutritionScreen extends ConsumerWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final normalizedDate = DateTime(today.year, today.month, today.day);
    final summaryAsync = ref.watch(dailyNutritionSummaryControllerProvider(normalizedDate));
    final mealsAsync = ref.watch(mealsForDateProvider(normalizedDate));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push(RoutePaths.barcodeScanner),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dailyNutritionSummaryControllerProvider);
          ref.invalidate(mealsForDateProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AsyncValueWidget(
              value: summaryAsync,
              data: (summary) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CalorieRing(consumed: summary.calories, goal: summary.goals.calories),
                      const SizedBox(height: 20),
                      MacroBar(
                        label: 'Protein',
                        consumedG: summary.proteinG,
                        goalG: summary.goals.proteinG,
                        color: AppColors.protein,
                      ),
                      const SizedBox(height: 10),
                      MacroBar(
                        label: 'Carbs',
                        consumedG: summary.carbsG,
                        goalG: summary.goals.carbsG,
                        color: AppColors.carbs,
                      ),
                      const SizedBox(height: 10),
                      MacroBar(
                        label: 'Fat',
                        consumedG: summary.fatG,
                        goalG: summary.goals.fatG,
                        color: AppColors.fat,
                      ),
                      const SizedBox(height: 16),
                      _WaterRow(consumedMl: summary.waterMl, goalMl: summary.goals.waterMl),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Today's meals", style: Theme.of(context).textTheme.titleMedium),
                FilledButton.tonalIcon(
                  onPressed: () => context.push(RoutePaths.logMeal),
                  icon: const Icon(Icons.add),
                  label: const Text('Log meal'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AsyncValueWidget(
              value: mealsAsync,
              data: (meals) => Column(children: meals.map((m) => _MealTile(meal: m)).toList()),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterRow extends ConsumerWidget {
  const _WaterRow({required this.consumedMl, required this.goalMl});
  final int consumedMl;
  final int goalMl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Icon(Icons.water_drop, color: AppColors.water),
        const SizedBox(width: 8),
        Expanded(child: Text('$consumedMl / $goalMl ml', style: Theme.of(context).textTheme.bodyMedium)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () async {
            final today = DateTime.now();
            await ref.read(nutritionRepositoryProvider).logWater(250);
            ref.invalidate(waterForDateProvider(DateTime(today.year, today.month, today.day)));
          },
        ),
      ],
    );
  }
}

class _MealTile extends StatelessWidget {
  const _MealTile({required this.meal});
  final MealEntry meal;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(meal.mealType.label[0])),
        title: Text(meal.mealType.label),
        subtitle: Text('${meal.totalCalories.round()} kcal · ${meal.items.length} items'),
      ),
    );
  }
}
