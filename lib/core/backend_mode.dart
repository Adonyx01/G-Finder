class BackendMode {
  static const backend = String.fromEnvironment(
    'CHEZMOI_BACKEND',
    defaultValue: 'supabase',
  );

  /// Template mode keeps the UI and flows runnable without touching old data.
  ///
  /// Existing Supabase code is intentionally preserved. Re-enable it with:
  /// flutter run --dart-define=CHEZMOI_BACKEND=supabase
  static const useSupabase = backend == 'supabase';
  static const isTemplate = !useSupabase;
}
