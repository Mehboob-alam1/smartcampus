"""
Flask API for face registration and verification (OpenCV + DeepFace).
Run: pip install -r requirements.txt && python app.py
"""
import base64
import io
import os
import tempfile

from flask import Flask, request, jsonify
from flask_cors import CORS
from deepface import DeepFace

import model

app = Flask(__name__)
CORS(app)

BACKEND = "opencv"
MODEL_NAME = "Facenet"  # lighter than Facenet512; change if needed


def _decode_image(image_base64: str) -> str:
    raw = base64.b64decode(image_base64)
    fd, path = tempfile.mkstemp(suffix=".jpg")
    os.close(fd)
    with open(path, "wb") as f:
        f.write(raw)
    return path


def _represent(image_path: str) -> list:
    reps = DeepFace.represent(
        img_path=image_path,
        model_name=MODEL_NAME,
        enforce_detection=True,
        detector_backend=BACKEND,
    )
    if not reps:
        raise ValueError("No face detected")
    return reps[0]["embedding"]


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"ok": True})


@app.route("/register-face", methods=["POST"])
def register_face():
    try:
        data = request.get_json(force=True, silent=True) or {}
        user_id = int(data.get("user_id"))
        b64 = data.get("image_base64")
        if not b64:
            return jsonify({"error": "image_base64 required"}), 400
        path = _decode_image(b64)
        try:
            emb = _represent(path)
        finally:
            try:
                os.remove(path)
            except OSError:
                pass
        model.save_embedding(user_id, emb)
        return jsonify({"success": True, "message": "embedding saved"})
    except Exception as e:
        return jsonify({"error": str(e)}), 400


@app.route("/verify-face", methods=["POST"])
def verify_face():
    try:
        data = request.get_json(force=True, silent=True) or {}
        user_id = int(data.get("user_id"))
        b64 = data.get("image_base64")
        if not b64:
            return jsonify({"error": "image_base64 required"}), 400
        if model.load_embedding(user_id) is None:
            return jsonify({"error": "No registered face for this user", "matched": False}), 400

        path = _decode_image(b64)
        try:
            emb = _represent(path)
        finally:
            try:
                os.remove(path)
            except OSError:
                pass

        matched, distance = model.verify_match(user_id, emb)
        return jsonify({"matched": bool(matched), "distance": distance})
    except Exception as e:
        return jsonify({"error": str(e), "matched": False}), 400


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=True)
