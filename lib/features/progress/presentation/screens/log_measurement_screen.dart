import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/body_measurement.dart';
import '../providers/progress_providers.dart';

class LogMeasurementScreen extends HookConsumerWidget {
  const LogMeasurementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weight = useTextEditingController();
    final bodyFat = useTextEditingController();
    final chest = useTextEditingController();
    final waist = useTextEditingController();
    final hips = useTextEditingController();
    final bicep = useTextEditingController();
    final thigh = useTextEditingController();
    final isSaving = useState(false);

    Future<void> save() async {
      isSaving.value = true;
      final result = await ref.read(progressRepositoryProvider).logMeasurement(
            BodyMeasurement(
              id: '',
              measuredAt: DateTime.now(),
              weightKg: double.tryParse(weight.text),
              bodyFatPct: double.tryParse(bodyFat.text),
              chestCm: double.tryParse(chest.text),
              waistCm: double.tryParse(waist.text),
              hipsCm: double.tryParse(hips.text),
              bicepCm: double.tryParse(bicep.text),
              thighCm: double.tryParse(thigh.text),
            ),
          );
      isSaving.value = false;
      if (!context.mounted) return;
      result.match(
        (failure) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.displayMessage))),
        (_) {
          ref.invalidate(bodyMeasurementsProvider);
          context.pop();
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Log measurement')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppTextField(
            label: 'Weight (kg)',
            controller: weight,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Body fat %',
            controller: bodyFat,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Chest (cm)',
                  controller: chest,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'Waist (cm)',
                  controller: waist,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Hips (cm)',
                  controller: hips,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  label: 'Bicep (cm)',
                  controller: bicep,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Thigh (cm)',
            controller: thigh,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 20),
          PrimaryButton(label: 'Save', isLoading: isSaving.value, onPressed: save),
        ],
      ),
    );
  }
}
