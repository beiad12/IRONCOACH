import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../../../core/widgets/segmented_tabs.dart';
import '../providers/auth_providers.dart';
import '../widgets/social_sign_in_buttons.dart';

enum _AuthMode { signIn, signUp }

/// Single segmented Sign In / Sign Up screen, matching the design's auth
/// flow exactly: one screen, one mode toggle, email + password only (no
/// username field — the backend assigns a default one on signup and the
/// user can pick a real one later in Edit Profile).
class AuthScreen extends HookConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = useState(_AuthMode.signIn);
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final obscurePassword = useState(true);
    final isLoading = useState(false);

    Future<void> handleFailure<T>(
        void Function() onSuccess, Future<Result<T>> Function() action) async {
      isLoading.value = true;
      final result = await action();
      isLoading.value = false;
      if (!context.mounted) return;
      result.match(
        (failure) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.displayMessage))),
        (_) => onSuccess(),
      );
    }

    Future<void> submit() async {
      if (!formKey.currentState!.validate()) return;
      if (mode.value == _AuthMode.signIn) {
        await handleFailure(
          () {},
          () => ref.read(signInWithEmailProvider).call(
                email: emailController.text.trim(),
                password: passwordController.text,
              ),
        );
      } else {
        await handleFailure(
          () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Check your inbox to confirm your email.')),
          ),
          () => ref.read(signUpWithEmailProvider).call(
                email: emailController.text.trim(),
                password: passwordController.text,
              ),
        );
      }
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 70, 28, 40),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  mode.value == _AuthMode.signIn
                      ? 'Welcome back'
                      : 'Create your account',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  mode.value == _AuthMode.signIn
                      ? 'Sign in to pick up where you left off'
                      : 'Start coaching that adapts to you',
                  style: const TextStyle(
                      color: AppColors.darkTextSecondary, fontSize: 14),
                ),
                const SizedBox(height: 24),
                SegmentedTabs<_AuthMode>(
                  selected: mode.value,
                  onChanged: (v) => mode.value = v,
                  options: const [
                    SegmentedTabOption(
                        value: _AuthMode.signIn, label: 'Sign In'),
                    SegmentedTabOption(
                        value: _AuthMode.signUp, label: 'Sign Up'),
                  ],
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Email address',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  validator: (value) => (value == null || !value.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Password',
                  controller: passwordController,
                  obscureText: obscurePassword.value,
                  autofillHints: [
                    mode.value == _AuthMode.signIn
                        ? AutofillHints.password
                        : AutofillHints.newPassword,
                  ],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => submit(),
                  suffixIcon: IconButton(
                    icon: Icon(obscurePassword.value
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        obscurePassword.value = !obscurePassword.value,
                  ),
                  validator: (value) => (value == null || value.length < 8)
                      ? 'Minimum 8 characters'
                      : null,
                ),
                if (mode.value == _AuthMode.signIn) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(RoutePaths.forgotPassword),
                      child: const Text('Forgot password?'),
                    ),
                  ),
                ] else
                  const SizedBox(height: 10),
                const SizedBox(height: 10),
                GradientButton(
                  label: mode.value == _AuthMode.signIn
                      ? 'Sign In'
                      : 'Create account',
                  isLoading: isLoading.value,
                  onPressed: submit,
                ),
                const SizedBox(height: 24),
                SocialSignInButtons(
                  isLoading: isLoading.value,
                  onGooglePressed: () => handleFailure(
                    () {},
                    () => ref.read(signInWithGoogleProvider).call(),
                  ),
                  onApplePressed: () => handleFailure(
                    () {},
                    () => ref.read(signInWithAppleProvider).call(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
