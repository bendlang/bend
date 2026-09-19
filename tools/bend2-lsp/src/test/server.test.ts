import assert from "node:assert/strict";
import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import { fileURLToPath } from "node:url";
import test from "node:test";

type Message = { id?: number; method?: string; params?: unknown; result?: unknown; error?: unknown };
type WaitFor = ((id: number) => Promise<Message>) & { notification(method: string): Promise<Message> };

function send(child: ChildProcessWithoutNullStreams, message: object): void {
  const body = JSON.stringify(message);
  child.stdin.write(`Content-Length: ${Buffer.byteLength(body)}\r\n\r\n${body}`);
}

function responses(child: ChildProcessWithoutNullStreams): WaitFor {
  let buffer = Buffer.alloc(0);
  const pending = new Map<number, (message: Message) => void>();
  const notificationPending = new Map<string, (message: Message) => void>();
  const notificationQueued = new Map<string, Message[]>();
  child.stdout.on("data", (chunk: Buffer) => {
    buffer = Buffer.concat([buffer, chunk]);
    while (true) {
      const marker = buffer.indexOf("\r\n\r\n");
      if (marker < 0) return;
      const header = buffer.subarray(0, marker).toString("ascii");
      const length = Number(/Content-Length: (\d+)/i.exec(header)?.[1]);
      if (!Number.isFinite(length) || buffer.length < marker + 4 + length) return;
      const message = JSON.parse(buffer.subarray(marker + 4, marker + 4 + length).toString("utf8")) as Message;
      buffer = buffer.subarray(marker + 4 + length);
      if (message.id !== undefined) pending.get(message.id)?.(message);
      else if (message.method) {
        const resolve = notificationPending.get(message.method);
        if (resolve) {
          notificationPending.delete(message.method);
          resolve(message);
        } else notificationQueued.set(message.method, [...(notificationQueued.get(message.method) ?? []), message]);
      }
    }
  });
  const waitFor = ((id: number) => new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`timed out waiting for response ${id}`)), 5000);
    pending.set(id, (message) => {
      clearTimeout(timer);
      pending.delete(id);
      resolve(message);
    });
  })) as WaitFor;
  waitFor.notification = (method) => new Promise((resolve, reject) => {
    const queued = notificationQueued.get(method)?.shift();
    if (queued) { resolve(queued); return; }
    const timer = setTimeout(() => reject(new Error(`timed out waiting for ${method}`)), 5000);
    notificationPending.set(method, (message) => { clearTimeout(timer); resolve(message); });
  });
  return waitFor;
}

test("serves formatting over an LSP stdio session", async (context) => {
  const server = fileURLToPath(new URL("../server.js", import.meta.url));
  const child = spawn(process.execPath, [server, "--stdio"], { stdio: ["pipe", "pipe", "pipe"] });
  context.after(() => child.kill());
  const waitFor = responses(child);

  const initialized = waitFor(1);
  send(child, { jsonrpc: "2.0", id: 1, method: "initialize", params: { capabilities: {} } });
  const initialize = await initialized;
  assert.equal(initialize.error, undefined);
  assert.deepEqual((initialize.result as { capabilities: object }).capabilities, {
    textDocumentSync: 1,
    documentFormattingProvider: true,
    hoverProvider: true,
  });

  send(child, { jsonrpc: "2.0", method: "initialized", params: {} });
  const diagnostics = waitFor.notification("textDocument/publishDiagnostics");
  send(child, {
    jsonrpc: "2.0",
    method: "textDocument/didOpen",
    params: { textDocument: { uri: "file:///main.bend", languageId: "bend", version: 1, text: "def main()->U32:\n    0" } },
  });
  const formatted = waitFor(2);
  send(child, {
    jsonrpc: "2.0",
    id: 2,
    method: "textDocument/formatting",
    params: { textDocument: { uri: "file:///main.bend" }, options: { tabSize: 2, insertSpaces: true } },
  });
  assert.deepEqual((await formatted).result, [{
    range: { start: { line: 0, character: 0 }, end: { line: 1, character: 5 } },
    newText: "def main() -> U32:\n  0",
  }]);
  const published = (await diagnostics).params as { uri: string; diagnostics: Array<{ source: string }> };
  assert.equal(published.uri, "file:///main.bend");
  assert.ok(published.diagnostics.every((item) => item.source === "bend2"));

  const hovered = waitFor(4);
  send(child, { jsonrpc: "2.0", id: 4, method: "textDocument/hover", params: { textDocument: { uri: "file:///main.bend" }, position: { line: 0, character: 1 } } });
  assert.match(JSON.stringify((await hovered).result), /Declares a top-level function/);

  const changed = waitFor.notification("textDocument/publishDiagnostics");
  send(child, { jsonrpc: "2.0", method: "textDocument/didChange", params: { textDocument: { uri: "file:///main.bend", version: 2 }, contentChanges: [{ text: "def main() -> U32:\n  ?TODO" }] } });
  send(child, { jsonrpc: "2.0", method: "textDocument/didChange", params: { textDocument: { uri: "file:///main.bend", version: 3 }, contentChanges: [{ text: "def main() -> U32:\n  0" }] } });
  assert.equal(((await changed).params as { version: number }).version, 3);

  const cleared = waitFor.notification("textDocument/publishDiagnostics");
  send(child, { jsonrpc: "2.0", method: "textDocument/didClose", params: { textDocument: { uri: "file:///main.bend" } } });
  assert.deepEqual(((await cleared).params as { diagnostics: unknown[] }).diagnostics, []);

  const shutdown = waitFor(3);
  send(child, { jsonrpc: "2.0", id: 3, method: "shutdown" });
  assert.equal((await shutdown).result, null);
  send(child, { jsonrpc: "2.0", method: "exit" });
});
