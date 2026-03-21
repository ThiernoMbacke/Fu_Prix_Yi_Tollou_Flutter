/// Modèle de configuration Supabase (sans secrets).
///
/// **Première installation :**
/// ```bash
/// cp lib/config/supabase_config.example.dart lib/config/supabase_config.dart
/// ```
/// Puis remplissez [supabaseUrl] et [supabaseAnonKey] depuis le dashboard :
/// https://supabase.com/dashboard → votre projet → **Settings** → **API**
///
/// Le fichier `supabase_config.dart` est ignoré par Git (voir `.gitignore`).
///
/// **URL :** si Postgres = `db.abcdefgh.supabase.co`, l’URL API = `https://abcdefgh.supabase.co`
class SupabaseConfig {
  static const String supabaseUrl = 'https://VOTRE_REF.supabase.co';
  static const String supabaseAnonKey = 'VOTRE_CLE_ANON_PUBLIQUE_ICI';

  static bool get isPlaceholderConfiguration {
    final u = supabaseUrl.toLowerCase().trim();
    if (u.contains('votre_ref') ||
        u.contains('your_ref') ||
        u.contains('placeholder') ||
        !u.contains('.supabase.co')) {
      return true;
    }
    final k = supabaseAnonKey.trim();
    if (k.contains('VOTRE_CLE') || k.length < 80) {
      return true;
    }
    return false;
  }

  static const String villesTable = 'villes';
  static const String marchesTable = 'marches';
  static const String produitsTable = 'produits';
  static const String prixTable = 'prix';
  static const String userProfilesTable = 'user_profiles';
}
