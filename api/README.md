# Craie API

API REST de l'application Craie (gestion des salles et du matériel).
**Fastify + Prisma + PostgreSQL**, TypeScript. Documentation interactive : `/docs` (Swagger).

## Lancer en local

```bash
cd api
npm ci
cp .env.example .env        # puis remplir DATABASE_URL, JWT_SECRET, ADMIN_IDENTIFIER, ADMIN_PASSWORD
npx prisma generate
npm run migrate             # crée les tables
npm run seed                # admin + données de démonstration
npm run dev                 # http://localhost:3000  (docs : /docs)
```

- `JWT_SECRET` : au moins 32 caractères, par exemple `openssl rand -base64 48`.
- Le serveur refuse de démarrer si une variable obligatoire manque.
- Comptes de démonstration (mot de passe `1234` en développement) : `seth@mail.com` (gestionnaire),
  `10080345` (Ariane ALIZEE, responsable IM-3), `10080346` (Miguel MIGAN, responsable IM-2).
  L'admin est celui défini par `ADMIN_IDENTIFIER` / `ADMIN_PASSWORD`.

| Script | Rôle |
| --- | --- |
| `npm run dev` | serveur avec rechargement automatique |
| `npm run build` | `prisma generate` puis compilation vers `dist/` |
| `npm start` | applique les migrations puis lance `dist/server.js` |
| `npm run migrate` | `prisma migrate deploy` |
| `npm run seed` / `seed:prod` | admin + démo (idempotent) |
| `npm run lint` / `npm run format` | ESLint / Prettier |
| `npm test` | tests (voir plus bas) |

## Base de données Neon

1. Créer un projet sur neon.tech (gratuit), copier la chaîne de connexion **directe** (sans `-pooler`).
2. Retirer `&channel_binding=require` de l'URL si présent ; garder `sslmode=require`.
3. La coller dans `DATABASE_URL` de `.env`, puis `npm run migrate` et `npm run seed` depuis votre PC
   (le plan gratuit de Render n'a pas de terminal : le seed se lance d'ici, une seule fois).

## Déployer sur Render

Nouveau **Web Service** relié au dépôt GitHub :

| Réglage | Valeur |
| --- | --- |
| Root Directory | `api` |
| Build Command | `npm ci --include=dev && npm run build` |
| Start Command | `npm start` (applique les migrations puis démarre) |
| Health Check Path | `/health` |

Variables d'environnement : `DATABASE_URL`, `JWT_SECRET`, `NODE_ENV=production`
(`PORT` est fourni par Render). Optionnelles : `CORS_ORIGIN`, `LOGIN_RATE_LIMIT`.

Le plan gratuit endort le service après ~15 min d'inactivité (premier appel lent, jusqu'à ~50 s) :
un ping toutes les 10 min sur `/health` (UptimeRobot, gratuit) évite l'endormissement.

## Règles métier

- Rôles : `admin` (comptes), `gestionnaire` (ressources, voit/libère toutes les réservations),
  `responsable` (réserve, voit/libère les siennes). Erreurs au format `{ "code", "message" }` (français).
- Réservations **d'aujourd'hui uniquement** (fuseau `Africa/Porto-Novo`, UTC+1 : constante
  `TIMEZONE_OFFSET_MINUTES` dans `src/lib/time.ts`), durée minimale 30 minutes.
- Deux réservations actives ne peuvent pas se chevaucher sur la même ressource : contrainte
  d'exclusion PostgreSQL (migration), donc valable même avec deux requêtes simultanées.
- Libération automatique : les listes ignorent toute réservation terminée, et une tâche
  (toutes les minutes) la marque `expired`.
- Suspendre ou supprimer un compte libère ses réservations ; l'historique est conservé
  (`user_name` est copié dans la réservation).
- Supprimer une ressource la masque (suppression logique) et libère ses réservations.
- Jetons : accès JWT 15 min ; refresh 7 jours, à usage unique (rotation), stocké haché.
  Un refresh déjà utilisé qui revient ferme toutes les sessions de l'utilisateur.
- Mots de passe hachés (argon2), jamais renvoyés par l'API.

## Tests

```bash
npm test                    # tests unitaires seulement (règles de créneau, jetons, variables d'environnement)
```

Les tests d'API (49 au total avec les unitaires) ont besoin d'une base PostgreSQL **jetable et locale**,
car ils vident les tables. Exemple avec Docker :

```bash
docker run -d --name craie-pg -e POSTGRES_PASSWORD=motdepasse -e POSTGRES_DB=craie_test \
  -p 127.0.0.1:55432:5432 postgres:16-alpine
export TEST_DATABASE_URL=postgresql://postgres:motdepasse@127.0.0.1:55432/craie_test
npm test
```

Les tests refusent une URL Neon/Render. L'heure est figée (10 h au Bénin) pour être reproductibles.

## Contrat avec l'application Flutter

- Préfixe `/api/v1`. Authentification : `Authorization: Bearer <accessToken>`.
- `POST /auth/login` → `{ accessToken, refreshToken, user }` ; `POST /auth/refresh` → `{ accessToken, refreshToken }` ;
  `POST /auth/logout` `{ refreshToken }` → 204 ; `GET /me`.
- Codes d'erreur : `INVALID_CREDENTIALS` (401), `ACCOUNT_SUSPENDED` (403 au login, 401 ensuite),
  `INVALID_REFRESH_TOKEN` (401), `FORBIDDEN` (403), `NOT_FOUND` (404), `IDENTIFIER_TAKEN`,
  `SLOT_CONFLICT`, `RESOURCE_BROKEN`, `NOT_ACTIVE` (409), `VALIDATION_ERROR`, `FILIERE_REQUIRED`,
  `FILIERE_NOT_ALLOWED`, `CLASSE_REQUIRED`, `START_AFTER_END`, `SLOT_TOO_SHORT`, `SLOT_NOT_TODAY`,
  `SLOT_IN_PAST` (422), `RATE_LIMITED` (429).
- `isTaken` d'une ressource = elle a une réservation active qui n'est pas encore terminée.
- Les champs qui ne concernent pas le type (ex. `zone` pour un matériel) valent `null`.
