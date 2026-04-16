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
    const q = req.query || {};
    const userId = q.userId != null ? parseInt(q.userId, 10) : null;

    let result;
    if (userId) {
      result = await pool.query(
        `SELECT a.id, a.user_id, a.date, a.status, u.name AS user_name, u.email AS user_email
         FROM attendance a
         JOIN users u ON u.id = a.user_id
         WHERE a.user_id = $1
         ORDER BY a.date DESC`,
        [userId]
      );
    } else {
      result = await pool.query(
        `SELECT a.id, a.user_id, a.date, a.status, u.name AS user_name, u.email AS user_email
         FROM attendance a
         JOIN users u ON u.id = a.user_id
         ORDER BY a.date DESC, a.id DESC`
      );
    }

    const attendance = result.rows.map((r) => ({
      id: r.id,
      userId: r.user_id,
      date: r.date,
      status: r.status,
      userName: r.user_name,
      userEmail: r.user_email,
    }));
    return json(res, 200, { attendance });
  } catch (e) {
    console.error(e);
    return json(res, 500, { error: 'Server error' });
  }
};
