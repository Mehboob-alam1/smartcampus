/**
 * Single Serverless Function entry (Vercel Hobby: max 12 functions per deployment).
 * URLs stay the same: /api/login, /api/getComplaints, …
 */
const { handleOptions, json } = require('../lib/_helpers.js');

const routes = {
  login: require('../handlers/login.js'),
  register: require('../handlers/register.js'),
  getComplaints: require('../handlers/getComplaints.js'),
  addComplaint: require('../handlers/addComplaint.js'),
  updateComplaint: require('../handlers/updateComplaint.js'),
  getAttendance: require('../handlers/getAttendance.js'),
  registerFace: require('../handlers/registerFace.js'),
  markAttendance: require('../handlers/markAttendance.js'),
  getProfile: require('../handlers/getProfile.js'),
  updateProfile: require('../handlers/updateProfile.js'),
  getUsers: require('../handlers/getUsers.js'),
  adminUpdateUser: require('../handlers/adminUpdateUser.js'),
  deleteUser: require('../handlers/deleteUser.js'),
  deleteComplaint: require('../handlers/deleteComplaint.js'),
  getAllAttendance: require('../handlers/getAllAttendance.js'),
};

function firstSegment(req) {
  const q = req.query && req.query.slug;
  let raw = '';
  if (q != null) {
    raw = Array.isArray(q) ? q.join('/') : String(q);
  } else {
    const url = (req.url || '').split('?')[0];
    const m = url.match(/^\/api\/([^/]+)/);
    raw = m ? m[1] : '';
  }
  const name = (raw || '').split('/')[0];
  return name || '';
}

module.exports = async (req, res) => {
  if (handleOptions(req, res)) return;

  const name = firstSegment(req);
  const handler = routes[name];

  if (!handler) {
    return json(res, 404, { error: 'Unknown route', route: name || null });
  }

  return handler(req, res);
};
