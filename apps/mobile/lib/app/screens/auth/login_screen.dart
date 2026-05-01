import 'package:flutter/material.dart';
import '../../router.dart';
import '../../session/auth_api_client.dart';
import '../../session/auth_scope.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/auth_status_banner.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authController = AuthScope.of(context);
    try {
      await authController.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on ApiException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(authController.errorMessage ?? 'Sign in failed')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authController.errorMessage ?? 'Unable to reach the server',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = AuthScope.of(context);

    return AuthScaffold(
      eyebrow: '',
      title: 'Sign in',
      subtitle: 'Welcome back.',
      footer: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Need an account?'),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRouter.signUp),
            child: const Text('Create one'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRouter.forgotPassword),
            child: const Text('Forgot password'),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: authController,
        builder: (context, _) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                if (authController.errorMessage != null)
                  AuthStatusBanner(
                    message: authController.errorMessage!,
                    color: const Color(0xFFB3261E),
                  ),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'name@company.com',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 8) {
                      return 'Use at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: authController.isLoading ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        authController.isLoading ? 'Signing in...' : 'Sign in',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
