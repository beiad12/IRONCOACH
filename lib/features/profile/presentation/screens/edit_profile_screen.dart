import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_providers.dart';

class EditProfileScreen extends HookConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: AsyncValueWidget(
        value: profileAsync,
        data: (profile) => profile == null
            ? const SizedBox.shrink()
            : _EditForm(profile: profile),
      ),
    );
  }
}

class _EditForm extends HookConsumerWidget {
  const _EditForm({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usernameController = useTextEditingController(text: profile.username);
    final displayNameController = useTextEditingController(text: profile.displayName);
    final bioController = useTextEditingController(text: profile.bio);
    final heightController = useTextEditingController(text: profile.heightCm?.toString() ?? '');
    final weightController = useTextEditingController(text: profile.weightKg?.toString() ?? '');
    final isPublic = useState(profile.isPublic);
    final fitnessLevel = useState(profile.fitnessLevel);
    final primaryGoal = useState(profile.primaryGoal);
    final units = useState(profile.units);
    final isSaving = useState(false);

    Future<void> save() async {
      isSaving.value = true;
      final result = await ref.read(profileRepositoryProvider).updateProfile(
            profile.copyWith(
              username: usernameController.text.trim(),
              displayName: displayNameController.text.trim(),
              bio: bioController.text.trim(),
              heightCm: double.tryParse(heightController.text),
              weightKg: double.tryParse(weightController.text),
              isPublic: isPublic.value,
              fitnessLevel: fitnessLevel.value,
              primaryGoal: primaryGoal.value,
              units: units.value,
            ),
          );
      isSaving.value = false;
      if (!context.mounted) return;
      result.match(
        (failure) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.displayMessage))),
        (_) {
          ref.invalidate(myProfileProvider);
          context.pop();
        },
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(label: 'Username', controller: usernameController, prefixIcon: Icons.alternate_email),
          const SizedBox(height: 16),
          AppTextField(label: 'Display name', controller: displayNameController),
          const SizedBox(height: 16),
          AppTextField(label: 'Bio', controller: bioController),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Height (cm)',
                  controller: heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppTextField(
                  label: 'Weight (kg)',
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Primary goal', style: Theme.of(context).textTheme.titleSmall),
          ...PrimaryGoal.values.map(
            (goal) => RadioListTile<PrimaryGoal>(
              contentPadding: EdgeInsets.zero,
              title: Text(goal.label),
              value: goal,
              groupValue: primaryGoal.value,
              onChanged: (v) => primaryGoal.value = v,
            ),
          ),
          const SizedBox(height: 8),
          Text('Experience level', style: Theme.of(context).textTheme.titleSmall),
          ...FitnessLevel.values.map(
            (level) => RadioListTile<FitnessLevel>(
              contentPadding: EdgeInsets.zero,
              title: Text(level.name[0].toUpperCase() + level.name.substring(1)),
              value: level,
              groupValue: fitnessLevel.value,
              onChanged: (v) => fitnessLevel.value = v!,
            ),
          ),
          const SizedBox(height: 8),
          Text('Units', style: Theme.of(context).textTheme.titleSmall),
          ...MeasurementUnits.values.map(
            (unit) => RadioListTile<MeasurementUnits>(
              contentPadding: EdgeInsets.zero,
              title: Text(unit == MeasurementUnits.metric ? 'Metric (kg, cm)' : 'Imperial (lb, in)'),
              value: unit,
              groupValue: units.value,
              onChanged: (v) => units.value = v!,
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Public profile'),
            subtitle: const Text('Allow others to find and follow your progress'),
            value: isPublic.value,
            onChanged: (v) => isPublic.value = v,
          ),
          const SizedBox(height: 16),
          GradientButton(label: 'Save changes', isLoading: isSaving.value, onPressed: save),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
