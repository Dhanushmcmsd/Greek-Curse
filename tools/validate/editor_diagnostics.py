"""Collect Godot LSP diagnostics; run headless editor with --lsp-port 6015 first."""
import json
from pathlib import Path
import socket
import time

sock = socket.create_connection(("127.0.0.1", 6015), timeout=5)
sock.settimeout(1)

def send(message):
    body = json.dumps(message).encode()
    sock.sendall(f"Content-Length: {len(body)}\r\n\r\n".encode() + body)

send({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"rootUri": Path.cwd().as_uri(), "capabilities": {}}})
time.sleep(0.2)
send({"jsonrpc": "2.0", "method": "initialized", "params": {}})
for path in Path("src").rglob("*.gd"):
    send({"jsonrpc": "2.0", "method": "textDocument/didOpen", "params": {"textDocument": {"uri": path.resolve().as_uri(), "languageId": "gdscript", "version": 1, "text": path.read_text(encoding="utf-8-sig")}}})
buffer = b""
results = {}
deadline = time.time() + 10
while time.time() < deadline:
    try:
        buffer += sock.recv(1048576)
    except socket.timeout:
        continue
    while b"\r\n\r\n" in buffer:
        header, body = buffer.split(b"\r\n\r\n", 1)
        length = int(header.split(b":")[1])
        if len(body) < length:
            break
        message = json.loads(body[:length])
        buffer = body[length:]
        if message.get("method") == "textDocument/publishDiagnostics":
            results[message["params"]["uri"]] = message["params"]["diagnostics"]
Path("build/editor_diagnostics_final.json").write_text(json.dumps(results, indent=2), encoding="utf-8")
for path, diagnostics in results.items():
    for diagnostic in diagnostics:
        print(path, diagnostic["range"]["start"]["line"] + 1, diagnostic["message"])
print("Scripts:", len(results), "Diagnostics:", sum(map(len, results.values())))
