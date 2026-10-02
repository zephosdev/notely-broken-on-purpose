// Tiny stand-in for Supabase's API gateway: /rest/v1/* -> PostgREST, requires an apikey header.
import http from 'node:http';
const UP = { host: '127.0.0.1', port: 54330 };
http.createServer((req, res) => {
  if (!req.url.startsWith('/rest/v1')) { res.writeHead(404); return res.end('not found'); }
  const apikey = req.headers['apikey'];
  if (!apikey) { res.writeHead(401, { 'content-type': 'application/json' }); return res.end('{"message":"No API key found in request"}'); }
  const headers = { ...req.headers, host: `${UP.host}:${UP.port}` };
  if (!headers['authorization'] && apikey.startsWith('eyJ')) headers['authorization'] = `Bearer ${apikey}`;
  const up = http.request({ ...UP, method: req.method, path: req.url.replace(/^\/rest\/v1/, '') || '/', headers }, (r) => {
    res.writeHead(r.statusCode, r.headers); r.pipe(res);
  });
  up.on('error', (e) => { res.writeHead(502); res.end(String(e)); });
  req.pipe(up);
}).listen(54321, '127.0.0.1', () => console.log('gateway on :54321'));
