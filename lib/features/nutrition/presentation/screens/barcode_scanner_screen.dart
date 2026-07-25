import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/entities/meal_entry.dart';
import '../providers/nutrition_providers.dart';

class BarcodeScannerScreen extends HookConsumerWidget {
  const BarcodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan a barcode')),
      body: MobileScanner(
        onDetect: (capture) async {
          final barcode = capture.barcodes.firstOrNull?.rawValue;
          if (barcode == null) return;

          final result = await ref
              .read(nutritionRepositoryProvider)
              .lookupBarcode(barcode);
          if (!context.mounted) return;

          result.match(
            (failure) => ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(failure.displayMessage))),
            (item) {
              if (item == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product not found')));
                return;
              }
              showModalBottomSheet<void>(
                context: context,
                builder: (sheetContext) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: Theme.of(sheetContext).textTheme.titleLarge),
                      if (item.brand != null) Text(item.brand!),
                      const SizedBox(height: 8),
                      Text('${item.caloriesPerServing.round()} kcal / serving'),
                      Text(
                          'P ${item.proteinG.round()}g · C ${item.carbsG.round()}g · F ${item.fatG.round()}g'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () async {
                          final logResult = await ref
                              .read(nutritionRepositoryProvider)
                              .logMeal(
                            mealType: MealType.snack,
                            items: [
                              MealEntryItem(
                                id: '',
                                foodItem: item,
                                quantity: 1,
                                calories: item.caloriesPerServing,
                                proteinG: item.proteinG,
                                carbsG: item.carbsG,
                                fatG: item.fatG,
                              ),
                            ],
                          );
                          if (!sheetContext.mounted) return;
                          logResult.match(
                            (failure) => ScaffoldMessenger.of(sheetContext)
                                .showSnackBar(SnackBar(
                                    content: Text(failure.displayMessage))),
                            (_) {
                              ref.invalidate(mealsForDateProvider);
                              ref.invalidate(
                                  dailyNutritionSummaryControllerProvider);
                              Navigator.pop(sheetContext);
                              context.pop();
                            },
                          );
                        },
                        child: const Text('Log this item'),
                      ),
                    ],
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
