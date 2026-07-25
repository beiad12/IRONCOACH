import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../providers/workout_providers.dart';
import '../widgets/exercise_card.dart';

class ExerciseLibraryScreen extends HookConsumerWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final query = useState('');
    final category = useState<ExerciseCategory?>(null);
    final favoritesOnly = useState(false);

    final filter = ExerciseFilter(
      query: query.value,
      category: category.value,
      favoritesOnly: favoritesOnly.value,
    );
    final exercisesAsync = ref.watch(exerciseListProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise library'),
        actions: [
          IconButton(
            icon: Icon(
                favoritesOnly.value ? Icons.favorite : Icons.favorite_border),
            onPressed: () => favoritesOnly.value = !favoritesOnly.value,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: 'Search exercises',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => query.value = v,
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                    label: 'All',
                    selected: category.value == null,
                    onTap: () => category.value = null),
                for (final c in ExerciseCategory.values)
                  _CategoryChip(
                    label: c.name[0].toUpperCase() + c.name.substring(1),
                    selected: category.value == c,
                    onTap: () => category.value = c,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: AsyncValueWidget(
              value: exercisesAsync,
              onRetry: () => ref.invalidate(exerciseListProvider),
              data: (exercises) {
                if (exercises.isEmpty) {
                  return const EmptyState(
                      icon: Icons.search_off, title: 'No exercises found');
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: exercises.length,
                  itemBuilder: (context, i) {
                    final exercise = exercises[i];
                    return ExerciseCard(
                      exercise: exercise,
                      onTap: () => context.push(
                        RoutePaths.exerciseLibrary + '/${exercise.id}',
                      ),
                      onFavoriteToggle: () => ref
                          .read(exerciseRepositoryProvider)
                          .toggleFavorite(exercise.id,
                              isFavorite: !exercise.isFavorite)
                          .then((_) => ref.invalidate(exerciseListProvider)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
          label: Text(label), selected: selected, onSelected: (_) => onTap()),
    );
  }
}
