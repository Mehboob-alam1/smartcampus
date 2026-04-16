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
      `SELECT id, user_id, date, status FROM attendance WHERE user_id = $1 ORDER BY date DESC`,
      [auth.userId]
    );
    const records = result.rows.map((r) => ({
      id: r.id,
      userId: r.user_id,
      date: r.date,
      status: r.status,
    }));
    return json(res, 200, { attendance: records });
  } catch (e) {
    console.error(e);
    return json(res, 500, { error: 'Server error' });
  }
};
