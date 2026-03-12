const multer = require('multer');
const path = require('path');

const ALLOWED_MIMES = [
  'image/jpeg',
  'image/jpg',
  'image/pjpeg',
  'image/png',
  'image/gif',
  'image/webp',
];

const ALLOWED_EXT = ['.jpg', '.jpeg', '.jpe', '.png', '.gif', '.webp'];

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 Mo
  fileFilter: (req, file, cb) => {
    const mimetype = (file.mimetype || '').toLowerCase();
    const ext = path.extname(file.originalname || '').toLowerCase();
    const mimeOk = ALLOWED_MIMES.includes(mimetype);
    const extOk = ALLOWED_EXT.includes(ext);
    // Accepter si MIME connu OU si extension OK (certains clients envoient application/octet-stream)
    if (mimeOk || (extOk && (mimetype === '' || mimetype === 'application/octet-stream'))) {
      cb(null, true);
    } else {
      cb(new Error('Type de fichier non autorisé. Utilisez JPEG, PNG, GIF ou WebP.'), false);
    }
  },
});

module.exports = upload;
