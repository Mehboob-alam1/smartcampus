const { getPool } = require('../lib/_db.js');
const { verifyRequest } = require('../lib/_auth.js');
const { handleOptions, json, getJsonBody } = require('../lib/_helpers.js');

async function callPythonVerify(userId, imageBase64) {
  const base = process.env.PYTHON_FACE_URL || 'http://127.0.0.1:5000';
  const url = `${base.replace(/\/$/, '')}/verify-face`;
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

    const verify = await callPythonVerify(auth.userId, imageBase64);
    if (!verify.matched) {
      return json(res, 403, { error: 'Face not matched', matched: false });
    }

    const pool = getPool();
    const today = new Date().toISOString().slice(0, 10);
    const dup = await pool.query(
      `SELECT id FROM attendance WHERE user_id = $1 AND date = $2::date`,
      [auth.userId, today]
    );
    if (dup.rows.length > 0) {
      return json(res, 200, {
        message: 'Already marked present today',
        attendance: { id: dup.rows[0].id, date: today, status: 'present' },
      });
    }

    const ins = await pool.query(
      `INSERT INTO attendance (user_id, date, status) VALUES ($1, $2::date, 'present') RETURNING id, user_id, date, status`,
      [auth.userId, today]
    );
    const row = ins.rows[0];
    return json(res, 201, {
      matched: true,
      attendance: { id: row.id, userId: row.user_id, date: row.date, status: row.status },
    });
  } catch (e) {
    console.error(e);
    const msg = e.message || 'Server error';
    if (msg.includes('Face service')) {
      return json(res, 502, { error: msg });
    }
    return json(res, 500, { error: msg });
  }
};
