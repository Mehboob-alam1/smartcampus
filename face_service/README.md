# Smart Campus — Face recognition service (Flask + DeepFace)

This is a **separate long-running HTTP service**, not a Vercel function. It stores face embeddings on disk under `embeddings/`.

## Run locally

```bash
cd face_service
python -m venv .venv
source .venv/bin/activate    # Windows: .venv\Scripts\activate
pip install -r requirements.txt
python app.py
```

Default: `http://127.0.0.1:5000`

- `POST /register-face` — JSON: `{ "user_id": 1, "image_base64": "..." }`
- `POST /verify-face` — JSON: `{ "user_id": 1, "image_base64": "..." }` → `{ "matched": true/false, ... }`
- `GET /health` — health check

Point your **backend** `PYTHON_FACE_URL` at this URL when developing (e.g. `http://127.0.0.1:5000`). For a phone on the same Wi‑Fi, use your PC’s LAN IP (e.g. `http://192.168.1.10:5000`) and ensure the firewall allows port 5000.

## Why not on Vercel?

Vercel serverless functions have **size limits**, **short timeouts**, and **no persistent disk** suited to TensorFlow/DeepFace and storing embeddings. This service should run on a **VM, container platform, or PaaS that supports long-lived processes and (preferably) a persistent volume**.

## Deploy options (production-style)

### 1. [Railway](https://railway.app) or [Render](https://render.com) (beginner-friendly)

1. Create a new **Web Service** from this repo (or only the `face_service` folder).
2. **Build command**: `pip install -r requirements.txt` (set root to `face_service` if needed).
3. **Start command**: `gunicorn app:app --bind 0.0.0.0:$PORT`  
   - Add to `requirements.txt`: `gunicorn==22.0.0`
4. Attach a **persistent disk** (or use cloud storage later) so `embeddings/` survives restarts.
5. Copy the public HTTPS URL (e.g. `https://smartcampus-face.onrender.com`) into Vercel **`PYTHON_FACE_URL`** (no trailing slash).

### 2. [Fly.io](https://fly.io) / Google **Cloud Run** / AWS **ECS**

Package the app in a **Docker** image, run one container with enough **memory (2GB+)** for DeepFace, mount a volume for `embeddings/`.

### 3. Demo only — [ngrok](https://ngrok.com)

Expose local port 5000 to the internet so Vercel can call it (temporary URL, good for demos):

```bash
ngrok http 5000
```

Set `PYTHON_FACE_URL` to the `https://....ngrok-free.app` URL in Vercel (note: free tier URLs change unless you use a fixed domain).

## Production notes

- **HTTPS**: Vercel → your face service should use HTTPS in production.
- **Security**: This sample trusts the backend to send the correct `user_id`. For stronger security, add a shared secret header checked by Flask, or only allow requests from your Vercel backend IPs (harder on serverless).
- **Threshold**: Tune `SIMILARITY_THRESHOLD` in `model.py` if matches are too strict or too loose.

## Optional: Gunicorn (for Render/Railway)

Add to `requirements.txt`:

```
gunicorn==22.0.0
```

Start:

```bash
gunicorn app:app --bind 0.0.0.0:${PORT:-5000} --workers 1 --threads 2 --timeout 120
```

Use **one worker** initially to avoid loading multiple TensorFlow models into RAM.
