const path = require('path');
const fs = require('fs');

const uploadsPath = path.join(__dirname, 'uploads');
const uploadsPathFromSrc = path.join(__dirname, '../uploads');

console.log('__dirname:', __dirname);
console.log('Path from root (backend/uploads):', uploadsPath);
console.log('Path from src (backend/src/../uploads):', uploadsPathFromSrc);

console.log('Exists (backend/uploads)?', fs.existsSync(uploadsPath));
console.log('Exists (backend/src/../uploads)?', fs.existsSync(uploadsPathFromSrc));

if (fs.existsSync(uploadsPathFromSrc)) {
  console.log('Contents of backend/uploads:', fs.readdirSync(uploadsPathFromSrc));
  const docsPath = path.join(uploadsPathFromSrc, 'documents');
  if (fs.existsSync(docsPath)) {
    console.log('Contents of backend/uploads/documents:', fs.readdirSync(docsPath));
  }
}
