# Smart Campus — Backend API (Vercel + PostgreSQL)

One **Serverless Function** entry (`api/[...slug].js`) dispatches to handlers under `handlers/` (Vercel **Hobby** allows at most **12** functions per deployment; a separate file per route would exceed that). Shared code lives in `lib/`.

The Flutter app still calls the same URLs: `https://<your-deployment>.vercel.app/api/login`, `/api/getComplaints`, etc.

### Layout

| Path | Role |
|------|------|
| `api/[...slug].js` | Router only (counts as **1** function) |
| `handlers/*.js` | Route logic (not separate Vercel functions) |
| `lib/_db.js`, `lib/_auth.js`, `lib/_helpers.js` | DB pool, JWT, CORS/JSON helpers |
| `public/` | Static landing page |

## Prerequisites

1. **PostgreSQL** database (e.g. [Neon](https://neon.tech), [Supabase](https://supabase.com), or [Vercel Postgres](https://vercel.com/storage/postgres)).
2. **Python face service** running somewhere public **HTTPS** URL (see `../face_service/README.md`). Vercel cannot host the DeepFace app in the same way (heavy CPU/GPU, long cold starts).
3. **Vercel account** and [Vercel CLI](https://vercel.com/docs/cli): `npm i -g vercel`.

## Database setup

From the **repository root** (where `schema.sql` lives):

```bash
psql "$DATABASE_URL" -f ../schema.sql
```

**Default admin** (created by `schema.sql`; re-running the file only ensures `is_admin = true` for this email—it does not reset the password if the user already exists):

| Field | Value |
|--------|--------|
| Email | `admin.smartcampus@gmail.com` |
| Password | `AdminSmartCampus2026!` |

Log in with **`POST /api/login`** (or the Flutter app), then **change the password** under **My profile** before production use.

To make another email an admin instead:

```sql
UPDATE users SET is_admin = true WHERE email = 'other@example.com';
```

## Local development

```bash
cd backend
npm install
cp .env.example .env
# Edit .env: DATABASE_URL, JWT_SECRET, PYTHON_FACE_URL (e.g. http://127.0.0.1:5000)
npx vercel dev
```

Default local URL is often `http://localhost:3000`. Endpoints look like:

- `POST http://localhost:3000/api/login`
- `GET http://localhost:3000/api/getComplaints`

## Deploy to Vercel

### If you linked the wrong project (e.g. `pnpm install` errors)

The CLI stores the link in **`.vercel/`**. Remove it and link again:

```bash
cd backend
rm -rf .vercel
npx vercel
```

When asked **“Link to existing project?”** choose **No** (or pick **Create new project**), then give a new name such as `smartcampus-api`.  
This repo’s backend uses **npm** (`package-lock.json`); `vercel.json` sets `"installCommand": "npm install"` so Vercel does not use another project’s pnpm setting.

### Option A — Deploy from this folder (recommended)

1. Open a terminal in **`backend/`** (this directory).

2. Log in and link a project:

   ```bash
   vercel login
   vercel
   ```

   Follow prompts: **create a new project** (do not link to an unrelated app like “athena”), confirm scope, accept defaults. Repeat `vercel` for production:

   ```bash
   vercel --prod
   ```

3. In the [Vercel dashboard](https://vercel.com/dashboard) → your project → **Settings → Environment Variables**, add (for **Production** and **Preview** as needed):

   | Name | Example |
   |------|---------|
   | `DATABASE_URL` | `postgresql://...` |
   | `JWT_SECRET` | Long random string (do not commit) |
   | `PYTHON_FACE_URL` | `https://your-face-service.onrender.com` (no trailing slash) |

4. **Redeploy** after saving env vars: **Deployments → … → Redeploy**, or run `vercel --prod` again.

### Option B — Monorepo: set “Root Directory” to `backend`

If the Git repo root is the whole `smartcampus` folder (Flutter + backend):

1. Import the repo in Vercel.
2. **Project → Settings → General → Root Directory** → set to `backend`.
3. Add the same environment variables as above.
4. Deploy.

## Flutter app URL

After deployment, your API base URL is:

`https://<project-name>.vercel.app`

Run Flutter with:

```bash
flutter run --dart-define=API_BASE_URL=https://<project-name>.vercel.app
```

(No trailing slash.)

## Troubleshooting

- **“No more than 12 Serverless Functions” (Hobby)**: This project is built so only **`api/[...slug].js`** is deployed as a function. Do not add many new `api/*.js` files; add a handler under `handlers/` and register it in `[...slug].js`, or upgrade to Pro / a team plan.
- **502 on registerFace / markAttendance**: `PYTHON_FACE_URL` wrong, face service down, or face service not reachable from Vercel (must be **public HTTPS** for production).
- **Database SSL errors**: Hosted Postgres usually needs SSL; `lib/_db.js` enables SSL when not localhost.
- **CORS**: Handlers send `Access-Control-Allow-Origin: *` for mobile dev.
