const { getPool } = require('../lib/_db.js');
const { verifyRequest } = require('../lib/_auth.js');
const { handleOptions, json, getJsonBody } = require('../lib/_helpers.js');

const STATUSES = ['pending', 'resolved'];

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
    const status = (body.status || '').toLowerCase().trim();
    if (!id || !STATUSES.includes(status)) {
      return json(res, 400, { error: 'Invalid id or status (pending|resolved)' });
    }

    const pool = getPool();
    const result = await pool.query(
      `UPDATE complaints SET status = $1 WHERE id = $2 RETURNING id, user_id, category, description, status, created_at`,
      [status, id]
    );
    if (result.rows.length === 0) {
      return json(res, 404, { error: 'Complaint not found' });
    }
    const row = result.rows[0];
    return json(res, 200, {
      complaint: {
        id: row.id,
        userId: row.user_id,
        category: row.category,
        description: row.description,
        status: row.status,
        createdAt: row.created_at,
      },
    });
  } catch (e) {
    console.error(e);
    return json(res, 500, { error: 'Server error' });
  }
};
