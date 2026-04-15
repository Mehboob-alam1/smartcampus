const { getPool } = require('./_db.js');
const { verifyRequest } = require('./_auth.js');
const { handleOptions, json } = require('./_helpers.js');

module.exports = async (req, res) => {
  if (handleOptions(req, res)) return;
  if (req.method !== 'GET') return json(res, 405, { error: 'Method not allowed' });

  const auth = verifyRequest(req);
  if (!auth) return json(res, 401, { error: 'Unauthorized' });

  try {
    const pool = getPool();
    const all = req.query && (req.query.all === 'true' || req.query.all === '1');
    let result;
    if (all && auth.isAdmin) {
      result = await pool.query(
        `SELECT c.id, c.user_id, c.category, c.description, c.status, c.created_at, u.name AS user_name
         FROM complaints c
         JOIN users u ON u.id = c.user_id
         ORDER BY c.created_at DESC`
      );
    } else {
      result = await pool.query(
        `SELECT id, user_id, category, description, status, created_at
         FROM complaints WHERE user_id = $1 ORDER BY created_at DESC`,
        [auth.userId]
      );
    }

    const complaints = result.rows.map((r) => ({
      id: r.id,
      userId: r.user_id,
      category: r.category,
      description: r.description,
      status: r.status,
      createdAt: r.created_at,
      userName: r.user_name || undefined,
    }));
    return json(res, 200, { complaints });
  } catch (e) {
    console.error(e);
    return json(res, 500, { error: 'Server error' });
  }
};
