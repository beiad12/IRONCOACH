import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_providers.dart';

class ForgotPasswordScreen extends HookConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final emailController = useTextEditingController();
    final isLoading = useState(false);
    final emailSent = useState(false);

    Future<void> submit() async {
      if (!formKey.currentState!.validate()) return;
      isLoading.value = true;
      final result = await ref.read(sendPasswordResetEmailProvider).call(emailController.text.trim());
      isLoading.value = false;
      if (!context.mounted) return;
      result.match(
        (failure) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.displayMessage))),
        (_) => emailSent.value = true,
      );
    }

    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: emailSent.value
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mark_email_read_outlined, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      'Check ${emailController.text} for a reset link.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                )
              : Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Reset your password', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        "We'll email you a link to reset it.",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      AppTextField(
                        label: 'Email',
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        onFieldSubmitted: (_) => submit(),
                        validator: (value) =>
                            (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(label: 'Send reset link', isLoading: isLoading.value, onPressed: submit),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
