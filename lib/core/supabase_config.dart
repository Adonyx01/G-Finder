import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase credentials for ChezMoi.
///
/// Override at build time with `--dart-define=SUPABASE_URL=...` and
/// `--dart-define=SUPABASE_ANON_KEY=...`.
class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://cjydycxbbemodgfbtfmd.supabase.co',
  );

  // Clé publique Supabase (nouveau format sb_publishable_...). Publique par
  // conception : l'accès aux données reste protégé par les règles RLS.
  static const anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_i9abxKswIPjX0dac3qFKOw_KAyvSTWt',
  );

  static Future<void> initialize() async {
    if (url.trim().isEmpty || anonKey.trim().isEmpty) {
      throw StateError(
        'SUPABASE_URL and SUPABASE_ANON_KEY are required when '
        'CHEZMOI_BACKEND=supabase.',
      );
    }
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: SharedPreferencesLocalStorage(
          persistSessionKey: 'chezmoi-auth-session-v2',
        ),
      ),
    );
  }
}
