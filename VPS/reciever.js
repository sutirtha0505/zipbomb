// receiver.js
const express = require('express');
const multer = require('multer');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const fs = require('fs');
const path = require('path');

const UPLOAD_DIR = path.resolve(__dirname, 'incoming');
if (!fs.existsSync(UPLOAD_DIR)) fs.mkdirSync(UPLOAD_DIR, { recursive: true });

const app = express();
app.use(helmet());

// Basic rate limiter
const limiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 30, // max requests per IP per window
});
app.use(limiter);

// Simple auth middleware (Bearer token). Replace with real auth.
const AUTH_TOKEN = process.env.RECEIVER_TOKEN || 'MySuperSecretAUTHTokenForZipBomb';
function requireAuth(req, res, next) {
  const auth = req.headers['authorization'];
  if (!auth || !auth.startsWith('Bearer ')) return res.status(401).json({ error: 'Missing auth' });
  const token = auth.slice(7);
  if (token !== AUTH_TOKEN) return res.status(403).json({ error: 'Invalid token' });
  next();
}

// Multer config: disk storage + file size limit (e.g., 50 MB)
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, UPLOAD_DIR),
  filename: (req, file, cb) => {
    const ts = Date.now();
    const safeName = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
    cb(null, `${ts}_${safeName}`);
  },
});
const upload = multer({
  storage,
  limits: { fileSize: 50 * 1024 * 1024 }, // 50 MB
  fileFilter: (req, file, cb) => {
    // allow any extension but you can check file.mimetype
    cb(null, true);
  },
});

// POST /upload — field name "file"
app.post('/upload', requireAuth, upload.single('file'), (req, res) => {
  if (!req.file) return res.status(400).json({ error: 'No file received' });

  // Server-side: schedule or run a scan here (antivirus, zip inspection).
  // For safety, do not unzip user archives on the same host without sandboxing.
  const saved = req.file.path;
  console.log(`Received file ${req.file.originalname} -> ${saved}, size=${req.file.size}`);

  // TODO: enqueue saved for scanning/processing
  res.status(201).json({ message: 'Uploaded', filename: path.basename(saved) });
});

// Health endpoint
app.get('/health', (req, res) => res.json({ ok: true }));

const PORT = process.env.PORT || 8443;
app.listen(PORT, () => console.log(`Receiver listening on port ${PORT}`));
