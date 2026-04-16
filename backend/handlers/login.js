const bcrypt = require('bcryptjs');
const { getPool } = require('../lib/_db.js');
const { signToken } = require('../lib/_auth.js');
const { handleOptions, json, getJsonBody } = require('../lib/_helpers.js');

module.exports = async (req, res) => {
  if (handleOptions(req, res)) return;
  if (req.method !== 'POST') return json(res, 405, { error: 'Method not allowed' });

  try {
    const body = await getJsonBody(req);
    const email = (body.email || '').trim().toLowerCase();
    const password = body.password || '';
    if (!email || !password) {
      return json(res, 400, { error: 'Email and password required' });
    }

    const pool = getPool();
    const result = await pool.query(
      `SELECT id, name, email, password, is_admin FROM users WHERE email = $1`,
      [email]
    );
    if (result.rows.length === 0) {
      return json(res, 401, { error: 'Invalid email or password' });
    }
    const user = result.rows[0];
    const ok = await bcrypt.compare(password, user.password);
    if (!ok) {
      return json(res, 401, { error: 'Invalid email or password' });
    }

    const token = signToken(user);
    return json(res, 200, {
      token,
      user: { id: user.id, name: user.name, email: user.email, isAdmin: user.is_admin },
    });
  } catch (e) {
    console.error(e);
    return json(res, 500, { error: 'Server error' });
  }
};
