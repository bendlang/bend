// libcurl callbacks capture response headers and UTF-8 body with one byte cap.
// The synchronous transfer blocks the JS IO loop, like other Bun FFI calls.
function http_curl() {
  if (globalThis.BEND_CURL_HTTP !== undefined) return globalThis.BEND_CURL_HTTP;
  const ffi = require("bun:ffi");
  const mac = process.platform === "darwin";
  const vari = mac && process.arch === "arm64";
  const v = vari ? ["ptr", "i32", ...Array(7).fill("i64")]
    : ["ptr", "i32", "i64"];
  const lib = ffi.dlopen(mac ? "libcurl.dylib" : "libcurl.so.4", {
    curl_global_init: { args: ["i64"], returns: "i32" },
    curl_easy_init: { args: [], returns: "ptr" },
    curl_easy_cleanup: { args: ["ptr"], returns: "void" },
    curl_easy_setopt: { args: v, returns: "i32" },
    curl_easy_getinfo: { args: v, returns: "i32" },
    curl_easy_perform: { args: ["ptr"], returns: "i32" },
    curl_easy_strerror: { args: ["i32"], returns: "cstring" },
    curl_slist_append: { args: ["ptr", "ptr"], returns: "ptr" },
    curl_slist_free_all: { args: ["ptr"], returns: "void" },
  }).symbols;
  if (lib.curl_global_init(3) !== 0) throw new Error("libcurl initialization failed");
  const option = (easy, id, arg) => vari
    ? lib.curl_easy_setopt(easy, id, 0, 0, 0, 0, 0, 0, arg)
    : lib.curl_easy_setopt(easy, id, arg);
  const info = (easy, id, arg) => vari
    ? lib.curl_easy_getinfo(easy, id, 0, 0, 0, 0, 0, 0, arg)
    : lib.curl_easy_getinfo(easy, id, arg);
  return globalThis.BEND_CURL_HTTP = { ffi, lib, option, info, mac };
}

function http_fail(code, message) {
  return { $: "Fail", error: io_tup(code >>> 0, message) };
}

function http_request(method, url, headers, body, max_output, timeout_ms, ca_file) {
  if (!/^[!#$%&'*+.^_`|~0-9A-Za-z-]+$/.test(method) || max_output === 0
    || timeout_ms === 0 || url.includes("\0") || ca_file.includes("\0")
    || method === "HEAD" && body.length !== 0) return io_fail(22);
  let parsed;
  try { parsed = new URL(url); }
  catch { return io_fail(22); }
  if (parsed.protocol !== "http:" && parsed.protocol !== "https:")
    return io_fail(22);
  const fields = [];
  for (let xs = headers; xs.$ === "Con"; xs = xs.tail) {
    const { name, value } = xs.head;
    if (!/^[!#$%&'*+.^_`|~0-9A-Za-z-]+$/.test(name)
      || /[\x00-\x08\x0a-\x1f\x7f]/.test(value)) return io_fail(22);
    fields.push(name + ": " + value);
  }
  let c;
  try { c = http_curl(); }
  catch (err) { return http_fail(2, String(err.message ?? err)); }
  const { ffi, lib } = c;
  const easy = lib.curl_easy_init();
  if (!easy) return io_fail(12);
  const encoder = new TextEncoder();
  const urlBuf = encoder.encode(url + "\0");
  const caBuf = ca_file ? encoder.encode(ca_file + "\0") : null;
  const methodBuf = encoder.encode(method + "\0");
  const bodyBuf = encoder.encode(body);
  const dataBuf = bodyBuf.length ? bodyBuf : new Uint8Array(1);
  let headerList = null;
  let bodyLength = 0;
  let received = 0;
  let overflow = false;
  let responseHeaders = [];
  const chunks = [];
  const bytes = (ptr, n) => new Uint8Array(ffi.toArrayBuffer(ptr, 0, n)).slice();
  const collect = new ffi.JSCallback((ptr, size, count) => {
    const n = Number(size) * Number(count);
    if (n > max_output - received) { overflow = true; return 0; }
    if (n === 0) return 0;
    received += n;
    chunks.push(bytes(ptr, n));
    bodyLength += n;
    return n;
  }, { args: ["ptr", "u64", "u64", "ptr"], returns: "u64" });
  const onHeader = new ffi.JSCallback((ptr, size, count) => {
    const n = Number(size) * Number(count);
    if (n > max_output - received) { overflow = true; return 0; }
    if (n === 0) return 0;
    received += n;
    const line = io_text(bytes(ptr, n), n);
    if (line.startsWith("HTTP/")) responseHeaders = [];
    else {
      const colon = line.indexOf(":");
      if (colon > 0) responseHeaders.push([line.slice(0, colon),
        line.slice(colon + 1).trim()]);
    }
    return n;
  }, { args: ["ptr", "u64", "u64", "ptr"], returns: "u64" });
  let error = 0;
  try {
    for (const field of fields) {
      const data = encoder.encode(field + "\0");
      const next = lib.curl_slist_append(headerList, ffi.ptr(data));
      if (!next) { error = 12; break; }
      headerList = next;
    }
    const set = (id, arg) => { if (!error) error = c.option(easy, id, arg); };
    set(10002, ffi.ptr(urlBuf));
    if (!error) {
      const allowed = encoder.encode("http,https\0");
      error = c.option(easy, 10318, ffi.ptr(allowed));
      if (error === 48) error = c.option(easy, 181, 3);
    }
    set(52, 0);
    set(99, 1);
    set(155, timeout_ms);
    set(64, 1);
    set(81, 2);
    if (caBuf !== null) set(10065, ffi.ptr(caBuf));
    if (headerList) set(10023, headerList);
    set(20011, collect.ptr);
    set(20079, onHeader.ptr);
    if (bodyBuf.length || method !== "GET" && method !== "HEAD") {
      set(30120, bodyBuf.length);
      set(10015, ffi.ptr(dataBuf));
    }
    if (method === "HEAD") set(44, 1);
    set(10036, ffi.ptr(methodBuf));
    if (!error) error = lib.curl_easy_perform(easy);
    if (overflow) return io_fail(27);
    if (error) return http_fail(error === 28 ? (c.mac ? 60 : 110)
      : error === 60 || error === 77 ? 13 : 5,
      String(lib.curl_easy_strerror(error)));
    const status = new BigInt64Array(1);
    error = c.info(easy, 2097154, ffi.ptr(status));
    if (error) return http_fail(5, String(lib.curl_easy_strerror(error)));
    const output = new Uint8Array(bodyLength);
    let at = 0;
    for (const chunk of chunks) { output.set(chunk, at); at += chunk.length; }
    let list = { $: "Nil" };
    for (let i = responseHeaders.length - 1; i >= 0; i -= 1) {
      const [name, value] = responseHeaders[i];
      list = { $: "Con", head: { $: "Header", name, value }, tail: list };
    }
    return io_done({ $: "Response", status: Number(status[0]),
      headers: list, body: io_text(output, bodyLength) });
  } finally {
    collect.close();
    onHeader.close();
    lib.curl_easy_cleanup(easy);
    if (headerList) lib.curl_slist_free_all(headerList);
  }
}
