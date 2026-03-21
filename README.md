# fu_prix_yi_tollou_ta

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


# 🛒 Fou Prix - Yi Tollou Tay

Application mobile Flutter pour consulter et comparer les prix des produits dans différents marchés au Sénégal.

## 🎯 Fonctionnalités

### Accès Public (sans connexion)
- ✅ Consulter tous les produits
- ✅ Voir les prix par marché et ville
- ✅ Comparer les prix entre différentes villes
- ✅ Rechercher des produits
- ✅ Filtrer par ville et catégorie

### Utilisateurs Connectés
- ✅ Toutes les fonctionnalités publiques
- ✅ Ajouter des prix pour les produits
- ✅ Ajouter de nouveaux produits
- ✅ Ajouter de nouveaux marchés
- ✅ Voir son historique de contributions
- ✅ Gérer son profil

## 📋 Prérequis

- Flutter SDK (>= 3.0.0)
- Un compte Supabase (gratuit)
- Un compte Twilio pour l'authentification SMS (gratuit pour tester)

## 🚀 Installation

### 1. Cloner et configurer le projet Flutter

```bash
# Créer le projet
flutter create fou_prix
cd fou_prix

# Copier tous les fichiers fournis dans le projet
```

### 2. Installer les dépendances

Remplacez le contenu de `pubspec.yaml` avec le fichier fourni, puis :

```bash
flutter pub get
```

### 3. Configurer Supabase (clés API)

Le fichier **`lib/config/supabase_config.dart`** n’est **pas** versionné (contient l’URL et la clé anon de **votre** projet).

1. Copiez le modèle :
   ```bash
   cp lib/config/supabase_config.example.dart lib/config/supabase_config.dart
   ```
2. Ouvrez `lib/config/supabase_config.dart` et renseignez **Project URL** et **anon public key** (dashboard Supabase → *Settings* → *API*).

Si le fichier était déjà suivi par Git avec d’anciennes clés, retirez-le de l’index une fois :
```bash
git rm --cached lib/config/supabase_config.dart
```

#### A. Créer un projet Supabase

1. Allez sur [https://supabase.com](https://supabase.com)
2. Créez un compte (gratuit)
3. Cliquez sur "New Project"
4. Donnez un nom à votre projet (ex: `fou-prix`)
5. Choisissez un mot de passe sécurisé
6. Sélectionnez la région la plus proche (ex: Europe West)
7. Cliquez sur "Create new project"

#### B. Créer les tables

1. Dans votre projet Supabase, allez dans **SQL Editor**
2. Cliquez sur "New Query"
3. Copiez-collez le script SQL suivant :

```sql
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

-- Policies : Lecture publique
CREATE POLICY "Lecture publique villes" ON villes FOR SELECT USING (true);
CREATE POLICY "Lecture publique marches" ON marches FOR SELECT USING (true);
CREATE POLICY "Lecture publique produits" ON produits FOR SELECT USING (true);
CREATE POLICY "Lecture publique prix" ON prix FOR SELECT USING (true);

-- Policies : Insertion pour utilisateurs authentifiés
CREATE POLICY "Utilisateurs peuvent ajouter marches" ON marches 
  FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Utilisateurs peuvent ajouter produits" ON produits 
  FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Utilisateurs peuvent ajouter prix" ON prix 
  FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Policies : User profiles
CREATE POLICY "Users can view own profile" ON user_profiles 
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles 
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles 
  FOR UPDATE USING (auth.uid() = id);

-- Fonction pour incrémenter les contributions
CREATE OR REPLACE FUNCTION increment_contributions(user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE user_profiles 
  SET contributions_count = contributions_count + 1 
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

4. Cliquez sur "Run" pour exécuter le script

#### C. Activer l'authentification par téléphone

1. Dans Supabase, allez dans **Authentication** > **Providers**
2. Activez **Phone**
3. Deux options :

**Option A - Twilio (recommandé pour la production)**
- Créez un compte sur [https://www.twilio.com](https://www.twilio.com)
- Obtenez vos clés Account SID et Auth Token
- Obtenez un numéro de téléphone Twilio
- Entrez ces informations dans Supabase

**Option B - Test sans SMS (pour développement)**
- Laissez vide et utilisez les "Test OTP" dans Supabase
- Allez dans Authentication > Settings > SMS Provider
- Activez "Test OTP mode"

#### D. Récupérer vos clés API

1. Dans Supabase, allez dans **Settings** > **API**
2. Copiez :
   - **Project URL** (ex: `https://xxxxx.supabase.co`)
   - **anon/public key** (commence par `eyJ...`)

3. Ouvrez `lib/config/supabase_config.dart` et remplacez :

```dart
static const String supabaseUrl = 'VOTRE_URL_ICI';
static const String supabaseAnonKey = 'VOTRE_CLE_ICI';
```

### 4. Ajouter des données de test

Pour tester rapidement, ajoutez quelques données :

```sql
-- Dans SQL Editor de Supabase

-- Ajouter des marchés
INSERT INTO marches (nom, ville_id) VALUES 
  ('Marché Sandaga', (SELECT id FROM villes WHERE nom = 'Dakar')),
  ('Marché Tilène', (SELECT id FROM villes WHERE nom = 'Dakar')),
  ('Marché HLM', (SELECT id FROM villes WHERE nom = 'Dakar')),
  ('Marché Central', (SELECT id FROM villes WHERE nom = 'Thiès')),
  ('Marché Touba Mosque', (SELECT id FROM villes WHERE nom = 'Touba'));

-- Ajouter des produits
INSERT INTO produits (nom, categorie) VALUES 
  ('Riz brisé', 'Céréales'),
  ('Riz parfumé', 'Céréales'),
  ('Oignon', 'Légumes'),
  ('Tomate', 'Légumes'),
  ('Pomme de terre', 'Légumes'),
  ('Poisson Thiof', 'Poissons'),
  ('Poulet', 'Viandes'),
  ('Banane', 'Fruits'),
  ('Mangue', 'Fruits');
```

### 5. Lancer l'application

```bash
# Android
flutter run

# iOS
flutter run
```

## 📱 Utilisation

### Pour les utilisateurs non connectés
1. Ouvrir l'app
2. Parcourir les produits
3. Cliquer sur un produit pour voir les prix
4. Filtrer par ville ou catégorie

### Pour ajouter des prix
1. Cliquer sur "Se connecter"
2. Entrer votre numéro de téléphone (+221 77 XXX XX XX)
3. Entrer le code reçu par SMS
4. Aller sur un produit
5. Cliquer sur "Ajouter un prix"
6. Remplir le formulaire et enregistrer

## 🎨 Personnalisation

### Modifier les couleurs

Éditez `lib/config/app_theme.dart` :

```dart
static const Color primaryGreen = Color(0xFF00853E);
static const Color primaryYellow = Color(0xFFFCD116);
static const Color primaryRed = Color(0xFFE31B23);
```

### Ajouter des villes

Dans Supabase SQL Editor :

```sql
INSERT INTO villes (nom) VALUES ('Ziguinchor'), ('Saint-Louis');
```

## 🐛 Dépannage

### Erreur de connexion à Supabase
- Vérifiez que les clés dans `supabase_config.dart` sont correctes
- Vérifiez votre connexion internet
- Vérifiez que le projet Supabase est actif

### SMS non reçu
- Vérifiez que Twilio est configuré
- Vérifiez votre crédit Twilio
- Activez le mode "Test OTP" pour le développement

### Erreur lors de l'ajout de prix
- Vérifiez que vous êtes connecté
- Vérifiez que les tables ont les bonnes policies
- Regardez les logs dans Supabase

## 📄 License

MIT License - Libre d'utilisation

## 👥 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
- Signaler des bugs
- Proposer des fonctionnalités
- Améliorer la documentation

## 📞 Support

Pour toute question, ouvrez une issue sur GitHub.

---

Fait avec ❤️ pour le Sénégal 🇸🇳