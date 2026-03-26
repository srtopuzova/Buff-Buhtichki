import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:medshelf/core/theme/app_colors.dart';
import 'package:medshelf/core/utils/validators.dart';
import 'package:medshelf/features/auth/providers/auth_provider.dart';
import 'package:medshelf/features/auth/widgets/auth_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      email: _emailController.text,
      username: _usernameController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (success) {
      context.go('/home');
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
      auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: AppColors.medShelfGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.medShelf.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Create Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Start managing your medications today',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AuthTextField(
                      label: 'Email',
                      hint: 'you@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                      validator: Validators.email,
                      focusNode: _emailFocus,
                      onEditingComplete: () =>
                          FocusScope.of(context).requestFocus(_usernameFocus),
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      label: 'Username',
                      hint: 'e.g. john_doe',
                      controller: _usernameController,
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      validator: Validators.username,
                      focusNode: _usernameFocus,
                      onEditingComplete: () =>
                          FocusScope.of(context).requestFocus(_passwordFocus),
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      label: 'Password',
                      hint: 'Min 8 chars, uppercase + special char',
                      controller: _passwordController,
                      isPassword: true,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      validator: Validators.password,
                      focusNode: _passwordFocus,
                      onEditingComplete: () =>
                          FocusScope.of(context).requestFocus(_confirmFocus),
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 14),
                    AuthTextField(
                      label: 'Confirm Password',
                      hint: 'Re-enter your password',
                      controller: _confirmPasswordController,
                      isPassword: true,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      validator: (v) => Validators.confirmPassword(
                          v, _passwordController.text),
                      focusNode: _confirmFocus,
                      textInputAction: TextInputAction.done,
                      onEditingComplete: isLoading ? null : _submit,
                      enabled: !isLoading,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Password requirements hint
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.medShelfLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Password must be at least 8 characters, include one uppercase letter and one special character.',
                  style: TextStyle(
                    color: AppColors.medShelf,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Create Account'),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: isLoading ? null : () => context.pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
