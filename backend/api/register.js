const bcrypt = require('bcryptjs');
const { getPool } = require('./_db.js');
const { signToken } = require('./_auth.js');
const { handleOptions, json, getJsonBody } = require('./_helpers.js');

module.exports = async (req, res) => {
  if (handleOptions(req, res)) return;
  if (req.method !== 'POST') return json(res, 405, { error: 'Method not allowed' });

  try {
    const body = await getJsonBody(req);
    const name = (body.name || '').trim();
    const email = (body.email || '').trim().toLowerCase();
    const password = body.password || '';
    if (!name || !email || !password || password.length < 6) {
      return json(res, 400, { error: 'Invalid name, email, or password (min 6 chars)' });
    }

    const pool = getPool();
    const hash = await bcrypt.hash(password, 10);
    const result = await pool.query(
      `INSERT INTO users (name, email, password) VALUES ($1, $2, $3) RETURNING id, name, email, is_admin`,
      [name, email, hash]
    );
    const user = result.rows[0];
    const token = signToken(user);
    return json(res, 201, {
      token,
      user: { id: user.id, name: user.name, email: user.email, isAdmin: user.is_admin },
    });
  } catch (e) {
    if (e.code === '23505') {
      return json(res, 409, { error: 'Email already registered' });
    }
    console.error(e);
    return json(res, 500, { error: 'Server error' });
  }
};
