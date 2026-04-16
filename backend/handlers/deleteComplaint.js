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

    const pool = getPool();
    const result = await pool.query(
      `DELETE FROM complaints WHERE id = $1 RETURNING id`,
      [id]
    );
    if (result.rows.length === 0) {
      return json(res, 404, { error: 'Complaint not found' });
    }
    return json(res, 200, { success: true, message: 'Complaint deleted' });
  } catch (e) {
    console.error(e);
    return json(res, 500, { error: 'Server error' });
  }
};
