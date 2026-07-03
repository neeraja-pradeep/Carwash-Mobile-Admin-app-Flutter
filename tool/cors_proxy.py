#!/usr/bin/env python3
"""Dev-only CORS proxy for running the Flutter web build against the backend.

Forwards every request to UPSTREAM and adds permissive CORS headers so the
browser stops blocking responses. NOT for production use.

Usage:  python3 tool/cors_proxy.py            # listens on 0.0.0.0:8090
        UPSTREAM=http://host:port PORT=8090 python3 tool/cors_proxy.py
"""
import os
import urllib.request
import urllib.error
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

UPSTREAM = os.environ.get("UPSTREAM", "http://156.67.104.149:8110").rstrip("/")
PORT = int(os.environ.get("PORT", "8090"))

# Hop-by-hop headers must not be forwarded.
HOP = {
    "connection", "keep-alive", "proxy-authenticate", "proxy-authorization",
    "te", "trailers", "transfer-encoding", "upgrade", "host", "content-length",
}


class Proxy(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _cors(self, origin):
        self.send_header("Access-Control-Allow-Origin", origin or "*")
        self.send_header("Access-Control-Allow-Credentials", "true")
        self.send_header("Access-Control-Allow-Methods",
                         "GET, POST, PUT, PATCH, DELETE, OPTIONS")
        req_hdrs = self.headers.get("Access-Control-Request-Headers",
                                    "Content-Type, Authorization, X-CSRFToken, X-Requested-With")
        self.send_header("Access-Control-Allow-Headers", req_hdrs)
        self.send_header("Access-Control-Expose-Headers", "*")
        self.send_header("Access-Control-Max-Age", "86400")

    def do_OPTIONS(self):
        origin = self.headers.get("Origin", "*")
        self.send_response(204)
        self._cors(origin)
        self.send_header("Content-Length", "0")
        self.end_headers()

    def _proxy(self):
        origin = self.headers.get("Origin", "*")
        url = UPSTREAM + self.path
        length = int(self.headers.get("Content-Length") or 0)
        body = self.rfile.read(length) if length else None

        fwd = {k: v for k, v in self.headers.items() if k.lower() not in HOP}
        req = urllib.request.Request(url, data=body, method=self.command, headers=fwd)
        try:
            resp = urllib.request.urlopen(req, timeout=30)
            status, raw, payload = resp.status, resp, resp.read()
        except urllib.error.HTTPError as e:
            status, raw, payload = e.code, e, e.read()
        except Exception as e:  # connection-level failure to upstream
            msg = str(e).encode()
            self.send_response(502)
            self._cors(origin)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", str(len(msg)))
            self.end_headers()
            self.wfile.write(msg)
            return

        self.send_response(status)
        for k, v in raw.headers.items():
            if k.lower() in HOP or k.lower().startswith("access-control-"):
                continue
            self.send_header(k, v)
        self._cors(origin)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    do_GET = do_POST = do_PUT = do_PATCH = do_DELETE = _proxy

    def log_message(self, fmt, *a):
        print("[proxy] %s - %s" % (self.address_string(), fmt % a))


if __name__ == "__main__":
    print(f"CORS proxy: http://0.0.0.0:{PORT}  ->  {UPSTREAM}")
    ThreadingHTTPServer(("0.0.0.0", PORT), Proxy).serve_forever()
