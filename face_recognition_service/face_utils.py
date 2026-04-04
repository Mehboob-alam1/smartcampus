"""
Utilità per face recognition: registrazione embedding e verifica volto.
Usa OpenCV per il rilevamento e DeepFace per gli embedding.
"""
import os
import json
from pathlib import Path
from typing import Any, Dict, Optional

import numpy as np

# Cartella dove salvare gli embedding per utente (in produzione usare DB)
EMBEDDINGS_DIR = Path(__file__).parent / "embeddings"
EMBEDDINGS_DIR.mkdir(exist_ok=True)


def get_embedding_path(user_id: str) -> Path:
    return EMBEDDINGS_DIR / f"{user_id}.json"


def warmup_deepface() -> None:
    """
    Load TensorFlow/Keras + Facenet weights once at process startup.
    Without this, the *first* /register or /verify after server start can take
    minutes (model download + TF init + weight load).
    """
    try:
        from deepface import DeepFace

        DeepFace.build_model("Facenet")
    except Exception:
        pass


def get_face_embedding(image_path: str) -> Optional[np.ndarray]:
    """Extract face embedding with DeepFace Facenet."""
    try:
        from deepface import DeepFace
        # opencv detector is much faster than retinaface/mtcnn on CPU; good enough for frontal ID photos.
        result = DeepFace.represent(
            img_path=image_path,
            model_name="Facenet",
            enforce_detection=True,
            detector_backend="opencv",
        )
        if result and len(result) > 0:
            return np.array(result[0]["embedding"], dtype=np.float32)
    except Exception:
        pass
    return None


def save_embedding(user_id: str, user_email: str, user_name: str, embedding: np.ndarray) -> None:
    """Salva l'embedding per un utente."""
    path = get_embedding_path(user_id)
    data = {
        "user_id": user_id,
        "user_email": user_email,
        "user_name": user_name,
        "embedding": embedding.tolist(),
    }
    with open(path, "w") as f:
        json.dump(data, f)


def load_embedding(user_id: str) -> Optional[np.ndarray]:
    """Carica l'embedding salvato per un utente."""
    path = get_embedding_path(user_id)
    if not path.exists():
        return None
    with open(path) as f:
        data = json.load(f)
    return np.array(data["embedding"], dtype=np.float32)


def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    """Similarità coseno tra due vettori."""
    return float(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b) + 1e-8))


def verify_face(image_path: str, threshold: float = 0.6) -> Optional[Dict[str, Any]]:
    """
    Verifica il volto nell'immagine contro tutti gli embedding registrati.
    Restituisce {"user_id", "user_email", "user_name", "confidence"} se trovato, altrimenti None.
    """
    embedding = get_face_embedding(image_path)
    if embedding is None:
        return None

    best_match = None
    best_score = threshold

    for path in EMBEDDINGS_DIR.glob("*.json"):
        user_id = path.stem
        try:
            with open(path) as f:
                data = json.load(f)
            stored = np.array(data["embedding"], dtype=np.float32)
            score = cosine_similarity(embedding, stored)
            if score > best_score:
                best_score = score
                best_match = {
                    "user_id": data["user_id"],
                    "user_email": data["user_email"],
                    "user_name": data["user_name"],
                    "confidence": round(score, 4),
                }
        except Exception:
            continue

    return best_match
