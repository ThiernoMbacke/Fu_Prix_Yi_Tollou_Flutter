# Mode démo et vérification Supabase — Fu Prix Yi Tollou

## 1. Mode démo (sans code OTP)

Deux **utilisateurs test** permettent de se connecter sans envoyer de SMS ni saisir de code :

| Bouton  | Identifiant | Utilisation |
|---------|-------------|-------------|
| **Test 1** | `test1` | Connexion démo → peut ajouter des prix |
| **Test 2** | `test2` | Connexion démo → peut ajouter des prix |

### Côté app

- Sur l’écran **Se connecter**, section **« Mode démo (sans code) »** : cliquer sur **Test 1** ou **Test 2**.
- Aucun numéro ni code demandé : connexion directe à l’accueil, avec possibilité d’ajouter des prix (produit, marché, montant).

### Côté backend

- Le backend expose **POST /api/auth/demo** avec le body : `{ "demoUser": "test1" }` ou `"test2"`.
- Les utilisateurs sont créés à la volée dans la table **users** (téléphones réservés : +221770000001, +221770000002).
- Aucune configuration supplémentaire : il suffit que le backend soit démarré et que l’app pointe vers lui (`ApiConfig.baseUrl`).

---

## 2. Vérifier que le projet pointe vers votre base Supabase

### 2.1 Configuration actuelle (Flutter)

Fichier **`lib/config/supabase_config.dart`** :

- **supabaseUrl** : `https://byrlinkbmyhfvdwqhhlm.supabase.co`
- **supabaseAnonKey** : clé anon (publique) du projet

L’app Flutter utilise cette URL et cette clé pour lire les données (villes, marchés, produits, prix) et pour l’init Supabase au démarrage.

### 2.2 Vérification dans le dashboard Supabase

1. Aller sur **https://supabase.com/dashboard** et ouvrir le projet qui contient vos données (villes, marchés, produits, prix).
2. **Settings** (Paramètres) → **API** :
   - **Project URL** doit être **exactement** :  
     `https://byrlinkbmyhfvdwqhhlm.supabase.co`
   - **Project API keys** → **anon public** : la valeur doit être **identique** à `SupabaseConfig.supabaseAnonKey` dans `supabase_config.dart`.
3. Si l’URL ou la clé diffèrent : soit mettre à jour `supabase_config.dart` avec les valeurs du dashboard, soit créer un projet Supabase dont l’URL est celle ci-dessus et y importer vos données.

### 2.3 Vérification rapide des données

Dans Supabase : **Table Editor** (ou **SQL Editor**).

- Vérifier que les tables existent : **villes**, **marches**, **produits**, **prix**.
- Exemple de test en SQL :
  ```sql
  SELECT id, nom FROM villes LIMIT 5;
  ```
- Si l’app affiche des villes/marchés/produits au lancement, la lecture Supabase fonctionne.

### 2.4 Backend et base Supabase

Le backend Spring Boot utilise la **même base** Supabase (PostgreSQL) :

- Fichier **`prix-yi-backend/src/main/resources/application.yml`** :
  - `spring.datasource.url` : hôte du type `db.byrlinkbmyhfvdwqhhlm.supabase.co` (ou variable d’environnement `SUPABASE_DB_HOST`).
- Les **prix** ajoutés via l’app (après connexion démo ou OTP) sont enregistrés par le backend dans la table **prix** de cette base.
- La table **users** (utilisateurs backend, dont les deux comptes démo) doit exister dans la même base : script **`prix-yi-backend/scripts/supabase-schema.sql`** à exécuter dans le **SQL Editor** Supabase si ce n’est pas déjà fait.

---

## 3. Récapitulatif

| Élément | Où vérifier |
|--------|-------------|
| Projet Supabase utilisé par l’app | `lib/config/supabase_config.dart` → URL = Project URL du dashboard |
| Clé anon | `supabase_config.dart` → anon key = clé « anon public » du dashboard |
| Tables (villes, marches, produits, prix, users) | Supabase → Table Editor ou SQL Editor |
| Backend (même base) | `application.yml` → `datasource.url` / `SUPABASE_DB_*` |
| Connexion démo | Écran « Se connecter » → **Test 1** ou **Test 2** (backend doit être lancé) |

Si l’URL et la clé anon dans `supabase_config.dart` correspondent à celles du dashboard et que les tables existent, le projet pointe bien vers votre base Supabase.
