import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_providers.dart';
import '../widgets/social_sign_in_buttons.dart';

class RegisterScreen extends HookConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final usernameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);

    Future<void> submit() async {
      if (!formKey.currentState!.validate()) return;
      isLoading.value = true;
      final result = await ref.read(signUpWithEmailProvider).call(
            email: emailController.text.trim(),
            password: passwordController.text,
            username: usernameController.text.trim(),
          );
      isLoading.value = false;
      if (!context.mounted) return;
      result.match(
        (failure) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.displayMessage))),
        (_) => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Check your inbox to confirm your email.')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(leading: BackButton(onPressed: () => context.pop())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Create your account', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Start training smarter with your AI coaches.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                AppTextField(
                  label: 'Username',
                  controller: usernameController,
                  prefixIcon: Icons.alternate_email,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      (value == null || value.trim().length < 3) ? 'Minimum 3 characters' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Email',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  prefixIcon: Icons.email_outlined,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Password',
                  controller: passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  prefixIcon: Icons.lock_outline,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => submit(),
                  validator: (value) =>
                      (value == null || value.length < 8) ? 'Minimum 8 characters' : null,
                ),
                const SizedBox(height: 24),
                PrimaryButton(label: 'Create account', isLoading: isLoading.value, onPressed: submit),
                const SizedBox(height: 24),
                SocialSignInButtons(
                  isLoading: isLoading.value,
                  onGooglePressed: () => ref.read(signInWithGoogleProvider).call(),
                  onApplePressed: () => ref.read(signInWithAppleProvider).call(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
