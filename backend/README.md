# Smart Campus — Backend API (Vercel + PostgreSQL)

Serverless Node.js routes under `api/`. The Flutter app calls `https://<your-deployment>.vercel.app/api/...`.

## Prerequisites

1. **PostgreSQL** database (e.g. [Neon](https://neon.tech), [Supabase](https://supabase.com), or [Vercel Postgres](https://vercel.com/storage/postgres)).
2. **Python face service** running somewhere public **HTTPS** URL (see `../face_service/README.md`). Vercel cannot host the DeepFace app in the same way (heavy CPU/GPU, long cold starts).
3. **Vercel account** and [Vercel CLI](https://vercel.com/docs/cli): `npm i -g vercel`.

## Database setup

From the **repository root** (where `schema.sql` lives):

```bash
psql "$DATABASE_URL" -f ../schema.sql
```

Promote an admin user:

```sql
UPDATE users SET is_admin = true WHERE email = 'your@email.com';
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

### Option A — Deploy from this folder (recommended)

1. Open a terminal in **`backend/`** (this directory).

2. Log in and link a project:

   ```bash
   vercel login
   vercel
   ```

   Follow prompts: create a new project, confirm scope, accept defaults. Repeat `vercel` for production:

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

- **502 on registerFace / markAttendance**: `PYTHON_FACE_URL` wrong, face service down, or face service not reachable from Vercel (must be **public HTTPS** for production).
- **Database SSL errors**: Hosted Postgres usually needs SSL; `api/_db.js` enables SSL when not localhost.
- **CORS**: Handlers send `Access-Control-Allow-Origin: *` for mobile dev.
