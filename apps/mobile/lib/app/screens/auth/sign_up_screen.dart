import 'package:flutter/material.dart';
import '../../router.dart';
import '../../session/auth_api_client.dart';
import '../../session/auth_scope.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/auth_status_banner.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'attendee';

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
      await authController.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _role,
      );
    } on ApiException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(authController.errorMessage ?? 'Sign up failed')),
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
      title: 'Create account',
      subtitle: 'Set up your account.',
      footer: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Already have an account?'),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRouter.login),
            child: const Text('Sign in'),
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Role',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(height: 10),
                Column(
                  children: const [
                    ('attendee', 'Attendee', Icons.person_outline_rounded),
                    ('organizer', 'Organizer', Icons.event_note_rounded),
                    ('vendor', 'Vendor', Icons.storefront_rounded),
                    ('sponsor', 'Sponsor', Icons.campaign_rounded),
                  ].map((entry) {
                    final selected = _role == entry.$1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => setState(() => _role = entry.$1),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFEAF0F5)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF2E4A62)
                                  : const Color(0xFFD9E1E7),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                entry.$3,
                                size: 20,
                                color: selected
                                    ? const Color(0xFF2E4A62)
                                    : const Color(0xFF68737D),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.$2,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? const Color(0xFF17212B)
                                        : const Color(0xFF3D4751),
                                  ),
                                ),
                              ),
                              if (selected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 20,
                                  color: Color(0xFF2E4A62),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(growable: false),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'At least 8 characters',
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
                        authController.isLoading
                            ? 'Creating account...'
                            : 'Create account',
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
