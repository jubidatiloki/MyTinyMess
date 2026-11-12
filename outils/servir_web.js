// Petit serveur pour afficher la version web construite (build/web).
// Usage : node outils/servir_web.js [port]
const http = require('http');
const fs = require('fs');
const path = require('path');
const racine = path.join(__dirname, '..', 'build', 'web');
const port = Number(process.argv[2] || 8082);
const types = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json',
  '.png': 'image/png', '.jpg': 'image/jpeg', '.otf': 'font/otf', '.ttf': 'font/ttf',
  '.wasm': 'application/wasm', '.css': 'text/css', '.svg': 'image/svg+xml' };
http.createServer((req, res) => {
  let p = decodeURIComponent(req.url.split('?')[0]);
  let f = path.normalize(path.join(racine, p));
  if (!f.startsWith(racine)) { res.writeHead(403); return res.end(); }
  if (!fs.existsSync(f) || fs.statSync(f).isDirectory()) f = path.join(racine, 'index.html');
  res.writeHead(200, { 'Content-Type': types[path.extname(f)] || 'application/octet-stream' });
  fs.createReadStream(f).pipe(res);
}).listen(port, () => console.log('http://localhost:' + port));
