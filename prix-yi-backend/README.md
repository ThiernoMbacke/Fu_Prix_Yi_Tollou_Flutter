# Prix Yi Backend

Backend Spring Boot 3 (Kotlin) pour **Fou Prix - Yi Tollou Tay** : auth OTP par SMS (Infobip/Orange), JWT, rate limiting, PostgreSQL (Supabase).

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

2. **Base de données**

Exécuter le script SQL dans Supabase (SQL Editor) :

```bash
# Fichier : scripts/supabase-schema.sql
```

3. **Gradle**

Générer le wrapper si besoin (une fois) : `gradle wrapper` (avec Gradle installé), ou ouvrir le projet dans IntelliJ IDEA / Android Studio qui proposera de créer le wrapper.

```bash
./gradlew bootRun
# ou sous Windows
gradlew.bat bootRun
```

Sans Redis : l’app peut démarrer si Redis est désactivé (à adapter dans `application.yml` si besoin). Avec Redis, le rate limiting et le stockage OTP fonctionnent.

## Endpoints

- `POST /api/auth/send-otp` — Envoyer OTP (body: `{ "phoneNumber": "+221771234567" }`)
- `POST /api/auth/verify-otp` — Vérifier OTP (body: `{ "phoneNumber", "code" }`)
- `POST /api/auth/refresh-token` — Rafraîchir les tokens
- `POST /api/auth/logout` — Déconnexion
- `GET /api/users/me` — Profil (JWT)
- `PUT /api/users/me` — Mise à jour profil (JWT)
- `GET /api/users/stats` — Stats utilisateur (JWT)
- `POST /api/prix` — Ajouter un prix (JWT)
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
