class SupabaseConfig {
  // 🔴 IMPORTANT : Remplacez ces valeurs par vos propres clés Supabase
  // Allez sur https://supabase.com/dashboard/project/_/settings/api
  
  static const String supabaseUrl = 'https://byrlinkbmyhfvdwqhhlm.supabase.co'; // Ex: https://xxxxx.supabase.co
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ5cmxpbmtibXloZnZkd3FoaGxtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI4NzIyMDcsImV4cCI6MjA3ODQ0ODIwN30.61Juvaa-4iaKDyrbN_zcyR6F9EaCX5luelswIJ5HYWM';
  
  // Configuration des tables
  static const String villesTable = 'villes';
  static const String marchesTable = 'marches';
  static const String produitsTable = 'produits';
  static const String prixTable = 'prix';
  static const String userProfilesTable = 'user_profiles';
}

/* 
📝 ÉTAPES POUR CONFIGURER SUPABASE :

1. Créez un compte sur https://supabase.com
2. Créez un nouveau projet
3. Allez dans Settings > API
4. Copiez :
   - Project URL → supabaseUrl
   - anon/public key → supabaseAnonKey
5. Collez ces valeurs ci-dessus

6. Allez dans SQL Editor et exécutez ce script pour créer les tables :

-- Table villes
CREATE TABLE villes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nom TEXT NOT NULL UNIQUE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Table marches
CREATE TABLE marches (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nom TEXT NOT NULL,
  ville_id UUID REFERENCES villes(id) ON DELETE CASCADE,
  latitude FLOAT,
  longitude FLOAT,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Table produits
CREATE TABLE produits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nom TEXT NOT NULL,
  categorie TEXT NOT NULL,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Table prix
CREATE TABLE prix (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  produit_id UUID REFERENCES produits(id) ON DELETE CASCADE,
  marche_id UUID REFERENCES marches(id) ON DELETE CASCADE,
  prix DECIMAL(10,2) NOT NULL,
  date DATE DEFAULT CURRENT_DATE,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Table user_profiles
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  phone TEXT UNIQUE,
  nom TEXT,
  contributions_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Insert villes initiales
INSERT INTO villes (nom) VALUES 
  ('Dakar'),
  ('Thiès'),
  ('Kaolack'),
  ('Touba');

-- Activer Row Level Security
ALTER TABLE villes ENABLE ROW LEVEL SECURITY;
ALTER TABLE marches ENABLE ROW LEVEL SECURITY;
ALTER TABLE produits ENABLE ROW LEVEL SECURITY;
ALTER TABLE prix ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Policies : Tout le monde peut lire
CREATE POLICY "Lecture publique villes" ON villes FOR SELECT USING (true);
CREATE POLICY "Lecture publique marches" ON marches FOR SELECT USING (true);
CREATE POLICY "Lecture publique produits" ON produits FOR SELECT USING (true);
CREATE POLICY "Lecture publique prix" ON prix FOR SELECT USING (true);

-- Policies : Seuls les utilisateurs authentifiés peuvent insérer
CREATE POLICY "Utilisateurs peuvent ajouter marches" ON marches FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Utilisateurs peuvent ajouter produits" ON produits FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Utilisateurs peuvent ajouter prix" ON prix FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Policies : User profiles
CREATE POLICY "Users can view own profile" ON user_profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON user_profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON user_profiles FOR UPDATE USING (auth.uid() = id);

7. Pour activer l'authentification par téléphone :
   - Allez dans Authentication > Providers
   - Activez "Phone"
   - Configurez Twilio ou un autre fournisseur SMS
*/