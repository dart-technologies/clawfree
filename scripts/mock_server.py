#!/usr/bin/env python3
"""
Mock communication server for Watch ↔ iPhone simulator demo.

Usage:
    python3 scripts/mock_server.py

Watch simulator POSTs commands to localhost:8888/command
iPhone simulator polls localhost:8888/poll for new commands
"""

import json
import time
import threading
from http.server import HTTPServer, BaseHTTPRequestHandler

# Thread-safe command queue
_lock = threading.Lock()
_commands = []  # list of {command, params, timestamp}


class MockHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/command':
            length = int(self.headers.get('Content-Length', 0))
            body = json.loads(self.rfile.read(length)) if length else {}
            with _lock:
                _commands.append({
                    'command': body.get('command', ''),
                    'params': body.get('params', {}),
                    'text': body.get('text', ''),
                    'type': body.get('type', 'command'),
                    'timestamp': int(time.time() * 1000),
                })
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({'ok': True}).encode())
        else:
            self.send_response(404)
            self.end_headers()

    def do_GET(self):
        if self.path == '/poll':
            with _lock:
                cmds = list(_commands)
                _commands.clear()
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps({'commands': cmds}).encode())
        elif self.path == '/health':
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps({'status': 'ok'}).encode())
        else:
            self.send_response(404)
            self.end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def log_message(self, format, *args):
        print(f"[MockServer] {args[0]}")


if __name__ == '__main__':
    server = HTTPServer(('0.0.0.0', 8888), MockHandler)
    print("🚀 Mock server running on http://localhost:8888")
    print("   POST /command  — Watch sends commands")
    print("   GET  /poll     — iPhone polls for commands")
    print("   GET  /health   — Health check")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Server stopped")
        server.server_close()
