# Prix Yi Backend

Backend Spring Boot 3 (Kotlin) pour **Fou Prix - Yi Tollou Tay** : auth OTP par SMS (Infobip/Orange), JWT, rate limiting, PostgreSQL (Supabase).

### Développement : Chrome **et** téléphone physique (Test1, produits, marchés)

1. **Redis** joignable (`localhost:6379` ou Docker).
2. Lancer **`.\gradlew.bat bootRun`** : le profil **`local`** est appliqué **automatiquement** → API en **`http://…:8080`** (pas de HTTPS, pas de certificat).
3. **Chrome** : l’app Flutter web pointe vers `http://localhost:8080`.
4. **Téléphone** (même Wi‑Fi) : URL `http://<IPv4_du_PC>:8080` — régler `kPhysicalDeviceHost` dans Flutter ou **Configurer l’URL** dans l’app ; ouvrir le port **8080** au pare-feu Windows.

Guide détaillé : **`DEV_SETUP.md`** à la racine du projet Flutter.

Pour un **JAR / prod** sans profil `local`, le comportement par défaut reste **HTTPS** (`SSL_ENABLED` / keystore). `SPRING_PROFILES_ACTIVE=prod` utilise `application-prod.yml`.

## Prérequis

- JDK 17+
- Redis (local ou distant)
- PostgreSQL (Supabase)

## Configuration

1. **Variables d'environnement** (ou `application.yml`)

| Variable | Description |
|----------|-------------|
| `SUPABASE_DB_HOST` | Host Postgres Supabase |
| `SUPABASE_DB_PORT` | 5432 |
| `SUPABASE_DB_NAME` | postgres |
| `SUPABASE_DB_USER` | Utilisateur DB |
| `SUPABASE_DB_PASSWORD` | Mot de passe DB |
| `JWT_SECRET` | Secret JWT (min 32 caractères) |
| `REDIS_HOST` | localhost ou URL Redis |
| `REDIS_PORT` | 6379 |
| `SMS_PROVIDER` | infobip ou orange |
| `INFOBIP_API_KEY` | Clé API Infobip (optionnel en dev) |
| `ORANGE_CLIENT_ID` / `ORANGE_CLIENT_SECRET` | Orange SMS (optionnel) |
| `SSL_ENABLED` | `true` (défaut) = HTTPS avec le keystore ; `false` = HTTP seul (recommandé pour tester sur téléphone physique avec `http://IP_PC:8080`) |
| `SSL_KEYSTORE_PASSWORD` | Mot de passe du `.p12` si `SSL_ENABLED=true` |

2. **Base de données**

Exécuter le script SQL dans Supabase (SQL Editor) :

```bash
# Fichier : scripts/supabase-schema.sql
```

Migrations optionnelles (bases déjà créées) :

- **`scripts/ensure-unique-produits-marches.sql`** — index uniques (produit : nom+catégorie ; marché : nom par ville). À exécuter après avoir supprimé ou fusionné les doublons existants.
- **`scripts/ensure-regions-senegal.sql`** — table `regions` + les **14 régions administratives** du Sénégal (référence en base uniquement ; pas de création depuis l’app).

**Règles métier (API)** : pas de doublon de **produit** (même nom + même catégorie, sans tenir compte de la casse), ni de **marché** (même nom dans la même ville). Les **villes** ont déjà `nom UNIQUE` en base. Les **régions** servent de référence ; pour lier une ville à une région plus tard, on pourra ajouter une colonne `region_id` sur `villes` (non implémenté pour l’instant).

3. **Gradle**

Générer le wrapper si besoin (une fois) : `gradle wrapper` (avec Gradle installé), ou ouvrir le projet dans IntelliJ IDEA / Android Studio qui proposera de créer le wrapper.

**Lancer le backend (Windows)** — il faut définir le mot de passe Supabase avant `bootRun` :

**Invite de commandes (CMD) :**
```cmd
set SUPABASE_DB_PASSWORD=TON_MOT_DE_PASSE_ICI
gradlew.bat bootRun
```

**PowerShell :**
```powershell
$env:SUPABASE_DB_PASSWORD="TON_MOT_DE_PASSE_ICI"
.\gradlew.bat bootRun
```

**IntelliJ / JAR sans Gradle** : pour du HTTP comme `bootRun`, ajoutez `--spring.profiles.active=local` (voir `application-local.yml`).

Où trouver le mot de passe Supabase : [Supabase](https://supabase.com/dashboard) → ton projet → **Project Settings** → **Database** → **Database password** (celui défini à la création du projet, ou réinitialisable).

Sous Linux / macOS :
```bash
export SUPABASE_DB_PASSWORD=TON_MOT_DE_PASSE_ICI
./gradlew bootRun
```

Sans Redis : l’app peut démarrer si Redis est désactivé (à adapter dans `application.yml` si besoin). Avec Redis, le rate limiting et le stockage OTP fonctionnent.

### Produit / marche : erreur a l enregistrement (500)

- **42703 — column `created_by` does not exist** : la table a ete creee sans cette colonne. Executer **`scripts/add-missing-created-by-columns.sql`** dans Supabase (SQL Editor).
- **FK vers `users`** : si la FK pointe vers la mauvaise table, executer aussi **`scripts/fix-produits-marches-fkey.sql`**.

L API renvoie un JSON avec `message` en cas d erreur SQL.

### `bootRun` échoue tout de suite

1. **Schéma JPA** : par défaut `spring.jpa.hibernate.ddl-auto` vaut `none` (schéma géré en SQL sur Supabase). Pour réactiver la validation stricte : variable d’environnement `JPA_DDL_AUTO=validate`.
2. **Redis** : doit être joignable (`REDIS_HOST` / `REDIS_PORT`) si l’OTP est utilisé.
3. **HTTPS** : avec le profil **`local`**, le serveur est en HTTP ; le keystore ne sert que si `SSL_ENABLED=true` ou profil **`prod`** sans `local`.
4. Pour la **cause exacte** : `.\gradlew.bat bootRun --stacktrace` et lire la première `Caused by:`.

## Endpoints

- `POST /api/auth/send-otp` — Envoyer OTP (body: `{ "phoneNumber": "+221771234567" }`)
- `POST /api/auth/verify-otp` — Vérifier OTP (body: `{ "phoneNumber", "code" }`)
- `POST /api/auth/refresh-token` — Rafraîchir les tokens
- `POST /api/auth/logout` — Déconnexion
- `POST /api/auth/demo` — Connexion démo sans OTP (body: `{ "demoUser": "test1" }` ou `"test2"`)
- `GET /api/users/me` — Profil (JWT)
- `PUT /api/users/me` — Mise à jour profil (JWT)
- `GET /api/users/stats` — Stats utilisateur (JWT)
- `POST /api/prix` — Ajouter un prix (JWT)
- `POST /api/marches` — Créer un marché (JWT, body: `nom`, `villeId`, optionnel `latitude` / `longitude`)
- `POST /api/produits` — Créer un produit (JWT, body: `nom`, `categorie`)
- `GET /actuator/health` — Health check

## SMS (Infobip / Orange)

### Infobip

1. Créer un compte sur [Infobip](https://www.infobip.com/).
2. Récupérer une clé API (SMS).
3. Définir `SMS_PROVIDER=infobip` et `INFOBIP_API_KEY= votre_clé`.

En dev, si la clé n’est pas définie, le backend log le code OTP en console au lieu d’envoyer un SMS.

### Orange

1. S’inscrire à l’API SMS Orange (Afrique).
2. Renseigner `ORANGE_CLIENT_ID`, `ORANGE_CLIENT_SECRET`, `ORANGE_SENDER`.
3. Définir `SMS_PROVIDER=orange`.

L’implémentation Orange dans le code est un stub : à compléter avec l’OAuth2 et l’appel réel à l’API SMS Orange.

## Déploiement (Railway / Render / AWS)

1. **Backend** : déployer le JAR (build avec `./gradlew bootJar`) ou utiliser le `Dockerfile`.
2. **Redis** : utiliser Upstash, Redis Cloud ou une instance managée.
3. **PostgreSQL** : conserver Supabase.
4. **Variables** : définir toutes les variables d’environnement listées ci-dessus.
5. **Flutter** : configurer `API_BASE_URL` (ou équivalent) vers l’URL du backend en production.

## Docker

```bash
docker-compose up -d
```

Renseigner les variables dans un fichier `.env` ou dans `docker-compose.yml`.
