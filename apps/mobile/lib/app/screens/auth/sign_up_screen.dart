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
        SnackBar(content: Text(authController.errorMessage ?? 'Sign up failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = AuthScope.of(context);

    return AuthScaffold(
      eyebrow: 'Create your workspace',
      title: 'Create account',
      subtitle:
          'Start with the role that matches your first workflow. The platform will shape the dashboard around that role.',
      highlights: const [
        'Attendee',
        'Organizer',
        'Vendor',
        'Sponsor',
        'Admin',
      ],
      footer: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Already registered?'),
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
                    'Starting role',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    ('attendee', 'Attendee'),
                    ('organizer', 'Organizer'),
                    ('vendor', 'Vendor'),
                    ('sponsor', 'Sponsor'),
                    ('admin', 'Admin'),
                  ].map((entry) {
                    final selected = _role == entry.$1;
                    return ChoiceChip(
                      label: Text(entry.$2),
                      selected: selected,
                      onSelected: (_) => setState(() => _role = entry.$1),
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
