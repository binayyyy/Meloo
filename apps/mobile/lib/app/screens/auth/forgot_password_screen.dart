import 'package:flutter/material.dart';
import '../../session/auth_api_client.dart';
import '../../session/auth_models.dart';
import '../../session/auth_scope.dart';
import '../../widgets/auth_scaffold.dart';
import '../../widgets/auth_status_banner.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  ForgotPasswordResult? _result;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authController = AuthScope.of(context);
    try {
      final result = await authController.forgotPassword(
        email: _emailController.text.trim(),
      );
      setState(() => _result = result);
    } on ApiException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authController.errorMessage ?? 'Request failed'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = AuthScope.of(context);

    return AuthScaffold(
      eyebrow: 'Password reset',
      title: 'Reset password',
      subtitle:
          'Request a reset for your Meloo account. Local builds still expose the debug token for testing.',
      highlights: const [
        'Secure reset',
        'Debug token in local',
      ],
      footer: Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to sign in'),
        ),
      ),
      child: AnimatedBuilder(
        animation: authController,
        builder: (context, _) {
          return Form(
            key: _formKey,
            child: Column(
              children: [
                if (_result != null)
                  AuthStatusBanner(
                    message: _result!.debugResetToken == null
                        ? _result!.message
                        : '${_result!.message}\n\nDebug token: ${_result!.debugResetToken}',
                    color: const Color(0xFF0E6B5C),
                  ),
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
                    hintText: 'Account email',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: authController.isLoading ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        authController.isLoading
                            ? 'Preparing reset...'
                            : 'Request reset',
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
