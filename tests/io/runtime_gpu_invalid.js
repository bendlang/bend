function runtime_gpu_invalid() {
  const fs = require("node:fs");
  const path = require("node:path");
  const child = require("node:child_process");
  const dir = fs.mkdtempSync(path.join(process.cwd(), ".bend-runtime-gpu-"));
  try {
    const input = path.join(dir, "main.bend");
    const output = path.join(dir, "main.cjs");
    fs.writeFileSync(input,
      'import Base\ndef main() -> IO(Unit):\n  IO.print("ran")\n');
    const bun = typeof Bun !== "undefined";
    const compiled = bun && Bun.main.startsWith("/$bunfs/");
    const prefix = compiled ? [] : [path.resolve("bend2/main.ts")];
    const built = child.spawnSync(bun ? process.execPath : "bun",
      [...prefix, input, "-o", output], {
        encoding: "utf8", env: { ...process.env, BEND_NO_TELEMETRY: "1" },
      });
    if (built.status !== 0) {
      throw built.error ?? new Error(built.stderr);
    }
    // Build argv inside the child, past the OS's per-argument size limit.
    const code = `process.argv = [process.execPath, ${JSON.stringify(output)},
      "+RTS", "--gpu", "9".repeat(500000)];
require(${JSON.stringify(output)});`;
    const ran = child.spawnSync(compiled ? "bun" : process.execPath, ["-e", code], {
      encoding: "utf8", timeout: 3000,
    });
    return ran.status === 1 && ran.stdout === "" && ran.stderr
      === "bend: expected on, off or a size like 4GB after --gpu\n" ? 0 : 1;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

io_eff(CID(Host.runtime_gpu_invalid), runtime_gpu_invalid);
