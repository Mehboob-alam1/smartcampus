const jwt = require('jsonwebtoken');

function signToken(user) {
  const secret = process.env.JWT_SECRET;
  if (!secret) throw new Error('JWT_SECRET is not set');
  const admin = user.is_admin === true || user.is_admin === 't';
  return jwt.sign(
    { userId: user.id, email: user.email, isAdmin: admin },
    secret,
    { expiresIn: '7d' }
  );
}

function verifyRequest(req) {
  const secret = process.env.JWT_SECRET;
  if (!secret) return null;
  const auth = req.headers.authorization || '';
  const m = auth.match(/^Bearer\s+(.+)$/i);
  if (!m) return null;
  try {
    const payload = jwt.verify(m[1], secret);
    return { userId: payload.userId, email: payload.email, isAdmin: !!payload.isAdmin };
  } catch {
    return null;
  }
}

module.exports = { signToken, verifyRequest };
