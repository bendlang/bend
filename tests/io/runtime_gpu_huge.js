function runtime_gpu_huge() {
  const fs = require("node:fs");
  const path = require("node:path");
  const child = require("node:child_process");
  const dir = fs.mkdtempSync(path.join(process.cwd(), ".bend-runtime-gpu-"));
  try {
    const input = path.join(dir, "main.bend");
    const bin = path.join(dir, "main");
    const js = path.join(dir, "main.cjs");
    fs.writeFileSync(input,
      'import Base\ndef main() -> IO(Unit):\n  IO.print("ran")\n');
    const bun = typeof Bun !== "undefined";
    const compiled = bun && Bun.main.startsWith("/$bunfs/");
    const prefix = compiled ? [] : [path.resolve("bend2/main.ts")];
    const built = child.spawnSync(bun ? process.execPath : "bun",
      [...prefix, input, "-o", bin, "-o", js], {
        encoding: "utf8", env: { ...process.env, BEND_NO_TELEMETRY: "1" },
      });
    if (built.status !== 0) {
      throw built.error ?? new Error(built.stderr);
    }
    const err = "bend: expected on, off or a size like 4GB after --gpu\n";
    const run = (size) => [[bin], [compiled ? "bun" : process.execPath, js]]
      .map(([cmd, ...pre]) => child.spawnSync(cmd,
        [...pre, "+RTS", "--gpu", size], { encoding: "utf8", timeout: 3000 }));
    const bad = ["999999999999GB", "17179869184GB", "1e400GB"].flatMap(run)
      .every((r) => r.status === 1 && r.stdout === "" && r.stderr === err);
    const good = ["17179869183GB", "4GB"].flatMap(run)
      .every((r) => r.status === 0 && r.stdout === "ran\n");
    return bad && good ? 0 : 1;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

io_eff(CID(Host.runtime_gpu_huge), runtime_gpu_huge);
