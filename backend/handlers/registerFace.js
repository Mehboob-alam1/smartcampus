/**
 * Saves face embedding via Python service (call once per user before markAttendance).
 */
const { verifyRequest } = require('../lib/_auth.js');
const { handleOptions, json, getJsonBody } = require('../lib/_helpers.js');

async function callPythonRegister(userId, imageBase64) {
  const base = process.env.PYTHON_FACE_URL || 'http://127.0.0.1:5000';
  const url = `${base.replace(/\/$/, '')}/register-face`;
  const r = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ user_id: userId, image_base64: imageBase64 }),
  });
  const text = await r.text();
  let data;
  try {
    data = JSON.parse(text);
  } catch {
    throw new Error(`Face service error: ${text.slice(0, 200)}`);
  }
  if (!r.ok) {
    throw new Error(data.error || `Face service HTTP ${r.status}`);
  }
  return data;
}

module.exports = async (req, res) => {
  if (handleOptions(req, res)) return;
  if (req.method !== 'POST') return json(res, 405, { error: 'Method not allowed' });

  const auth = verifyRequest(req);
  if (!auth) return json(res, 401, { error: 'Unauthorized' });

  try {
    const body = await getJsonBody(req);
    const imageBase64 = body.imageBase64;
    if (!imageBase64 || typeof imageBase64 !== 'string') {
      return json(res, 400, { error: 'imageBase64 required' });
    }
    await callPythonRegister(auth.userId, imageBase64);
    return json(res, 200, { success: true, message: 'Face registered' });
  } catch (e) {
    console.error(e);
    return json(res, 502, { error: e.message || 'Face registration failed' });
  }
};
