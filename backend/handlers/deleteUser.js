const { getPool } = require('../lib/_db.js');
const { verifyRequest } = require('../lib/_auth.js');
const { handleOptions, json, getJsonBody } = require('../lib/_helpers.js');

module.exports = async (req, res) => {
  if (handleOptions(req, res)) return;
  if (req.method !== 'POST' && req.method !== 'DELETE') {
    return json(res, 405, { error: 'Method not allowed' });
  }

  const auth = verifyRequest(req);
  if (!auth || !auth.isAdmin) {
    return json(res, 403, { error: 'Admin only' });
  }

  try {
    let id;
    if (req.method === 'DELETE' && req.query && req.query.id) {
      id = parseInt(req.query.id, 10);
    } else {
      const body = await getJsonBody(req);
      id = parseInt(body.id, 10);
    }
    if (!id) return json(res, 400, { error: 'Invalid id' });

    if (id === auth.userId) {
      return json(res, 400, { error: 'Cannot delete your own account' });
    }

    const pool = getPool();
    const target = await pool.query(
      `SELECT id, is_admin FROM users WHERE id = $1`,
      [id]
    );
    if (target.rows.length === 0) {
      return json(res, 404, { error: 'User not found' });
    }
    if (target.rows[0].is_admin === true || target.rows[0].is_admin === 't') {
      const admins = await pool.query(
        `SELECT COUNT(*)::int AS c FROM users WHERE is_admin = true`
      );
      if (admins.rows[0].c <= 1) {
        return json(res, 400, { error: 'Cannot delete the only admin user' });
      }
    }

    await pool.query(`DELETE FROM users WHERE id = $1`, [id]);
    return json(res, 200, { success: true, message: 'User deleted' });
  } catch (e) {
    console.error(e);
    return json(res, 500, { error: 'Server error' });
  }
};
