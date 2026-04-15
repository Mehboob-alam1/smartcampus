"""
Face embeddings: save/load as NumPy arrays on disk (one file per user_id).
Verification uses cosine similarity between stored embedding and a new capture.
"""
from __future__ import annotations

import os
from typing import Optional, Tuple

import numpy as np

EMBED_DIR = os.path.join(os.path.dirname(__file__), "embeddings")
# Typical DeepFace embedding length (Facenet512)
SIMILARITY_THRESHOLD = 0.35  # cosine distance; lower = stricter (DeepFace uses distance)


def _path(user_id: int) -> str:
    os.makedirs(EMBED_DIR, exist_ok=True)
    return os.path.join(EMBED_DIR, f"{int(user_id)}.npy")


def save_embedding(user_id: int, embedding: list) -> None:
    arr = np.array(embedding, dtype=np.float32)
    np.save(_path(user_id), arr)


def load_embedding(user_id: int) -> Optional[np.ndarray]:
    p = _path(user_id)
    if not os.path.isfile(p):
        return None
    return np.load(p)


def cosine_distance(a: np.ndarray, b: np.ndarray) -> float:
    a = a.flatten()
    b = b.flatten()
    denom = (np.linalg.norm(a) * np.linalg.norm(b)) or 1.0
    sim = float(np.dot(a, b) / denom)
    return 1.0 - sim  # distance in [0, 2] roughly


def verify_match(user_id: int, new_embedding: list) -> Tuple[bool, float]:
    stored = load_embedding(user_id)
    if stored is None:
        return False, -1.0
    new_arr = np.array(new_embedding, dtype=np.float32)
    dist = cosine_distance(stored, new_arr)
    matched = dist < SIMILARITY_THRESHOLD
    return matched, float(dist)
