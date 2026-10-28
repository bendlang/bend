// This API is native: exercise the real C consumer in JS lanes too.
function fatal_cleanup_test() {
  const fs = require("node:fs");
  const path = require("node:path");
  const child = require("node:child_process");
  const directory = fs.mkdtempSync(path.join(process.cwd(), ".bend-fatal-cleanup-"));
  try {
    const binary = path.join(directory, "check");
    const bun = typeof Bun !== "undefined";
    const command = bun ? process.execPath : "bun";
    const prefix = bun && Bun.main.startsWith("/$bunfs/")
      ? [] : [path.resolve("bend2/main.ts")];
    const built = child.spawnSync(command,
      [...prefix, path.resolve("tests/io/fatal_cleanup.bend"), "-o", binary],
      { encoding: "utf8" });
    if (built.error || built.status !== 0) {
      throw built.error ?? new Error(built.stderr);
    }
    const ran = child.spawnSync(binary, { encoding: "utf8", timeout: 5000 });
    if (ran.error || ran.status !== 0 || ran.stdout !== "0\n" || ran.stderr !== "") {
      throw ran.error ?? new Error(JSON.stringify(ran));
    }
    return 0;
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
}

io_eff(CID(FatalCleanup.test), fatal_cleanup_test);
