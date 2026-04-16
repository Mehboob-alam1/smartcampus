const { getPool } = require('../lib/_db.js');
const { verifyRequest } = require('../lib/_auth.js');
const { handleOptions, json, getJsonBody } = require('../lib/_helpers.js');

const ALLOWED = ['hostel', 'transport', 'cafeteria', 'other'];

module.exports = async (req, res) => {
  if (handleOptions(req, res)) return;
  if (req.method !== 'POST') return json(res, 405, { error: 'Method not allowed' });

  const auth = verifyRequest(req);
  if (!auth) return json(res, 401, { error: 'Unauthorized' });

  try {
    const body = await getJsonBody(req);
    const category = (body.category || '').toLowerCase().trim();
    const description = (body.description || '').trim();
    if (!ALLOWED.includes(category)) {
      return json(res, 400, { error: 'Invalid category' });
    }
    if (!description) {
      return json(res, 400, { error: 'Description required' });
    }

    const pool = getPool();
    const result = await pool.query(
      `INSERT INTO complaints (user_id, category, description, status)
       VALUES ($1, $2, $3, 'pending')
       RETURNING id, category, description, status, created_at`,
      [auth.userId, category, description]
    );
    const row = result.rows[0];
    return json(res, 201, {
      complaint: {
        id: row.id,
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
