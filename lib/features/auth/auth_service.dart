import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentification e-mail + mot de passe (connexion / inscription).
class AuthService {
  AuthService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  bool get isSignedIn => _client.auth.currentUser != null;

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
    String accountType = 'traveler',
    String? companyName,
    String? phone,
  }) {
    final company = companyName?.trim() ?? '';
    final tel = phone?.trim() ?? '';
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'account_type': accountType,
        if (company.isNotEmpty) 'company_name': company,
        if (company.isNotEmpty) 'display_name': company,
        if (tel.isNotEmpty) 'phone': tel,
      },
    );
  }

  /// Voyageur : connexion sans mot de passe via un code à 6 chiffres envoyé
  /// par e-mail (crée le compte au besoin, avec le type de compte choisi).
  Future<void> sendSignInCode({
    required String email,
    String accountType = 'traveler',
  }) {
    return _client.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: true,
      data: {'account_type': accountType},
    );
  }

  /// Vérifie le code reçu par e-mail et ouvre la session.
  Future<AuthResponse> verifyEmailCode({
    required String email,
    required String token,
  }) {
    return _client.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.email,
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Filet de sécurité : crée/complète la ligne profiles si le trigger
  /// `handle_new_user` n'a pas tourné (ex. projet sans trigger).
  Future<void> ensureProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'display_name':
            metadata['display_name'] ??
            metadata['company_name'] ??
            metadata['full_name'] ??
            '',
        'company_name': metadata['company_name'],
        'phone': metadata['phone'],
        'account_type': metadata['account_type'] ?? 'traveler',
      }, onConflict: 'id');
    } catch (_) {
      // Le profil sera relu plus tard ; on n'interrompt pas la connexion.
    }
  }
}
