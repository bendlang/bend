export {};

// Keep the generated source intact for display/download. These declarations
// adapt its CLI entry point and IO loop to a worker, retaining the compiled
// functions, value printer, effect implementations, and channel operations.
const browserRuntime = String.raw`
function io_out(fd, bytes) { browser.output(fd, bytes); }
function io_sys() {
  throw new Error("This effect requires native system access and is unavailable in the browser.");
}
function io_exit(main, show) {
  browser.completion = (async () => {
    try {
      if (show !== null) {
        io_out(1, io_bytes(show_val(...show, 0, run_loop(main()), 0) + "\n"));
        return 0;
      }
      return await browser_run(main);
    } catch (error) {
      io_errs(error instanceof Error ? error.message : String(error));
      return 1;
    }
  })();
}
async function browser_run(main) {
  const steps = io_steps(main);
  for (let step = steps.next();; step = steps.next()) {
    if (step.done) return step.value;
    const io = step.value;
    if (io.waits.some(w => w.fd !== undefined)) io_sys();
    const soon = io.waits.reduce((at, w) => Math.min(at, w.at), Infinity);
    await new Promise(resolve => setTimeout(resolve, Math.min(2147483647, Math.max(0, soon - performance.now()))));
    const now = performance.now();
    const fire = io.waits.filter(w => w.at <= now);
    io.waits = io.waits.filter(w => w.at > now);
    for (const w of fire) io_push(io_wake, w, false);
  }
}
`;

// One program per worker. The page terminates it on completion or cancellation.
self.onmessage = async ({ data }: MessageEvent) => {
  const start = performance.now();
  const limit = 1024 * 1024;
  let received = 0;
  let pending = "";
  let truncated = false;
  const decoders = [new TextDecoder(), new TextDecoder()];
  const flush = () => {
    if (pending) self.postMessage({ type: "output", text: pending });
    pending = "";
  };
  const interval = setInterval(flush, 30);
  const browser = {
    completion: Promise.resolve(0),
    output(fd: number, bytes: Uint8Array) {
      const available = Math.max(0, limit - received);
      received += bytes.length;
      pending += decoders[fd === 2 ? 1 : 0].decode(bytes.subarray(0, available), { stream: true });
      if (received > limit && !truncated) {
        truncated = true;
        pending += "\n[Output truncated at 1 MiB.]\n";
      }
      // Synchronous programs cannot yield to the interval; still stream chunks.
      if (pending.length >= 8192) flush();
    },
  };
  let code = 1;
  try {
    const require = (name: string) => { throw new Error(`Native module ${name} is unavailable in the browser.`); };
    const process = { argv: ["browser", "main.js"], env: Object.create(null) };
    new Function("browser", "require", "process", data.javascript + "\n" + browserRuntime)(browser, require, process);
    code = await browser.completion;
  } catch (error) {
    pending += (error instanceof Error ? error.message : String(error)) + "\n";
  } finally {
    clearInterval(interval);
    for (const decoder of decoders) pending += decoder.decode();
    flush();
    self.postMessage({ type: "done", code, elapsed: performance.now() - start });
  }
};
