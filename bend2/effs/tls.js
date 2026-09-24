// libcurl owns TLS and certificate verification on the JavaScript lane too.
// The Bend loop parks send/recv on the socket; connect itself is synchronous.
function tls_curl() {
  if (globalThis.BEND_CURL_TLS !== undefined) return globalThis.BEND_CURL_TLS;
  const ffi = require("bun:ffi");
  const mac = process.platform === "darwin";
  const vari = mac && process.arch === "arm64";
  const v = vari ? ["ptr", "i32", ...Array(7).fill("i64")]
    : ["ptr", "i32", "i64"];
  const names = {
    curl_global_init: { args: ["i64"], returns: "i32" },
    curl_easy_init: { args: [], returns: "ptr" },
    curl_easy_cleanup: { args: ["ptr"], returns: "void" },
    curl_easy_setopt: { args: v, returns: "i32" },
    curl_easy_getinfo: { args: v, returns: "i32" },
    curl_easy_perform: { args: ["ptr"], returns: "i32" },
    curl_easy_send: { args: ["ptr", "ptr", "u64", "ptr"], returns: "i32" },
    curl_easy_recv: { args: ["ptr", "ptr", "u64", "ptr"], returns: "i32" },
    curl_easy_strerror: { args: ["i32"], returns: "cstring" },
  };
  const lib = ffi.dlopen(mac ? "libcurl.dylib" : "libcurl.so.4", names).symbols;
  if (lib.curl_global_init(3) !== 0) throw new Error("libcurl initialization failed");
  const option = (easy, id, arg) => vari
    ? lib.curl_easy_setopt(easy, id, 0, 0, 0, 0, 0, 0, arg)
    : lib.curl_easy_setopt(easy, id, arg);
  const info = (easy, id, arg) => vari
    ? lib.curl_easy_getinfo(easy, id, 0, 0, 0, 0, 0, 0, arg)
    : lib.curl_easy_getinfo(easy, id, arg);
  return globalThis.BEND_CURL_TLS = { ffi, lib, option, info, mac };
}

function tls_error(code, message) {
  return { $: "Fail", error: io_tup(code >>> 0, message) };
}

function tls_code(c, code) {
  return code === 28 ? (c.mac ? 60 : 110)
    : code === 60 || code === 77 ? 13 : 5;
}

function tls_connect(host, port, ca_file, timeout_ms) {
  const net = require("node:net");
  const ip = net.isIP(host);
  if (!host || host.length > 253 || port < 1 || port > 65535 || timeout_ms === 0
    || (!ip && !/^[A-Za-z0-9.-]+$/.test(host)) || ca_file.includes("\0")) {
    return io_fail(22);
  }
  let c;
  try { c = tls_curl(); }
  catch (err) { return tls_error(2, String(err.message ?? err)); }
  const easy = c.lib.curl_easy_init();
  if (!easy) return io_fail(12);
  const url = new TextEncoder().encode("https://" + (ip === 6 ? `[${host}]` : host)
    + ":" + port + "/\0");
  const ca = ca_file ? new TextEncoder().encode(ca_file + "\0") : null;
  const set = (id, arg) => c.option(easy, id, arg);
  let code = set(10002, c.ffi.ptr(url));
  if (code === 0) code = set(141, 1);
  if (code === 0) code = set(226, 0);
  if (code === 0) code = set(64, 1);
  if (code === 0) code = set(81, 2);
  if (code === 0 && ca !== null) code = set(10065, c.ffi.ptr(ca));
  if (code === 0) code = set(156, timeout_ms);
  if (code === 0) code = set(155, timeout_ms);
  if (code === 0) code = c.lib.curl_easy_perform(easy);
  if (code !== 0) {
    c.lib.curl_easy_cleanup(easy);
    return tls_error(tls_code(c, code), String(c.lib.curl_easy_strerror(code)));
  }
  return io_done({ easy, c });
}

function tls_park(socket, writing, deadline, k, more) {
  const { c, easy } = socket;
  const fd = new Int32Array(1);
  if (c.info(easy, 5242924, c.ffi.ptr(fd)) !== 0 || fd[0] < 0) {
    return io_tup(socket, io_fail(5));
  }
  if (performance.now() >= deadline) {
    return io_tup(socket, io_fail(c.mac ? 60 : 110));
  }
  io_park_on(fd[0], writing, k, more, deadline);
  return undefined;
}

function tls_send(socket, bytes, timeout_ms, k) {
  if (timeout_ms === 0) return io_tup(socket, io_fail(22));
  let length = 0;
  for (let xs = bytes; xs.$ === "Con"; xs = xs.tail) length += 1;
  const data = new Uint8Array(length);
  let at = 0;
  for (let xs = bytes; xs.$ === "Con"; xs = xs.tail) {
    if (xs.head > 255) return io_tup(socket, io_fail(22));
    data[at++] = xs.head;
  }
  const { c, easy } = socket;
  const sent = new BigUint64Array(1);
  const deadline = performance.now() + timeout_ms;
  const go = (offset) => {
    while (offset < length) {
      if (performance.now() >= deadline)
        return io_tup(socket, io_fail(c.mac ? 60 : 110));
      sent[0] = 0n;
      const view = data.subarray(offset);
      const code = c.lib.curl_easy_send(easy, c.ffi.ptr(view), view.length,
        c.ffi.ptr(sent));
      offset += Number(sent[0]);
      if (code === 81) return tls_park(socket, true, deadline, k, () => go(offset));
      if (code !== 0) return io_tup(socket,
        tls_error(tls_code(c, code), String(c.lib.curl_easy_strerror(code))));
      if (sent[0] === 0n) return io_tup(socket, io_fail(32));
    }
    return io_tup(socket, io_done({ $: "Unit" }));
  };
  return go(0);
}

function tls_recv(socket, max, timeout_ms, k) {
  if (max === 0 || timeout_ms === 0) return io_tup(socket, io_fail(22));
  const { c, easy } = socket;
  const data = new Uint8Array(Math.min(Number(max), 65536));
  const got = new BigUint64Array(1);
  const deadline = performance.now() + timeout_ms;
  const go = () => {
    if (performance.now() >= deadline)
      return io_tup(socket, io_fail(c.mac ? 60 : 110));
    got[0] = 0n;
    const code = c.lib.curl_easy_recv(easy, c.ffi.ptr(data), data.length,
      c.ffi.ptr(got));
    if (code === 81) return tls_park(socket, false, deadline, k, go);
    if (code !== 0) return io_tup(socket,
      tls_error(tls_code(c, code), String(c.lib.curl_easy_strerror(code))));
    let xs = { $: "Nil" };
    for (let i = Number(got[0]) - 1; i >= 0; i -= 1) {
      xs = { $: "Con", head: data[i], tail: xs };
    }
    return io_tup(socket, io_done(xs));
  };
  return go();
}

function tls_close(socket) {
  socket.c.lib.curl_easy_cleanup(socket.easy);
  return { $: "Unit" };
}
