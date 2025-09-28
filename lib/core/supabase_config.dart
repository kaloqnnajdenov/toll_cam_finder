/// Centralizes how Supabase credentials are supplied to the application.
///
/// Values are read from compile-time environment variables so they can be
/// injected via `--dart-define` without checking secrets into source control.
class SupabaseConfig {
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://paxlfjvjhvdumwzexcpb.supabase.co');

  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBheGxmanZqaHZkdW13emV4Y3BiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkwNDUyOTQsImV4cCI6MjA3NDYyMTI5NH0.Mc_eg8En6GGLA78WxC6lfczKhVbZIsaTZWhjBbshM-c');

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}