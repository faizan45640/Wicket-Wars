import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_messages.dart';
import '../auth/auth_validators.dart';
import '../auth/password_crypto.dart';
import '../data/onboarding_seed.dart';
import '../data/providers.dart';
import '../theme/game_colors.dart';
import '../widgets/auth_error_banner.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _obscure = true;
  var _obscure2 = true;
  var _loading = false;
  String? _authError;

  void _clearAuthError() {
    if (_authError != null) setState(() => _authError = null);
  }

  @override
  void dispose() {
    _displayName.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _loading = true;
      _authError = null;
    });
    try {
      final encrypted = PasswordCrypto.encryptPassword(_password.text);
      final passwordForAuth = PasswordCrypto.decryptPassword(encrypted);
      final user = await ref
          .read(authRepositoryProvider)
          .createUserWithEmailAndPassword(
            email: _email.text,
            password: passwordForAuth,
            displayName: _displayName.text,
          );
      await ensureStarterData(
        userRepository: ref.read(userRepositoryProvider),
        squadRepository: ref.read(squadRepositoryProvider),
        uid: user.uid,
        email: _email.text,
        displayName: _displayName.text,
      );
      if (!mounted) return;
      context.go('/starter-pack');
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _authError = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.bg,
      appBar: AppBar(
        backgroundColor: GameColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: GameColors.neon),
          onPressed:
              _loading
                  ? null
                  : () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/login');
                    }
                  },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'CREATE ACCOUNT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: GameColors.neon,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _displayName,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(color: Colors.white),
                      decoration: _fieldDecoration('Display name'),
                      autofillHints: const [AutofillHints.name],
                      onChanged: (_) => _clearAuthError(),
                      validator: AuthValidators.displayName,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: _fieldDecoration('Email'),
                      autofillHints: const [AutofillHints.email],
                      onChanged: (_) => _clearAuthError(),
                      validator: AuthValidators.email,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      style: const TextStyle(color: Colors.white),
                      decoration: _fieldDecoration('Password').copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: GameColors.muted,
                          ),
                        ),
                      ),
                      autofillHints: const [AutofillHints.newPassword],
                      onChanged: (_) => _clearAuthError(),
                      validator: AuthValidators.newPassword,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _obscure2,
                      style: const TextStyle(color: Colors.white),
                      decoration: _fieldDecoration('Confirm password').copyWith(
                        suffixIcon: IconButton(
                          onPressed:
                              () => setState(() => _obscure2 = !_obscure2),
                          icon: Icon(
                            _obscure2
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: GameColors.muted,
                          ),
                        ),
                      ),
                      onChanged: (_) => _clearAuthError(),
                      validator: (v) {
                        if (v != _password.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    if (_authError != null) ...[
                      const SizedBox(height: 16),
                      AuthErrorBanner(
                        message: _authError!,
                        onDismiss: _clearAuthError,
                        semanticsLabel: 'Sign up error',
                      ),
                    ],
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: GameColors.neon,
                        foregroundColor: GameColors.onNeonButton,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child:
                          _loading
                              ? SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: GameColors.onNeonButton,
                                ),
                              )
                              : const Text(
                                'CREATE ACCOUNT',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already registered? ',
                          style: TextStyle(
                            color: GameColors.muted.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed:
                              _loading
                                  ? null
                                  : () {
                                    if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go('/login');
                                    }
                                  },
                          style: TextButton.styleFrom(
                            foregroundColor: GameColors.neon,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text(
                            'Sign in',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: GameColors.muted.withValues(alpha: 0.95),
        fontWeight: FontWeight.w600,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: GameColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: GameColors.neon, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE57373)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE57373)),
      ),
      fillColor: GameColors.card,
      filled: true,
    );
  }
}
