"""
API FastAPI per registrazione volto e verifica presenza.
L'app Flutter invia immagini qui; il servizio salva embedding (registrazione)
o confronta con gli embedding salvati (verifica) e restituisce l'utente riconosciuto.
"""
import asyncio
import os
import tempfile
from contextlib import asynccontextmanager

from fastapi import FastAPI, File, Form, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from face_utils import get_face_embedding, save_embedding, verify_face, warmup_deepface


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Preload ML models in a thread so the first user request is not stuck on cold start.
    loop = asyncio.get_event_loop()
    await loop.run_in_executor(None, warmup_deepface)
    yield


app = FastAPI(title="Smart Campus Face Recognition API", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.post("/register")
async def register_face(
    image: UploadFile = File(...),
    user_id: str = Form(...),
    user_email: str = Form(...),
    user_name: str = Form(""),
):
    """Registra il volto dell'utente. Salva l'embedding su disco."""
    suffix = os.path.splitext(image.filename or "")[1] or ".jpg"
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        content = await image.read()
        tmp.write(content)
        tmp_path = tmp.name
    try:
        embedding = get_face_embedding(tmp_path)
        if embedding is None:
            raise HTTPException(status_code=400, detail="No face detected or invalid image")
        save_embedding(user_id, user_email, user_name, embedding)
        return {"success": True, "message": "Face registered"}
    finally:
        os.unlink(tmp_path)


@app.post("/verify")
async def verify_face_attendance(
    image: UploadFile = File(...),
    session_id: str = Form(...),
    course_name: str = Form(""),
):
    """
    Verifica il volto nell'immagine e restituisce l'utente riconosciuto.
    L'app Flutter o un sistema esterno può poi marcare la presenza su Firestore.
    """
    suffix = os.path.splitext(image.filename or "")[1] or ".jpg"
    with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
        content = await image.read()
        tmp.write(content)
        tmp_path = tmp.name
    try:
        match = verify_face(tmp_path)
        if match is None:
            return {"success": False, "message": "Face not recognized"}
        return {
            "success": True,
            "user_id": match["user_id"],
            "user_email": match["user_email"],
            "user_name": match["user_name"],
            "confidence": match["confidence"],
            "session_id": session_id,
            "course_name": course_name,
        }
    finally:
        os.unlink(tmp_path)


@app.get("/health")
def health():
    return {"status": "ok"}
