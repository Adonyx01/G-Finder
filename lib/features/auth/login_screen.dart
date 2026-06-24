import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_router.dart';
import '../../core/auth_error_messages.dart';
import '../../core/auth_background.dart';
import '../../core/backend_mode.dart';
import '../../core/chezmoi_logo.dart';
import '../../core/theme.dart';
import '../../shared/widgets/akasha_footer.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.redirect});

  final String? redirect;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscure = true;
  String _accountType = 'traveler';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Veuillez saisir votre adresse e-mail.';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Adresse e-mail invalide.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir votre mot de passe.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Mode template : pas de backend, on entre directement.
    if (BackendMode.isTemplate) {
      context.go(authSuccessDestination(widget.redirect));
      return;
    }

    final isAnnonceur = _accountType == 'annonceur';
    setState(() => _isLoading = true);
    try {
      if (isAnnonceur) {
        await _authService.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        await _authService.ensureProfile();
        if (!mounted) return;
        context.go(authSuccessDestination(widget.redirect));
      } else {
        // Voyageur : connexion par code e-mail (sans mot de passe).
        await _authService.sendSignInCode(
          email: _emailController.text,
          accountType: 'traveler',
        );
        if (!mounted) return;
        context.push('/verify-code', extra: <String, dynamic>{
          'email': _emailController.text.trim(),
          if (isValidRedirect(widget.redirect)) 'redirect': widget.redirect,
        });
      }
    } catch (error) {
      if (!mounted) return;
      _showError(
        authErrorMessage(
          error,
          action: isAnnonceur ? AuthAction.signin : AuthAction.loginOtp,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToSignup() {
    final extra = <String, dynamic>{};
    if (isValidRedirect(widget.redirect)) extra['redirect'] = widget.redirect;
    context.push('/signup', extra: extra.isEmpty ? null : extra);
  }

  void _showError(String message) {
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
                onPressed: () => context.go('/dashboard'),
                icon: Icon(Icons.arrow_back, color: colors.textPrimary),
                tooltip: 'Retour',
              ),
            ),
          ),
          Expanded(
            child: AuthFormCard(
              child: Form(
                key: _formKey,
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
                      'Connexion',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connectez-vous pour accéder à ChezMoi.',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'traveler',
                          label: Text('Voyageur'),
                          icon: Icon(Icons.luggage_rounded),
                        ),
                        ButtonSegment(
                          value: 'annonceur',
                          label: Text('Annonceur'),
                          icon: Icon(Icons.storefront_rounded),
                        ),
                      ],
                      selected: {_accountType},
                      onSelectionChanged: _isLoading
                          ? null
                          : (selection) =>
                                setState(() => _accountType = selection.first),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Adresse e-mail',
                        hintText: 'vous@exemple.com',
                      ),
                      validator: _validateEmail,
                      enabled: !_isLoading,
                    ),
                    if (_accountType == 'annonceur') ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: _validatePassword,
                        enabled: !_isLoading,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _accountType == 'annonceur'
                                  ? 'Se connecter'
                                  : 'Recevoir mon code',
                            ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pas encore de compte ? ',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                        GestureDetector(
                          onTap: _isLoading ? null : _goToSignup,
                          child: Text(
                            'Créer un compte',
                            style: TextStyle(
                              color: colors.primaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const AkashaFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
