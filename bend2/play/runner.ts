export {};

// Keep the generated source intact for display/download. These declarations
// adapt its CLI entry point and IO loop to a worker, retaining the compiled
// functions, value printer, effect implementations, and channel operations.
const browserRuntime = String.raw`
function io_out(fd, bytes) { browser.output(fd, bytes); }
function io_sys() {
  throw new Error("This effect requires native system access and is unavailable in the browser.");
}
// Pace presents like the native 60 Hz tick: parking yields the event loop,
// so inbound keys and lines are delivered and outbound frames stop flooding.
function io_pace(k, more) {
  globalThis.BEND_IO.waits.push({ at: performance.now() + 16, k: k, more: more });
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
  let yieldCount = 0;
  for (let step = steps.next();; step = steps.next()) {
    if (step.done) return step.value;
    // Hot sync loops (a frame per step, nothing parked) would starve the
    // event loop: inbound keys/lines could never be delivered and outbound
    // frames would queue without bound. Yield periodically so messages flow.
    if ((yieldCount++ & 15) === 0) await new Promise(resolve => setTimeout(resolve, 0));
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

// Window polyfill state, worker level for the same reason: input events
// arrive as later messages while the program keeps running.
let winNext = 1;
const winSizes = new Map<number, { w: number; h: number }>();
const winEvents: Array<{ kind: number; a: number; b: number; c: number; d: number }> = [];
// Display scale from the page (1 = native). Fractional scales rasterize
// fewer pixels; input coordinates scale back to native program space.
let dispScale = 1;
let workerDebug = false;
function dbg(msg: string): void {
  if (workerDebug) self.postMessage({ type: "dbg", from: "runner", msg });
}
// A quadtree fill mirroring the native pixel walk: children go
// [tl, tr, bl, br], colors are 0x00RRGGBB. One visit per node plus a
// tight rect fill beats a per-pixel walk; output is identical.
// A different target size samples the same tree (nearest neighbor),
// so any display size works; same-size takes the fast fill path.
function winPixels(image: unknown, nw: number, nh: number, tw: number, th: number): Uint8ClampedArray {
  if (tw === nw && th === nh) {
    let k = 0;
    while ((1 << k) < nw || (1 << k) < nh) k++;
    const out = new Uint8ClampedArray(nw * nh * 4);
    const size = 1 << k;
    const fill = (t: any, x0: number, y0: number, s: number): void => {
      if (typeof t === "object" && t !== null && t.$ === "Qua" && s > 1) {
        const h2 = s >> 1;
        fill(t.tl, x0, y0, h2);
        fill(t.tr, x0 + h2, y0, h2);
        fill(t.bl, x0, y0 + h2, h2);
        fill(t.br, x0 + h2, y0 + h2, h2);
        return;
      }
      let c: number;
      if (typeof t === "number") c = t >>> 0;
      else if (typeof t === "object" && t !== null && t.$ === "Pix") c = (t.color as number) >>> 0;
      else if (typeof t === "object" && t !== null && t.$ === "Qua") {
        let u: any = t;
        while (typeof u === "object" && u !== null && u.$ === "Qua") u = u.tl;
        c = typeof u === "number" ? u >>> 0 : 0;
      } else c = 0;
      const r = (c >> 16) & 255, g = (c >> 8) & 255, b = c & 255;
      const x1 = Math.min(x0 + s, nw), y1 = Math.min(y0 + s, nh);
      for (let y = Math.max(y0, 0); y < y1; y++) {
        let o = (y * nw + Math.max(x0, 0)) * 4;
        for (let x = Math.max(x0, 0); x < x1; x++) {
          out[o] = r; out[o + 1] = g; out[o + 2] = b; out[o + 3] = 255;
          o += 4;
        }
      }
    };
    fill(image, 0, 0, size);
    return out;
  }
  let k = 0;
  while ((1 << k) < nw || (1 << k) < nh) k++;
  const out = new Uint8ClampedArray(tw * th * 4);
  for (let y = 0; y < th; y++) {
    const ny = Math.min(nh - 1, (y * nh / th) | 0);
    for (let x = 0; x < tw; x++) {
      const nx = Math.min(nw - 1, (x * nw / tw) | 0);
      let t: any = image;
      let i = k;
      while (i > 0 && typeof t === "object" && t !== null && t.$ === "Qua") {
        i--;
        const j = ((ny >> i) & 1) * 2 + ((nx >> i) & 1);
        t = j === 0 ? t.tl : j === 1 ? t.tr : j === 2 ? t.bl : t.br;
      }
      const c = typeof t === "number" ? t >>> 0
        : typeof t === "object" && t !== null && t.$ === "Pix" ? (t.color as number) >>> 0 : 0;
      const o = (y * tw + x) * 4;
      out[o] = (c >> 16) & 255;
      out[o + 1] = (c >> 8) & 255;
      out[o + 2] = c & 255;
      out[o + 3] = 255;
    }
  }
  return out;
}

self.onmessage = async ({ data }: MessageEvent) => {
  if (data.javascript === undefined) {
    if (typeof data.text === "string" || data.eof) {
      // A line (or EOF) for the running program. Only one runs per worker.
      if (data.eof) stdinEOF = true;
      else if (typeof data.text === "string") stdinLines.push(data.text);
      deliverLine();
      return;
    }
    if (data.win === "event" && data.ev) {
      // A DOM input event for the next Window.frame to drain.
      winEvents.push(data.ev);
      if (winEvents.length > 4096) winEvents.shift();
      dbg(`win-event kind=${data.ev.kind} queued (depth ${winEvents.length})`);
      return;
    }
    if (typeof data.display?.scale === "number" && isFinite(data.display.scale)) {
      dispScale = Math.min(4, Math.max(0.05, data.display.scale));
      dbg(`display scale ${dispScale}`);
      return;
    }
    return;
  }
  // Fresh stdin per program: the Stdin box prefills lines; once they run
  // out the program parks and the page is asked per line. EOF ends input.
  const raw = String(data.stdin ?? "");
  workerDebug = data.debug === true;
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
    dbg(msg: string) { dbg(String(msg)); },
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
    winOpen(title: unknown, width: unknown, height: unknown) {
      const w = Number(width);
      const h = Number(height);
      if (!(w >= 1 && h >= 1 && w <= 16384 && h <= 16384)) {
        return { $: "Fail", error: { $: "Tuple", fst: 22, snd: "Window.open: bad size" } };
      }
      const id = winNext++;
      winSizes.set(id, { w, h });
      dbg(`win-open ${w}x${h} "${String(title)}" -> id ${id}`);
      self.postMessage({ type: "win-open", id, title: String(title), w, h });
      return { $: "Done", value: id };
    },
    winFrame(handle: unknown, image: unknown) {
      const id = Number(handle);
      const size = winSizes.get(id) ?? { w: 0, h: 0 };
      if (size.w > 0 && size.h > 0) {
        const tw = Math.max(1, Math.floor(size.w * dispScale));
        const th = Math.max(1, Math.floor(size.h * dispScale));
        const pix = winPixels(image, size.w, size.h, tw, th);
        self.postMessage({ type: "win-frame", id, w: tw, h: th, pix: pix.buffer }, [pix.buffer]);
      }
      let evs: any = { $: "Nil" };
      const drained = winEvents.length;
      // Input arrives in display pixels; scale back to native program space.
      const sx = (v: number) => Math.min(size.w - 1, Math.max(0, Math.floor(v / dispScale)));
      const sy = (v: number) => Math.min(size.h - 1, Math.max(0, Math.floor(v / dispScale)));
      for (let i = winEvents.length - 1; i >= 0; i--) {
        const e = winEvents[i];
        const head = e.kind === 0 ? { $: "Key", code: e.a, down: !!e.b }
          : e.kind === 1 ? { $: "Mouse", x: sx(e.a), y: sy(e.b), button: e.c, down: !!e.d }
          : e.kind === 2 ? { $: "Move", x: sx(e.a), y: sy(e.b) }
          : { $: "Close" };
        evs = { $: "Con", head, tail: evs };
      }
      winEvents.length = 0;
      dbg(`win-frame id ${id}: drained ${drained} event(s)`);
      return { $: "Tuple", fst: handle, snd: { $: "Tuple", fst: image, snd: evs } };
    },
    winTitle(handle: unknown, title: unknown) {
      self.postMessage({ type: "win-title", id: Number(handle), title: String(title) });
      return handle;
    },
    winClose(handle: unknown) {
      winSizes.delete(Number(handle));
      self.postMessage({ type: "win-close", id: Number(handle) });
      return { $: "Unit" };
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
