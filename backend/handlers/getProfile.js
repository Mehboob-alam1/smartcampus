const { getPool } = require('../lib/_db.js');
const { verifyRequest } = require('../lib/_auth.js');
const { handleOptions, json } = require('../lib/_helpers.js');

module.exports = async (req, res) => {
  if (handleOptions(req, res)) return;
  if (req.method !== 'GET') return json(res, 405, { error: 'Method not allowed' });

  const auth = verifyRequest(req);
  if (!auth) return json(res, 401, { error: 'Unauthorized' });

  try {
    const pool = getPool();
    const result = await pool.query(
      `SELECT id, name, email, is_admin FROM users WHERE id = $1`,
      [auth.userId]
    );
    if (result.rows.length === 0) {
      return json(res, 404, { error: 'User not found' });
    }
    const u = result.rows[0];
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
