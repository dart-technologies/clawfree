/**
 * clawfree CORS Gateway
 *
 * Lightweight proxy that forwards Anthropic API calls with CORS headers
 * and OpenClaw management endpoints to the OpenClaw instance.
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
const OPENCLAW_HOST = process.env.OPENCLAW_HOST || 'localhost';
const OPENCLAW_PORT = parseInt(process.env.OPENCLAW_PORT || '18790', 10);
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

  // Pairing redirect: browser scans QR -> redirects to mobile app
  if (req.url.startsWith('/pair')) {
    const url = new URL(req.url, `http://${req.headers.host}`);
    const targetUrl = `http://${req.headers.host}`;
    const token = process.env.GATEWAY_TOKEN || '';

    // Redirect to custom scheme: clawfree://pair?url=...&token=...
    const deepLink = `clawfree://pair?url=${encodeURIComponent(targetUrl)}&token=${encodeURIComponent(token)}`;

    res.writeHead(302, {
      ...CORS_HEADERS,
      'Location': deepLink,
    });
    res.end();
    return;
  }

  // Determine proxy target based on path
  const isAnthropicPath = req.url.startsWith('/v1/');
  const isOpenClawPath = req.url.startsWith('/agents') ||
                         req.url.startsWith('/sessions') ||
                         req.url.startsWith('/onboard');

  if (!isAnthropicPath && !isOpenClawPath) {
    res.writeHead(404, { ...CORS_HEADERS, 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'Not found. Proxy handles /v1/*, /agents, /sessions, /onboard.' }));
    return;
  }

  // Collect request body
  const chunks = [];
  req.on('data', (chunk) => chunks.push(chunk));
  req.on('end', () => {
    const body = Buffer.concat(chunks);

    // Route to Anthropic (HTTPS) or OpenClaw (HTTP)
    const proxyModule = isAnthropicPath ? https : http;
    const proxyOptions = isAnthropicPath ? {
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
    } : {
      hostname: OPENCLAW_HOST,
      port: OPENCLAW_PORT,
      path: req.url,
      method: req.method,
      headers: {
        'Content-Type': req.headers['content-type'] || 'application/json',
        'Content-Length': body.length,
        ...(req.headers['authorization'] ? { 'Authorization': req.headers['authorization'] } : {}),
      },
    };

    const proxyReq = proxyModule.request(proxyOptions, (proxyRes) => {
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
  console.log(`Anthropic API: https://${ANTHROPIC_HOST} (/v1/*)`);
  console.log(`OpenClaw:      http://${OPENCLAW_HOST}:${OPENCLAW_PORT} (/agents, /sessions, /onboard)`);
  console.log(`API key: ${API_KEY.substring(0, 12)}...${API_KEY.slice(-4)}`);
});
