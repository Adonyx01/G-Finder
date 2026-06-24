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

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, this.redirect});

  final String? redirect;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscure = true;
  String _accountType = 'traveler';

  @override
  void dispose() {
    _companyController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) return 'Veuillez saisir $label.';
    return null;
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
      return 'Veuillez saisir un mot de passe.';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _passwordController.text) {
      return 'Les mots de passe ne correspondent pas.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (BackendMode.isTemplate) {
      context.go(authSuccessDestination(widget.redirect));
      return;
    }

    final isAnnonceur = _accountType == 'annonceur';
    setState(() => _isLoading = true);
    try {
      if (isAnnonceur) {
        final response = await _authService.signUpWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
          accountType: 'annonceur',
          companyName: _companyController.text,
          phone: _phoneController.text,
        );
        if (!mounted) return;
        if (response.session != null) {
          // Session immédiate (confirmation e-mail désactivée) -> connecté.
          await _authService.ensureProfile();
          if (!mounted) return;
          context.go(authSuccessDestination(widget.redirect));
        } else {
          _showMessage(
            'Compte créé. Vérifiez votre e-mail pour confirmer, puis connectez-vous.',
          );
          context.go('/login');
        }
      } else {
        // Voyageur : sans mot de passe -> code envoyé par e-mail.
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
      _showMessage(
        authErrorMessage(
          error,
          action: isAnnonceur ? AuthAction.signup : AuthAction.signupOtp,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                      'Créer un compte',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rejoignez ChezMoi au Gabon.',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Je crée un compte en tant que',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 8),
                    Text(
                      _accountType == 'annonceur'
                          ? 'Vous pourrez publier et gérer vos hôtels, restaurants ou activités.'
                          : 'Vous pourrez réserver des hôtels, restaurants et activités.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_accountType == 'annonceur') ...[
                      TextFormField(
                        controller: _companyController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: "Nom de l'entreprise",
                          prefixIcon: Icon(Icons.storefront_outlined),
                        ),
                        validator: (v) =>
                            _validateRequired(v, "le nom de l'entreprise"),
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Numéro de téléphone',
                          hintText: '+241 ...',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) =>
                            _validateRequired(v, 'le numéro de téléphone'),
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 14),
                    ],
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
                        autofillHints: const [AutofillHints.newPassword],
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          helperText: 'Au moins 6 caractères',
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
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _obscure,
                        decoration: const InputDecoration(
                          labelText: 'Confirmer le mot de passe',
                        ),
                        validator: _validateConfirm,
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
                                  ? 'Créer mon compte'
                                  : 'Recevoir mon code',
                            ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Déjà un compte ? ',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                        GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () => context.canPop()
                                    ? context.pop()
                                    : context.go('/login'),
                          child: Text(
                            'Se connecter',
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
