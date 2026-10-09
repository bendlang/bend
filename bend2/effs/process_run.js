// Process
// =======

const PROCESS_WORKER = `
const { errno, signals } = require("node:os").constants;

self.onmessage = async ({ data: { argv, input, max, ms, flag, port } }) => {
  let got;
  try {
    got = await run(argv, input, max, ms);
  } catch (e) {
    got = { fail: errno[e] ?? (typeof e?.errno === "number"
      ? Math.abs(e.errno) : errno.EIO) };
  }
  port.postMessage(got);
  Atomics.store(flag, 0, 1);
  Atomics.notify(flag, 0);
};

async function run(argv, input, max, ms) {
  const proc = Bun.spawn({ cmd: argv, stdin: input, stdout: "pipe",
    stderr: "pipe" });
  const readers = [proc.stdout.getReader(), proc.stderr.getReader()];
  let size = 0;
  const read = async (reader) => {
    const chunks = [];
    for (let r; !(r = await reader.read()).done;) {
      chunks.push(r.value);
      size += r.value.length;
      if (size > max) {
        throw "EFBIG";
      }
    }
    return Buffer.concat(chunks).toString("utf8");
  };
  let timer;
  try {
    const [out, err] = await Promise.race([
      Promise.all([...readers.map(read), proc.exited]),
      new Promise((_, no) => timer = setTimeout(no, ms, "ETIMEDOUT"))]);
    const sig = proc.signalCode === null ? 0 : signals[proc.signalCode] ?? 0;
    return { code: proc.exitCode ?? 128 + sig, out, err };
  } catch (e) {
    proc.kill("SIGKILL");
    readers.forEach((r) => r.cancel().catch(() => {}));
    throw e;
  } finally {
    clearTimeout(timer);
  }
}
`;

let process_worker = null;

function process_run(program, args, input, maxOutput, timeoutMs) {
  const argv = [program];
  for (let xs = args; xs.$ === CID(Con); xs = xs.tail) {
    argv.push(xs.head);
  }
  if (maxOutput === 0 || timeoutMs === 0
    || argv.some((arg) => arg.includes("\0"))) {
    return io_fail(22);
  }
  const { MessageChannel, receiveMessageOnPort } = require("node:worker_threads");
  process_worker ??= new Worker(URL.createObjectURL(new Blob([PROCESS_WORKER])));
  process_worker.unref();
  const flag = new Int32Array(new SharedArrayBuffer(4));
  const { port1, port2 } = new MessageChannel();
  process_worker.postMessage({ argv, input: Buffer.from(input), max: maxOutput,
    ms: timeoutMs, flag, port: port2 }, [port2]);
  Atomics.wait(flag, 0, 0);
  const got = receiveMessageOnPort(port1).message;
  port1.close();
  return got.fail !== undefined ? io_fail(got.fail)
    : io_done(io_tup(got.code, got.out, got.err));
}

io_eff(CID(Process.run), process_run);
