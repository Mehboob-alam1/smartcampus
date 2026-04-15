# Smart Campus — Complaint & attendance (Flutter + Node + Postgres + Python)

| Part | Location | Role |
|------|----------|------|
| **Mobile app** | `lib/` (Flutter) | JWT login, complaints, attendance photos → REST |
| **Backend API** | **`backend/`** | Vercel serverless routes, PostgreSQL, calls face service |
| **Face ML** | **`face_service/`** | Flask + DeepFace: `/register-face`, `/verify-face` |
| **Database** | `schema.sql` (repo root) | PostgreSQL tables |

## Quick links

- **Backend (Vercel deploy, env vars, local `vercel dev`):** [`backend/README.md`](backend/README.md)
- **Face service (where to host, gunicorn, ngrok):** [`face_service/README.md`](face_service/README.md)

## Typical dev order

1. Create DB → `psql "$DATABASE_URL" -f schema.sql`
2. Run face service: `cd face_service && pip install -r requirements.txt && python app.py`
3. Run API: `cd backend && npm install && cp .env.example .env` → edit `.env` → `npx vercel dev`
4. Run Flutter: `flutter pub get` → `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000` (Android emulator)

## Deploy summary

- **Backend:** Deploy the **`backend`** folder to Vercel (see `backend/README.md`). Set `DATABASE_URL`, `JWT_SECRET`, `PYTHON_FACE_URL`.
- **Face service:** **Not** on Vercel — use Railway, Render, Fly.io, Cloud Run, or ngrok for demos (see `face_service/README.md`).
