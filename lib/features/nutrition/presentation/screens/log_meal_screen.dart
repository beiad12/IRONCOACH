import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/gradient_button.dart';
import '../../../ai_coach/presentation/providers/ai_coach_providers.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/meal_entry.dart';
import '../providers/nutrition_providers.dart';

class LogMealScreen extends HookConsumerWidget {
  const LogMealScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealType = useState(MealType.breakfast);
    final searchController = useTextEditingController();
    final searchResults = useState<List<FoodItem>>([]);
    final cart = useState<List<MealEntryItem>>([]);
    final photo = useState<File?>(null);
    final isBusy = useState(false);

    Future<void> search(String query) async {
      if (query.trim().isEmpty) {
        searchResults.value = [];
        return;
      }
      final result = await ref.read(nutritionRepositoryProvider).searchFoodItems(query);
      result.match((_) {}, (items) => searchResults.value = items);
    }

    void addToCart(FoodItem item) {
      cart.value = [
        ...cart.value,
        MealEntryItem(
          id: '',
          foodItem: item,
          quantity: 1,
          calories: item.caloriesPerServing,
          proteinG: item.proteinG,
          carbsG: item.carbsG,
          fatG: item.fatG,
        ),
      ];
    }

    Future<void> pickPhoto() async {
      final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80);
      if (picked == null) return;
      photo.value = File(picked.path);

      isBusy.value = true;
      final result = await ref.read(aiRepositoryProvider).analyzeMealPhoto(imageFile: photo.value!);
      isBusy.value = false;
      result.match(
        (failure) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(failure.displayMessage)));
          }
        },
        (analysis) {
          addToCart(
            FoodItem(
              id: '',
              name: analysis.foodName,
              caloriesPerServing: analysis.estimatedCalories,
              proteinG: analysis.proteinG,
              carbsG: analysis.carbsG,
              fatG: analysis.fatG,
            ),
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Estimated from photo: ${analysis.notes}')),
            );
          }
        },
      );
    }

    Future<void> save() async {
      if (cart.value.isEmpty) return;
      isBusy.value = true;
      final result = await ref.read(nutritionRepositoryProvider).logMeal(
            mealType: mealType.value,
            items: cart.value,
          );
      isBusy.value = false;
      if (!context.mounted) return;
      result.match(
        (failure) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.displayMessage))),
        (_) {
          ref.invalidate(mealsForDateProvider);
          ref.invalidate(dailyNutritionSummaryControllerProvider);
          context.pop();
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log a meal'),
        actions: [IconButton(icon: const Icon(Icons.camera_alt_outlined), onPressed: pickPhoto)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: MealType.values
                  .map(
                    (type) => ChoiceChip(
                      label: Text(type.label),
                      selected: mealType.value == type,
                      onSelected: (_) => mealType.value = type,
                    ),
                  )
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(hintText: 'Search foods', prefixIcon: Icon(Icons.search)),
              onChanged: search,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final item in searchResults.value)
                  ListTile(
                    title: Text(item.name),
                    subtitle: Text('${item.caloriesPerServing.round()} kcal / serving'),
                    trailing: IconButton(icon: const Icon(Icons.add), onPressed: () => addToCart(item)),
                  ),
                if (cart.value.isNotEmpty) ...[
                  const Divider(),
                  Text('Added items', style: Theme.of(context).textTheme.titleSmall),
                  for (final item in cart.value)
                    ListTile(
                      title: Text(item.foodItem.name),
                      subtitle: Text('${item.calories.round()} kcal'),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => cart.value = cart.value.where((i) => i != item).toList(),
                      ),
                    ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GradientButton(label: 'Save meal', isLoading: isBusy.value, onPressed: save),
          ),
        ],
      ),
    );
  }
}
