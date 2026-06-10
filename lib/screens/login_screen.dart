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
import '../widgets/auth_logo.dart';
import '../widgets/game_loading_overlay.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _obscure = true;
  var _loading = false;
  var _resetLoading = false;
  String? _authError;

  void _clearAuthError() {
    if (_authError != null) setState(() => _authError = null);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
          .signInWithEmailAndPassword(
            email: _email.text,
            password: passwordForAuth,
          );
      await ensureStarterData(
        userRepository: ref.read(userRepositoryProvider),
        squadRepository: ref.read(squadRepositoryProvider),
        uid: user.uid,
        email: user.email ?? _email.text,
        displayName: user.displayName,
      );
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _authError = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final emailError = AuthValidators.email(_email.text);
    if (emailError != null) {
      setState(() => _authError = emailError);
      HapticFeedback.mediumImpact();
      return;
    }
    setState(() {
      _resetLoading = true;
      _authError = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(_email.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset link sent to ${_email.text.trim()}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _authError = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _resetLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildForm(context),
        Positioned.fill(
          child: GameLoadingOverlay(visible: _loading, title: 'LOGGING IN'),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const AuthLogo(height: 150),
                    const SizedBox(height: 30),
                    TextFormField(
                      key: const Key('login_email'),
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      style: const TextStyle(color: Colors.white),
                      decoration: _fieldDecoration('Email'),
                      onChanged: (_) => _clearAuthError(),
                      validator: AuthValidators.email,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('login_password'),
                      controller: _password,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
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
                      onChanged: (_) => _clearAuthError(),
                      validator: AuthValidators.loginPassword,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed:
                            (_loading || _resetLoading)
                                ? null
                                : _sendPasswordReset,
                        child:
                            _resetLoading
                                ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: GameColors.neon,
                                  ),
                                )
                                : const Text('Forgot password?'),
                      ),
                    ),
                    if (_authError != null) ...[
                      const SizedBox(height: 16),
                      AuthErrorBanner(
                        message: _authError!,
                        onDismiss: _clearAuthError,
                        semanticsLabel: 'Sign in error',
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
                                'LOG IN',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No account? ',
                          style: TextStyle(
                            color: GameColors.muted.withValues(alpha: 0.9),
                          ),
                        ),
                        TextButton(
                          onPressed:
                              _loading ? null : () => context.push('/signup'),
                          child: Text(
                            'Sign up',
                            style: TextStyle(
                              color: GameColors.neon,
                              fontWeight: FontWeight.w700,
                            ),
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
