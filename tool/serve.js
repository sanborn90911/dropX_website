// Serves the release build (build/web) to every device on the local network,
// for testing the site on a phone. No dependencies — needs only Node.js.
//
//   flutter build web --release
//   node tool/serve.js            (port 8080)
//   node tool/serve.js 9000       (any other port)

const http = require('http');
const fs = require('fs');
const os = require('os');
const path = require('path');

const port = Number(process.argv[2]) || 8080;
const root = path.join(__dirname, '..', 'build', 'web');

const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.css': 'text/css; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.bin': 'application/octet-stream',
  '.frag': 'application/octet-stream',
};

if (!fs.existsSync(path.join(root, 'index.html'))) {
  console.error(`No build found at ${root}. Run "flutter build web --release" first.`);
  process.exit(1);
}

http
  .createServer((req, res) => {
    const urlPath = decodeURIComponent(new URL(req.url, 'http://x').pathname);
    let file = path.normalize(path.join(root, urlPath));
    if (!file.startsWith(root)) {
      res.writeHead(403).end();
      return;
    }
    if (fs.existsSync(file) && fs.statSync(file).isDirectory()) file = path.join(file, 'index.html');
    // Unknown paths fall back to the app shell (the site routes in-app).
    if (!fs.existsSync(file)) file = path.join(root, 'index.html');
    res.writeHead(200, {
      'Content-Type': types[path.extname(file).toLowerCase()] || 'application/octet-stream',
      'Cache-Control': 'no-cache',
    });
    fs.createReadStream(file).pipe(res);
    console.log(`${new Date().toLocaleTimeString()}  ${req.socket.remoteAddress}  ${req.url}`);
  })
  .on('error', (e) => {
    console.error(e.code === 'EADDRINUSE' ? `Port ${port} is already in use (is "flutter run" still running?).` : e);
    process.exit(1);
  })
  .listen(port, '0.0.0.0', () => {
    console.log(`Serving ${root}`);
    for (const nets of Object.values(os.networkInterfaces())) {
      for (const n of nets) {
        if (n.family === 'IPv4' && !n.internal) console.log(`  Open on your phone:  http://${n.address}:${port}/`);
      }
    }
  });
