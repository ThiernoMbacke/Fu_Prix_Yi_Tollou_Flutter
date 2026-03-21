-- ============================================================
-- Schema Supabase pour Prix Yi Backend + Flutter
-- Exécuter dans Supabase SQL Editor
-- ============================================================

-- 1. Table users (remplace auth.users pour ce projet)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) UNIQUE NOT NULL,
    nom VARCHAR(100),
    role VARCHAR(20) DEFAULT 'USER',
    is_active BOOLEAN DEFAULT true,
    contributions_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 2. Refresh tokens
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    token VARCHAR(500) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    is_revoked BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token ON refresh_tokens(token);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id);

-- 3. OTP attempts (anti-fraude)
CREATE TABLE IF NOT EXISTS otp_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) NOT NULL,
    ip_address VARCHAR(50),
    attempts INT DEFAULT 1,
    last_attempt TIMESTAMP DEFAULT NOW(),
    is_blocked BOOLEAN DEFAULT false
);
CREATE INDEX IF NOT EXISTS idx_otp_attempts_phone ON otp_attempts(phone);
CREATE INDEX IF NOT EXISTS idx_otp_attempts_ip ON otp_attempts(ip_address);

-- 4. Tables métier (si pas déjà créées)
CREATE TABLE IF NOT EXISTS villes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Régions du Sénégal (référence seule : pas d’API de création dans l’app)
CREATE TABLE IF NOT EXISTS regions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS marches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom TEXT NOT NULL,
    ville_id UUID REFERENCES villes(id) ON DELETE CASCADE,
    adresse TEXT DEFAULT '' NOT NULL,
    latitude FLOAT,
    longitude FLOAT,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS produits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nom TEXT NOT NULL,
    categorie TEXT NOT NULL,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Unicité (insensible à la casse) — aligné avec ProduitService / MarcheService
CREATE UNIQUE INDEX IF NOT EXISTS produits_nom_categorie_lower_unique
    ON produits (lower(trim(nom)), lower(trim(categorie)));
CREATE UNIQUE INDEX IF NOT EXISTS marches_ville_nom_lower_unique
    ON marches (ville_id, lower(trim(nom)))
    WHERE ville_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS prix (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    produit_id UUID REFERENCES produits(id) ON DELETE CASCADE NOT NULL,
    marche_id UUID REFERENCES marches(id) ON DELETE CASCADE NOT NULL,
    prix DECIMAL(10,2) NOT NULL,
    date DATE DEFAULT CURRENT_DATE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    -- Option premium : contact, localisation GPS et paiement
    contact_phone VARCHAR(20),
    contact_location TEXT,
    contact_lat DOUBLE PRECISION,
    contact_lng DOUBLE PRECISION,
    is_premium BOOLEAN DEFAULT FALSE,
    premium_amount INT,
    payment_method TEXT,
    payment_reference TEXT,
    premium_paid_at TIMESTAMP
);

-- 5. Migrer created_by si vous aviez auth.users (optionnel)
-- ALTER TABLE marches DROP CONSTRAINT IF EXISTS marches_created_by_fkey;
-- ALTER TABLE marches ADD CONSTRAINT marches_created_by_fkey FOREIGN KEY (created_by) REFERENCES users(id);
-- Idem pour produits, prix si nécessaire.

-- 6. Données initiales villes (si vide)
INSERT INTO villes (nom) VALUES 
  ('Dakar'), ('Thiès'), ('Kaolack'), ('Touba')
ON CONFLICT (nom) DO NOTHING;

-- 6b. Régions administratives du Sénégal (14) — gestion en base uniquement
INSERT INTO regions (nom) VALUES
  ('Dakar'),
  ('Diourbel'),
  ('Fatick'),
  ('Kaffrine'),
  ('Kaolack'),
  ('Kédougou'),
  ('Kolda'),
  ('Louga'),
  ('Matam'),
  ('Saint-Louis'),
  ('Sédhiou'),
  ('Tambacounda'),
  ('Thiès'),
  ('Ziguinchor')
ON CONFLICT (nom) DO NOTHING;

-- 7. RLS (optionnel si tout passe par le backend)
-- Pour garder Supabase Flutter en lecture seule sur villes/marches/produits/prix :
ALTER TABLE villes ENABLE ROW LEVEL SECURITY;
ALTER TABLE regions ENABLE ROW LEVEL SECURITY;
ALTER TABLE marches ENABLE ROW LEVEL SECURITY;
ALTER TABLE produits ENABLE ROW LEVEL SECURITY;
ALTER TABLE prix ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lecture publique villes" ON villes;
CREATE POLICY "Lecture publique villes" ON villes FOR SELECT USING (true);
DROP POLICY IF EXISTS "Lecture publique regions" ON regions;
CREATE POLICY "Lecture publique regions" ON regions FOR SELECT USING (true);
DROP POLICY IF EXISTS "Lecture publique marches" ON marches;
CREATE POLICY "Lecture publique marches" ON marches FOR SELECT USING (true);
DROP POLICY IF EXISTS "Lecture publique produits" ON produits;
CREATE POLICY "Lecture publique produits" ON produits FOR SELECT USING (true);
DROP POLICY IF EXISTS "Lecture publique prix" ON prix;
CREATE POLICY "Lecture publique prix" ON prix FOR SELECT USING (true);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Service role only users" ON users;
CREATE POLICY "Service role only users" ON users FOR ALL USING (false);
