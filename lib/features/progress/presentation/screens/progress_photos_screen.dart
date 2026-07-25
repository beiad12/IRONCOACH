import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/async_value_widget.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/progress_photo.dart';
import '../providers/progress_providers.dart';

class ProgressPhotosScreen extends ConsumerWidget {
  const ProgressPhotosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(progressPhotosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_outlined),
            onPressed: () => _capture(context, ref),
          ),
        ],
      ),
      body: AsyncValueWidget(
        value: photosAsync,
        onRetry: () => ref.invalidate(progressPhotosProvider),
        data: (photos) {
          if (photos.isEmpty) {
            return const EmptyState(
                icon: Icons.photo_camera_outlined,
                title: 'No progress photos yet');
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: photos.length,
            itemBuilder: (context, i) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                  imageUrl: photos[i].photoUrl, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }

  Future<void> _capture(BuildContext context, WidgetRef ref) async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null) return;

    final result =
        await ref.read(progressRepositoryProvider).uploadProgressPhoto(
              file: File(picked.path),
              angle: PhotoAngle.front,
            );
    if (!context.mounted) return;
    result.match(
      (failure) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.displayMessage))),
      (_) => ref.invalidate(progressPhotosProvider),
    );
  }
}
