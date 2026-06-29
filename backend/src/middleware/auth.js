// ---------------------------------------------------------------------------
// User-scoping middleware.
//
// Every per-user request must carry the caller's Firebase UID. The Flutter
// client attaches it as the `x-firebase-uid` header (see ApiClient interceptor)
// for all requests once signed in; we also accept it from the JSON body or the
// query string as a fallback (e.g. the very first /api/auth/login call).
//
// SECURITY NOTE: This trusts the UID provided by the client. For production
// hardening you should verify a Firebase ID token here with `firebase-admin`
// (admin.auth().verifyIdToken) and derive the UID from the decoded token
// instead of trusting the header. That requires a service-account credential
// and is intentionally left as a follow-up so deployment isn't blocked.
// ---------------------------------------------------------------------------

function resolveUid(req) {
  return (
    req.headers['x-firebase-uid'] ||
    (req.body && req.body.firebaseUid) ||
    (req.query && req.query.firebaseUid) ||
    ''
  )
    .toString()
    .trim();
}

// Attaches `req.firebaseUid` when present (does not reject). Useful for routes
// that can work with or without a user.
function attachUser(req, _res, next) {
  req.firebaseUid = resolveUid(req);
  logRequest(req);
  next();
}

// Rejects the request with 401 when no Firebase UID is present.
function requireUser(req, res, next) {
  const uid = resolveUid(req);
  if (!uid) {
    return res.status(401).json({
      success: false,
      message: 'Authentication required: missing Firebase UID.',
    });
  }
  req.firebaseUid = uid;
  logRequest(req);
  next();
}

function logRequest(req) {
  const uid = req.firebaseUid || '(none)';
  const email = req.headers['x-user-email'] || '(none)';
  const phone = req.headers['x-user-phone'] || '(none)';
  console.log(
    `[REQ] ${req.method} ${req.originalUrl} | uid=${uid} email=${email} phone=${phone}`
  );
}

module.exports = { attachUser, requireUser, resolveUid };
