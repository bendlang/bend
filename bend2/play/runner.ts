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
    // Reads park on the virtual stdin fd (-1); anything else with an fd
    // still needs native system access.
    const foreign = io.waits.filter(w => w.fd !== undefined && w.fd !== -1);
    if (foreign.length > 0) io_sys();
    const stdinWaits = io.waits.filter(w => w.fd === -1);
    if (stdinWaits.length > 0 && browser.hasLine()) {
      for (const w of stdinWaits) {
        io.waits = io.waits.filter(x => x !== w);
        io_push(io_wake, w, false);
      }
      continue;
    }
    const timers = io.waits.filter(w => w.fd === undefined);
    const soon = timers.reduce((at, w) => Math.min(at, w.at), Infinity);
    if (stdinWaits.length > 0) {
      await browser.untilLine(soon);
      continue;
    }
    if (timers.length === 0) continue;
    await new Promise(resolve => setTimeout(resolve, Math.min(2147483647, Math.max(0, soon - performance.now()))));
    const now = performance.now();
    const fire = timers.filter(w => w.at <= now);
    io.waits = io.waits.filter(w => !fire.includes(w));
    for (const w of fire) io_push(io_wake, w, false);
  }
}
`;

// One program per worker. The page terminates it on completion or cancellation.
// Stdin state lives at worker level: lines arrive as later messages while
// the program started by the first message is still running, so per-message
// closures would never see them.
let stdinLines: string[] = [];
let stdinAt = 0;
let stdinEOF = false;
let lineWaiter: (() => void) | null = null;
let lineTimer: ReturnType<typeof setTimeout> | undefined;
function deliverLine(): void {
  if (lineWaiter) {
    clearTimeout(lineTimer);
    lineTimer = undefined;
    const wake = lineWaiter;
    lineWaiter = null;
    wake();
  }
}

self.onmessage = async ({ data }: MessageEvent) => {
  if (data.javascript === undefined) {
    // A line (or EOF) for the running program. Only one runs per worker.
    if (data.eof) stdinEOF = true;
    else if (typeof data.text === "string") stdinLines.push(data.text);
    deliverLine();
    return;
  }
  // Fresh stdin per program: the Stdin box prefills lines; once they run
  // out the program parks and the page is asked per line. EOF ends input.
  const raw = String(data.stdin ?? "");
  stdinLines = raw.split("\n").map(l => l.endsWith("\r") ? l.slice(0, -1) : l);
  if (stdinLines.length > 0 && stdinLines[stdinLines.length - 1] === "") stdinLines.pop();
  stdinAt = 0;
  stdinEOF = false;
  lineWaiter = null;
  clearTimeout(lineTimer);
  lineTimer = undefined;
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
    takeLine(): string | null | undefined {
      if (stdinAt < stdinLines.length) return stdinLines[stdinAt++];
      if (stdinEOF) return null;
      return undefined;
    },
    hasLine(): boolean {
      return stdinAt < stdinLines.length || stdinEOF;
    },
    untilLine(soon: number): Promise<void> {
      if (stdinAt < stdinLines.length || stdinEOF) return Promise.resolve();
      return new Promise<void>((resolve) => {
        lineWaiter = resolve;
        if (soon !== Infinity) {
          lineTimer = setTimeout(() => {
            lineWaiter = null;
            lineTimer = undefined;
            resolve();
          }, Math.min(2147483647, Math.max(0, soon - performance.now())));
        }
      });
    },
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
