import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/backend_mode.dart';
import '../places/models/place.dart';

/// État du compte voyageur (consultation + réservation).
class AccountCapabilities {
  const AccountCapabilities({
    required this.authenticated,
    required this.loading,
    this.profile,
  });

  final bool authenticated;
  final bool loading;
  final ChezMoiProfile? profile;

  static AccountCapabilities signedOut({bool loading = false}) {
    return AccountCapabilities(authenticated: false, loading: loading);
  }
}

class AccountCapabilitiesService {
  AccountCapabilitiesService({SupabaseClient? client})
    : _supabaseClient = client;

  final SupabaseClient? _supabaseClient;

  SupabaseClient get _client => _supabaseClient ?? Supabase.instance.client;

  Future<AccountCapabilities> loadCurrent() async {
    if (BackendMode.isTemplate) {
      return AccountCapabilities(
        authenticated: true,
        loading: false,
        profile: const ChezMoiProfile(
          id: 'template-user',
          email: 'demo@chezmoi.ga',
          prenom: 'Demo',
          nom: 'ChezMoi',
          displayName: 'Demo ChezMoi',
          phone: '+241 77 00 00 00',
          location: 'Libreville',
          countryCode: 'GA',
          countryName: 'Gabon',
          accountType: 'traveler',
          avatarUrl: '',
          locationLat: 0.4162,
          locationLng: 9.4325,
        ),
      );
    }
    final user = _client.auth.currentUser;
    if (user == null) return AccountCapabilities.signedOut();

    final profile = await _loadProfile(
      user.id,
      fallbackEmail: user.email ?? '',
    );

    return AccountCapabilities(
      authenticated: true,
      loading: false,
      profile: profile,
    );
  }

  Future<ChezMoiProfile?> _loadProfile(
    String userId, {
    required String fallbackEmail,
  }) async {
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return null;
      return ChezMoiProfile.fromRow(
        Map<String, dynamic>.from(row),
        fallbackEmail: fallbackEmail,
      );
    } catch (_) {
      return null;
    }
  }
}
