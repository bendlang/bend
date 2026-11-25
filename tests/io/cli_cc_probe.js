function cli_cc_probe() {
  const fs = require("node:fs");
  const path = require("node:path");
  const child = require("node:child_process");
  const bun = typeof Bun !== "undefined";
  const command = bun ? process.execPath : "bun";
  const cli = bun && Bun.main.startsWith("/$bunfs/") ? [] : [path.resolve("bend2/main.ts")];
  const dir = fs.mkdtempSync(path.join(require("node:os").tmpdir(), "bend-cc-probe-"));
  try {
    const entry = path.join(dir, "app.bend");
    const cc = path.join(dir, "bad-cc");
    const bin = path.join(dir, "app");
    fs.writeFileSync(entry, 'import Base\ndef main() -> IO(Unit):\n  IO.print("hello")\n');
    fs.writeFileSync(cc,
      '#!/bin/sh\nif [ "$1" = --version ]; then echo "clang version 99.0"; fi\nexit 23\n',
      { mode: 0o700 });
    const built = child.spawnSync(command, [...cli, entry, "-o", bin], {
      encoding: "utf8", env: { ...process.env, BEND_NO_TELEMETRY: "1", CC: cc },
    });
    if (built.status !== 0 || !built.stderr.includes("fails --version")) return 1;
    const ran = child.spawnSync(bin, { encoding: "utf8" });
    return ran.status === 0 && ran.stdout === "hello\n" ? 0 : 2;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

io_eff(CID(Cli.cc_probe), cli_cc_probe);
