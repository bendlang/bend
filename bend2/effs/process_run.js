// Process
// =======

const PROCESS_WORKER = `
// Eval workers may inherit module mode, where require is undefined.
const { errno, signals } = process.getBuiltinModule("node:os").constants;
const { parentPort } = process.getBuiltinModule("node:worker_threads");
const { spawn } = process.getBuiltinModule("node:child_process");
let port;
let flag;
let native;
let children;

parentPort.on("message", async (data) => {
  if (data.port !== undefined) {
    ({ port, flag } = data);
    return;
  }
  let got;
  try {
    got = data.command === "open" ? await open(data)
      : data.command === "wait" ? await wait(data) : await run(data);
  } catch (e) {
    got = { fail: errno[e] ?? (typeof e?.errno === "number"
      ? Math.abs(e.errno) : errno.EIO) };
  }
  if (data.reply !== undefined) {
    data.reply.postMessage(got);
    data.reply.close();
  } else {
    port.postMessage(got);
    Atomics.store(flag, 0, 1);
    Atomics.notify(flag, 0);
  }
});

function run({ argv, input, env, max, ms }) {
  return new Promise((yes, no) => {
    const proc = spawn(argv[0], argv.slice(1), { env,
      stdio: ["pipe", "pipe", "pipe"] });
    // Node destroys proc.stdin at exit; a descendant may still read it.
    const stdin = proc.stdin;
    proc.stdin = null;
    const chunks = [[], []];
    let size = 0;
    let error;
    const fail = (e) => {
      if (error !== undefined) return;
      error = e;
      proc.kill("SIGKILL");
      stdin.destroy();
      proc.stdout.destroy();
      proc.stderr.destroy();
    };
    proc.once("error", fail);
    stdin.on("error", (e) => {
      if (e.code !== "EPIPE") fail(e);
    });
    [proc.stdout, proc.stderr].forEach((stream, i) => {
      stream.on("error", fail);
      stream.on("data", (chunk) => {
        if (error !== undefined) return;
        size += chunk.length;
        if (size > max) fail("EFBIG");
        else chunks[i].push(chunk);
      });
    });
    // Feed stdin until the child exits and its stdout and stderr close.
    let live = 3;
    const done = () => --live || stdin.destroy();
    proc.once("exit", done);
    proc.stdout.once("close", done);
    proc.stderr.once("close", done);
    const timer = setTimeout(() => fail("ETIMEDOUT"),
      Math.min(ms, 2 ** 31 - 1));
    proc.once("close", (code, signal) => {
      clearTimeout(timer);
      if (error !== undefined) no(error);
      else yes({ code: code ?? 128 + (signals[signal] ?? 0),
        out: Buffer.concat(chunks[0]).toString("utf8"),
        err: Buffer.concat(chunks[1]).toString("utf8") });
    });
    stdin.end(input);
  });
}

function system() {
  return native ??= import("bun:ffi").then((ffi) => {
    const mac = process.platform === "darwin";
    const vari = mac && process.arch === "arm64";
    const err = mac ? "__error" : "__errno_location";
    const lib = ffi.dlopen(mac ? "libSystem.dylib" : "libc.so.6", {
      pipe: { args: ["ptr"], returns: "i32" },
      close: { args: ["i32"], returns: "i32" },
      fcntl: { args: vari
        ? ["i32", "i32", "i32", "i32", "i32", "i32", "i32", "i32", "i32"]
        : ["i32", "i32", "i32"], returns: "i32" },
      [err]: { args: [], returns: "ptr" }
    }).symbols;
    return { ...lib, ptr: ffi.ptr,
      fcntl: vari ? (fd, cmd, arg) => lib.fcntl(fd, cmd, 0, 0, 0, 0, 0, 0, arg)
        : lib.fcntl,
      errno: () => ffi.read.i32(lib[err](), 0) };
  });
}

async function open({ argv, env }) {
  const sys = await system();
  const fds = new Int32Array([-1, -1, -1, -1]);
  try {
    const ptr = sys.ptr(fds);
    for (let at = 0; at < 4; at += 2) {
      if (sys.pipe(ptr + at * 4) < 0) throw { errno: sys.errno() };
      for (let i = at; i < at + 2; i++) {
        if (fds[i] < 3) {
          const moved = sys.fcntl(fds[i], 0, 3);
          if (moved < 0) throw { errno: sys.errno() };
          sys.close(fds[i]);
          fds[i] = moved;
        }
        if (sys.fcntl(fds[i], 2, 1) < 0) throw { errno: sys.errno() };
      }
    }
    const child = Bun.spawn(argv, {
      stdin: fds[0], stdout: fds[3], stderr: 2, env
    });
    sys.close(fds[0]); fds[0] = -1;
    sys.close(fds[3]); fds[3] = -1;
    (children ??= new Map()).set(child.pid, child);
    const got = { pid: child.pid, input: fds[1], output: fds[2] };
    fds[1] = -1; fds[2] = -1;
    return got;
  } finally {
    for (const fd of fds) if (fd >= 0) sys.close(fd);
  }
}

async function wait({ pid }) {
  const child = children?.get(pid);
  if (child === undefined) throw "ECHILD";
  children.delete(pid);
  const code = await child.exited;
  return { code: child.signalCode === null ? code
    : 128 + (signals[child.signalCode] ?? 0) };
}
`;

let process_worker = null;

// Captured runs may restart their worker after a transport timeout.
// Interactive children use a separate, persistent worker.
let process_open_worker = null;

function process_argv(program, args) {
  const argv = [str_out(program)];
  for (let xs = args; xs.$ === CID(Con); xs = xs.tail) {
    argv.push(str_out(xs.head));
  }
  return argv;
}

function process_arg_error(argv) {
  if (argv.some((arg) => arg.includes("\0"))) return 22;
  // spawn("") throws with no errno; C's posix_spawnp("") answers ENOENT.
  return argv[0] === "" ? 2 : 0;
}

function process_run_now(program, args, input, maxOutput, timeoutMs) {
  const argv = process_argv(program, args);
  if (maxOutput === 0 || timeoutMs === 0) return io_fail(22);
  const bad = process_arg_error(argv);
  if (bad !== 0) return io_fail(bad);
  if (process_worker === null) {
    const { Worker, MessageChannel, receiveMessageOnPort } = require("node:worker_threads");
    const { port1, port2 } = new MessageChannel();
    const flag = new Int32Array(new SharedArrayBuffer(4));
    const worker = new Worker(PROCESS_WORKER, { eval: true });
    worker.unref();
    worker.postMessage({ port: port2, flag }, [port2]);
    process_worker = { worker, port: port1, flag, receive: receiveMessageOnPort };
  }
  const { worker, port, flag, receive } = process_worker;
  Atomics.store(flag, 0, 0);
  worker.postMessage({ argv, input: io_bytes(input), env: { ...process.env },
    max: maxOutput, ms: timeoutMs });
  if (Atomics.wait(flag, 0, 0, timeoutMs + 1000) === "timed-out") {
    worker.terminate();
    process_worker = null;
    return io_fail(5);
  }
  const got = receive(port).message;
  return got.fail !== undefined ? io_fail(got.fail)
    : io_done(io_tup(got.code, got.out, got.err));
}

function process_run(program, args, input, maxOutput, timeoutMs, k) {
  io_park_on(undefined, 0, k,
    () => process_run_now(program, args, input, maxOutput, timeoutMs), 0);
}

function process_request(data, k, pack) {
  let port;
  let receive;
  try {
    if (process_open_worker === null) {
      const { Worker, MessageChannel, receiveMessageOnPort } = require("node:worker_threads");
      const worker = new Worker(PROCESS_WORKER, { eval: true });
      worker.unref();
      process_open_worker = { worker, MessageChannel, receive: receiveMessageOnPort };
    }
    const worker = process_open_worker;
    const channel = new worker.MessageChannel();
    port = channel.port1;
    port.unref();
    receive = worker.receive;
    data.reply = channel.port2;
    worker.worker.postMessage(data, [channel.port2]);
  } catch (e) {
    port?.close();
    data.reply?.close();
    return io_fail(Math.abs(e.errno ?? 5));
  }
  const more = () => {
    const got = receive(port);
    if (got === undefined) {
      io_park_on(undefined, 0, k, more, performance.now() + 1);
      return undefined;
    }
    port.close();
    return got.message.fail !== undefined ? io_fail(got.message.fail)
      : io_done(pack(got.message));
  };
  return more();
}

function process_open(program, args, k) {
  const argv = process_argv(program, args);
  const bad = process_arg_error(argv);
  if (bad !== 0) return io_fail(bad);
  if (typeof Bun === "undefined") {
    return io_fail(process.platform === "darwin" ? 78 : 38);
  }
  return process_request({ command: "open", argv, env: { ...process.env } },
    k, (got) => io_tup(got.pid, got.input, got.output));
}

function process_wait(pid, k) {
  if (pid === 0 || pid > 2147483647) return io_fail(22);
  if (process_open_worker === null) return io_fail(10);
  return process_request({ command: "wait", pid }, k, (got) => got.code);
}

io_eff(CID(Process.run), process_run);
io_eff(CID(Process.open), process_open);
io_eff(CID(Process.wait), process_wait);
