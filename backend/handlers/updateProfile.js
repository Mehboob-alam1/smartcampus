const bcrypt = require('bcryptjs');
const { getPool } = require('../lib/_db.js');
const { verifyRequest } = require('../lib/_auth.js');
const { handleOptions, json, getJsonBody } = require('../lib/_helpers.js');

module.exports = async (req, res) => {
  if (handleOptions(req, res)) return;
  if (req.method !== 'PUT' && req.method !== 'POST') {
    return json(res, 405, { error: 'Method not allowed' });
  }

  const auth = verifyRequest(req);
  if (!auth) return json(res, 401, { error: 'Unauthorized' });

  try {
    const body = await getJsonBody(req);
    const name = body.name != null ? String(body.name).trim() : null;
    const newPassword = body.newPassword != null ? String(body.newPassword) : '';
    const currentPassword = body.currentPassword != null ? String(body.currentPassword) : '';

    const pool = getPool();
    const cur = await pool.query(
      `SELECT id, name, email, password, is_admin FROM users WHERE id = $1`,
      [auth.userId]
    );
    if (cur.rows.length === 0) {
      return json(res, 404, { error: 'User not found' });
    }
    const row = cur.rows[0];

    let nextName = row.name;
    let nextHash = row.password;

    if (name !== null) {
      if (!name) return json(res, 400, { error: 'Name cannot be empty' });
      nextName = name;
    }

    if (newPassword) {
      if (newPassword.length < 6) {
        return json(res, 400, { error: 'New password must be at least 6 characters' });
      }
      if (!currentPassword) {
        return json(res, 400, { error: 'currentPassword required when changing password' });
      }
      const ok = await bcrypt.compare(currentPassword, row.password);
      if (!ok) return json(res, 401, { error: 'Current password is incorrect' });
      nextHash = await bcrypt.hash(newPassword, 10);
    }

    if (nextName === row.name && nextHash === row.password) {
      return json(res, 400, { error: 'Nothing to update' });
    }

    const upd = await pool.query(
      `UPDATE users SET name = $1, password = $2 WHERE id = $3 RETURNING id, name, email, is_admin`,
      [nextName, nextHash, auth.userId]
    );
    const u = upd.rows[0];
    return json(res, 200, {
      user: {
        id: u.id,
        name: u.name,
        email: u.email,
        isAdmin: u.is_admin === true || u.is_admin === 't',
      },
    });
  } catch (e) {
    console.error(e);
    return json(res, 500, { error: 'Server error' });
  }
};
