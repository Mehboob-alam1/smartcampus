const { getPool } = require('../lib/_db.js');
const { verifyRequest } = require('../lib/_auth.js');
const { handleOptions, json } = require('../lib/_helpers.js');

module.exports = async (req, res) => {
  if (handleOptions(req, res)) return;
  if (req.method !== 'GET') return json(res, 405, { error: 'Method not allowed' });

  const auth = verifyRequest(req);
  if (!auth || !auth.isAdmin) {
    return json(res, 403, { error: 'Admin only' });
  }

  try {
    const pool = getPool();
    const result = await pool.query(
      `SELECT id, name, email, is_admin FROM users ORDER BY id ASC`
    );
    const users = result.rows.map((u) => ({
      id: u.id,
      name: u.name,
      email: u.email,
      isAdmin: u.is_admin === true || u.is_admin === 't',
    }));
    return json(res, 200, { users });
  } catch (e) {
    console.error(e);
    return json(res, 500, { error: 'Server error' });
  }
};
