#!/usr/bin/env python3
import http.server, json, sys

class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get('Content-Length','0'))
        body = self.rfile.read(length)
        try:
            data = json.loads(body.decode('utf-8'))
            print(f"[webhook] payload: {json.dumps(data, ensure_ascii=False)}")
        except Exception as e:
            print(f"[webhook] invalid JSON: {e}")
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"OK")

if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv)>1 else 8091
    print(f"Listening on http://0.0.0.0:{port} ...")
    http.server.HTTPServer(("", port), Handler).serve_forever()
