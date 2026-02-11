/**
 * clawfree CORS Gateway
 *
 * Lightweight proxy that forwards Anthropic API calls with CORS headers.
 * Supports SSE streaming for real-time genUI rendering.
 *
 * Usage:
 *   ANTHROPIC_API_KEY=sk-ant-... node server.js
 *   # or via .env.local in parent dir
 */

const http = require('http');
const https = require('https');

const PORT = parseInt(process.env.GATEWAY_PORT || '18789', 10);
const ANTHROPIC_HOST = 'api.anthropic.com';
const API_KEY = process.env.ANTHROPIC_API_KEY || '';

if (!API_KEY) {
  console.error('ERROR: ANTHROPIC_API_KEY is not set');
  process.exit(1);
}

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, x-api-key, anthropic-version, anthropic-dangerous-direct-browser-access',
  'Access-Control-Expose-Headers': 'Content-Type',
};

const server = http.createServer((req, res) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    res.writeHead(204, CORS_HEADERS);
    res.end();
    return;
  }

  // Health check
  if (req.url === '/health') {
    res.writeHead(200, { ...CORS_HEADERS, 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', service: 'clawfree-gateway' }));
    return;
  }

  // Only proxy /v1/* paths
  if (!req.url.startsWith('/v1/')) {
    res.writeHead(404, { ...CORS_HEADERS, 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not found. Proxy only handles /v1/* paths.' }));
    return;
  }

  // Collect request body
  const chunks = [];
  req.on('data', (chunk) => chunks.push(chunk));
  req.on('end', () => {
    const body = Buffer.concat(chunks);

    const proxyOptions = {
      hostname: ANTHROPIC_HOST,
      port: 443,
      path: req.url,
      method: req.method,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': API_KEY,
        'anthropic-version': req.headers['anthropic-version'] || '2023-06-01',
        'Content-Length': body.length,
      },
    };

    const proxyReq = https.request(proxyOptions, (proxyRes) => {
      const isStreaming = proxyRes.headers['content-type']?.includes('text/event-stream');

      const responseHeaders = {
        ...CORS_HEADERS,
        'Content-Type': proxyRes.headers['content-type'] || 'application/json',
      };

      if (isStreaming) {
        // SSE: disable buffering
        responseHeaders['Cache-Control'] = 'no-cache';
        responseHeaders['Connection'] = 'keep-alive';
        responseHeaders['X-Accel-Buffering'] = 'no';
      }

      res.writeHead(proxyRes.statusCode, responseHeaders);

      // Stream data through
      proxyRes.on('data', (chunk) => {
        res.write(chunk);
        // Flush immediately for SSE
        if (isStreaming && typeof res.flush === 'function') {
          res.flush();
        }
      });

      proxyRes.on('end', () => {
        res.end();
      });
    });

    proxyReq.on('error', (err) => {
      console.error('Proxy error:', err.message);
      res.writeHead(502, { ...CORS_HEADERS, 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: `Gateway error: ${err.message}` }));
    });

    proxyReq.write(body);
    proxyReq.end();
  });
});

server.listen(PORT, () => {
  console.log(`clawfree gateway listening on http://localhost:${PORT}`);
  console.log(`Proxying to https://${ANTHROPIC_HOST}`);
  console.log(`API key: ${API_KEY.substring(0, 12)}...${API_KEY.slice(-4)}`);
});
