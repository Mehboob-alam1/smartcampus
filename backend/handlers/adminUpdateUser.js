const { getPool } = require('../lib/_db.js');
const { verifyRequest, signToken } = require('../lib/_auth.js');
const { handleOptions, json, getJsonBody } = require('../lib/_helpers.js');

module.exports = async (req, res) => {
  if (handleOptions(req, res)) return;
  if (req.method !== 'POST' && req.method !== 'PUT') {
    return json(res, 405, { error: 'Method not allowed' });
  }

  const auth = verifyRequest(req);
  if (!auth || !auth.isAdmin) {
    return json(res, 403, { error: 'Admin only' });
  }

  try {
    const body = await getJsonBody(req);
    const id = parseInt(body.id, 10);
    if (!id) return json(res, 400, { error: 'Invalid id' });

    const name = body.name !== undefined ? String(body.name).trim() : undefined;
    const email = body.email !== undefined ? String(body.email).trim().toLowerCase() : undefined;
    const isAdmin =
      body.isAdmin !== undefined
        ? body.isAdmin === true || body.isAdmin === 'true' || body.isAdmin === 1
        : undefined;

    if (name === undefined && email === undefined && isAdmin === undefined) {
      return json(res, 400, { error: 'Provide name, email, and/or isAdmin' });
    }
    if (name !== undefined && !name) return json(res, 400, { error: 'Name cannot be empty' });
    if (email !== undefined && !email) return json(res, 400, { error: 'Email cannot be empty' });

    const pool = getPool();

    if (isAdmin === false && id === auth.userId) {
      const admins = await pool.query(
        `SELECT COUNT(*)::int AS c FROM users WHERE is_admin = true`
      );
      if (admins.rows[0].c <= 1) {
        return json(res, 400, { error: 'Cannot remove admin from the only admin account' });
      }
    }

    const cur = await pool.query(`SELECT id FROM users WHERE id = $1`, [id]);
    if (cur.rows.length === 0) return json(res, 404, { error: 'User not found' });

    const sets = [];
    const vals = [];
    let i = 1;
    if (name !== undefined) {
      sets.push(`name = $${i++}`);
      vals.push(name);
    }
    if (email !== undefined) {
      sets.push(`email = $${i++}`);
      vals.push(email);
    }
    if (isAdmin !== undefined) {
      sets.push(`is_admin = $${i++}`);
      vals.push(isAdmin);
    }
    vals.push(id);

    const result = await pool.query(
      `UPDATE users SET ${sets.join(', ')} WHERE id = $${i} RETURNING id, name, email, is_admin`,
      vals
    );
    const u = result.rows[0];
    const userPayload = {
      id: u.id,
      name: u.name,
      email: u.email,
      isAdmin: u.is_admin === true || u.is_admin === 't',
    };
    const out = { user: userPayload };
    if (id === auth.userId) {
      out.token = signToken(u);
    }
    return json(res, 200, out);
  } catch (e) {
    if (e.code === '23505') {
      return json(res, 409, { error: 'Email already in use' });
    }
    console.error(e);
    return json(res, 500, { error: 'Server error' });
  }
};
