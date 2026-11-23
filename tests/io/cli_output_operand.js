function cli_output_operand() {
  const fs = require("node:fs");
  const path = require("node:path");
  const child = require("node:child_process");
  const bun = typeof Bun !== "undefined";
  const command = bun ? process.execPath : "bun";
  const cli = bun && Bun.main.startsWith("/$bunfs/") ? [] : [path.resolve("bend2/main.ts")];
  const dir = fs.mkdtempSync(path.join(require("node:os").tmpdir(), "bend-output-operand-"));
  try {
    fs.writeFileSync(path.join(dir, "main.bend"), 'import Base\ndef main() -> IO(Unit):\n  IO.print("hello")\n');
    const opts = { cwd: dir, encoding: "utf8", env: { ...process.env, BEND_NO_TELEMETRY: "1" } };
    const build = (...args) => child.spawnSync(command, [...cli, "main.bend", "-o", ...args], opts);
    for (const args of [[], [""], ["--check-only"], ["--"]]) {
      const result = build(...args);
      if (result.status !== 1 || !result.stderr.includes("-o needs an output file")) return 1;
    }
    if (fs.readdirSync(dir).join() !== "main.bend") return 2;
    if (build("./--named.js").status !== 0) return 3;
    const run = child.spawnSync(command, ["./--named.js"], opts);
    return run.status === 0 && run.stdout === "hello\n" ? 0 : 4;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

io_eff(CID(Cli.output_operand), cli_output_operand);
