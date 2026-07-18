import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/device.dart';
import '../../core/l10n.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_widgets.dart';
import '../../core/widgets/error_banner.dart';
import '../../data/api/api_error.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      // Best-effort device IANA timezone so streaks roll over at local midnight,
      // and the device language so the account starts out in the language the
      // user is already reading this form in.
      final timezone = await getDeviceTimezone();
      final user = await ref.read(authRepositoryProvider).register(
            email: _email.text.trim(),
            password: _password.text,
            timezone: timezone,
            language: getDeviceLanguage(),
          );
      ref.read(authControllerProvider.notifier).setSession(user);
    } catch (e) {
      if (!mounted) return;
      final message = apiErrorMessage(context.l10n, e, fallback: context.l10n.signUpFailed);
      setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(alignment: Alignment.centerLeft, child: AppLogo(size: 60, radius: 18)),
                    const SizedBox(height: 20),
                    Text(l10n.createAccount, style: theme.textTheme.displaySmall),
                    const SizedBox(height: 6),
                    Text(l10n.buildYourStreak,
                        style: theme.textTheme.bodyLarge?.copyWith(color: c.textSecondary)),
                    const SizedBox(height: 28),

                    FieldLabel(l10n.emailLabel),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? l10n.validEmailRequired
                          : null,
                    ),
                    const SizedBox(height: 16),

                    FieldLabel(l10n.passwordLabel),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
                      decoration: InputDecoration(
                        helperText: l10n.passwordHelperMinChars,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 8)
                          ? l10n.passwordTooShort
                          : null,
                    ),
                    const SizedBox(height: 16),

                    FieldLabel(l10n.confirmPasswordLabel),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _obscure,
                      style: TextStyle(fontWeight: FontWeight.w600, color: c.ink),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      validator: (v) =>
                          v != _password.text ? l10n.passwordsDoNotMatch : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      ErrorBanner(_error!),
                    ],
                    const SizedBox(height: 28),

                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(l10n.createAccount),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: _submitting ? null : () => context.pop(),
                        child: Text(l10n.alreadyHaveAccount),
                      ),
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
}
