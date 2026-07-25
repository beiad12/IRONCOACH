import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/failures.dart';
import 'error_view.dart';

/// Renders an [AsyncValue] with consistent loading/error/data handling so
/// screens don't hand-roll `.when` boilerplate. [error] is used when the
/// thrown object is already a [Failure] (from a repository); otherwise it
/// falls back to [Failure.unexpected].
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
    super.key,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () =>
          loading ?? const Center(child: CircularProgressIndicator()),
      error: (error, _) {
        final failure =
            error is Failure ? error : Failure.unexpected(error.toString());
        return ErrorView(failure: failure, onRetry: onRetry);
      },
    );
  }
}
