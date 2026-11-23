function cli_source_location() {
  const fs = require("node:fs");
  const path = require("node:path");
  const child = require("node:child_process");
  const bun = typeof Bun !== "undefined";
  const command = bun ? process.execPath : "bun";
  const cli = bun && Bun.main.startsWith("/$bunfs/") ? [] : [path.resolve("bend2/main.ts")];
  const dir = fs.mkdtempSync(path.join(require("node:os").tmpdir(), "bend-location-"));
  try {
    const entry = path.join(dir, "main.bend");
    const dep = path.join(dir, "price.bend");
    fs.writeFileSync(entry, "import ./price.bend as P\n");
    fs.writeFileSync(dep, "import Base\n\ndef total(cost: U32) -> U32:\n  wrong\n");
    const reports = (args, position, excerpt) => {
      const run = child.spawnSync(command, [...cli, ...args], {
        encoding: "utf8", env: { ...process.env, BEND_NO_TELEMETRY: "1" },
      });
      return run.status === 1 && run.stderr.includes(excerpt)
        && run.stderr.includes("\n--> " + fs.realpathSync(dep) + position + "\n");
    };
    if (!reports([dep], ":4:3", "4>|   wrong")
      || !reports([entry, "--check-only"], ":4:3", "4>|   wrong")) {
      return 1;
    }
    fs.writeFileSync(dep, "import Base\nimport ./missing.bend as M\n");
    if (!reports([entry], ":2:8", "2>| import ./missing.bend as M")) {
      return 2;
    }
    // an error in a def with a ~ parameter is in this file, not in Base
    fs.writeFileSync(dep, "import Base\n\ndef total(~f: U32 -> U32, cost: U32) -> U32:\n  wrong\n");
    return reports([dep], ":4:3", "4>|   wrong") ? 0 : 3;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

io_eff(CID(Cli.source_location), cli_source_location);
