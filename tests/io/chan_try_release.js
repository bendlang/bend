function chan_release_run(action) {
  if (globalThis.channel_release !== undefined) {
    return io_run(() => action);
  }
  const fs = require("node:fs");
  const path = require("node:path");
  const child = require("node:child_process");
  const dir = fs.mkdtempSync(path.join(process.cwd(), ".bend-chan-release-"));
  try {
    const output = path.join(dir, "probe.cjs");
    const compiled = Bun.main.startsWith("/$bunfs/");
    const built = child.spawnSync(process.execPath,
      [...compiled ? [] : [path.resolve("bend2/main.ts")],
        path.resolve("tests/io/chan_try_release.bend"), "-o", output], {
        encoding: "utf8", timeout: 3000,
        env: { ...process.env, BEND_NO_TELEMETRY: "1" },
      });
    if (built.status !== 0) {
      throw built.error ?? new Error(built.stderr);
    }
    // A WeakRef keeps its target alive until the creating job ends.
    const source = `globalThis.channel_release = { payload: [7] };
channel_release.ref = new WeakRef(channel_release.payload);
setTimeout(() => require(${JSON.stringify(output)}), 0);
`;
    const ran = child.spawnSync(compiled ? "bun" : process.execPath,
      ["-e", source], { encoding: "utf8", timeout: 2000 });
    if (ran.error) throw ran.error;
    // The probe prints 0 if collected, 1 if retained; anything else is shown.
    if (ran.status === 0 && ran.stderr === "" && /^[01]\n$/.test(ran.stdout)) {
      return Number(ran.stdout[0]);
    }
    throw new Error(`probe exited ${ran.status}: ${ran.stdout}${ran.stderr}`);
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

function chan_release_payload() {
  const value = globalThis.channel_release.payload;
  delete globalThis.channel_release.payload;
  return value;
}

function chan_release_collected() {
  Bun.gc(true);
  return globalThis.channel_release.ref.deref() === undefined ? 0 : 1;
}

io_eff(CID(Host.run), chan_release_run);
io_eff(CID(Host.payload), chan_release_payload);
io_eff(CID(Host.collected), chan_release_collected);
