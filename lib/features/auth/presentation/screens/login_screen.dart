import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../providers/auth_providers.dart';
import '../widgets/social_sign_in_buttons.dart';

class LoginScreen extends HookConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);
    final obscurePassword = useState(true);

    Future<void> submit() async {
      if (!formKey.currentState!.validate()) return;
      isLoading.value = true;
      final result = await ref.read(signInWithEmailProvider).call(
            email: emailController.text.trim(),
            password: passwordController.text,
          );
      isLoading.value = false;
      if (!context.mounted) return;
      result.match(
        (failure) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.displayMessage))),
        (_) {},
      );
    }

    Future<void> submitGoogle() async {
      isLoading.value = true;
      final result = await ref.read(signInWithGoogleProvider).call();
      isLoading.value = false;
      if (!context.mounted) return;
      result.match(
        (failure) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.displayMessage))),
        (_) {},
      );
    }

    Future<void> submitApple() async {
      isLoading.value = true;
      final result = await ref.read(signInWithAppleProvider).call();
      isLoading.value = false;
      if (!context.mounted) return;
      result.match(
        (failure) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.displayMessage))),
        (_) {},
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Welcome back', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Sign in to keep training with IronCoach.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
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
                  obscureText: obscurePassword.value,
                  autofillHints: const [AutofillHints.password],
                  prefixIcon: Icons.lock_outline,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => submit(),
                  suffixIcon: IconButton(
                    icon: Icon(obscurePassword.value ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => obscurePassword.value = !obscurePassword.value,
                  ),
                  validator: (value) =>
                      (value == null || value.length < 8) ? 'Minimum 8 characters' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(RoutePaths.forgotPassword),
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 8),
                PrimaryButton(label: 'Sign in', isLoading: isLoading.value, onPressed: submit),
                const SizedBox(height: 24),
                SocialSignInButtons(
                  isLoading: isLoading.value,
                  onGooglePressed: submitGoogle,
                  onApplePressed: submitApple,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () => context.push(RoutePaths.register),
                      child: const Text('Sign up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
