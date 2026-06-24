import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../core/auth_background.dart';
import '../../core/auth_error_messages.dart';
import '../../core/chezmoi_logo.dart';
import '../../core/theme.dart';
import 'auth_service.dart';

/// Saisie du code à 6 chiffres reçu par e-mail (connexion voyageur sans mot de passe).
class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({super.key, required this.email, this.redirect});

  final String email;
  final String? redirect;

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final _codeController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _resending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      _showMessage('Saisissez le code reçu par e-mail.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.verifyEmailCode(email: widget.email, token: code);
      await _authService.ensureProfile();
      if (!mounted) return;
      context.go(authSuccessDestination(widget.redirect));
    } catch (error) {
      if (!mounted) return;
      _showMessage(authErrorMessage(error, action: AuthAction.verifyOtp));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await _authService.sendSignInCode(email: widget.email);
      if (!mounted) return;
      _showMessage('Nouveau code envoyé.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(authErrorMessage(error, action: AuthAction.resendOtp));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.chezMoiColors;

    return AuthBackgroundScaffold(
      body: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: IconButton(
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/login'),
                icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                tooltip: 'Retour',
              ),
            ),
          ),
          Expanded(
            child: AuthFormCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Center(
                    child: ChezMoiLogo(
                      size: ChezMoiLogoSize.small,
                      lightOnDark: false,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Vérification',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Saisissez le code envoyé à ${widget.email}.',
                    style: TextStyle(color: colors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 10,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '------',
                    ),
                    enabled: !_isLoading,
                    onSubmitted: (_) => _verify(),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isLoading ? null : _verify,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Vérifier'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: (_isLoading || _resending) ? null : _resend,
                    child: Text(_resending ? 'Envoi…' : 'Renvoyer le code'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
