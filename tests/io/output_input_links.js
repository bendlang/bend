function output_input_links() {
  const fs = require("node:fs");
  const os = require("node:os");
  const path = require("node:path");
  const child = require("node:child_process");
  // Outside the repo, so a run the alarm kills leaves no files in the tree.
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "bend-output-input-"));
  const inputs = new Map([
    ["main.bend", 'import Base\nimport ./lib.bend as Lib\n'
      + 'def Probe.value() -> IO(U32):\n'
      + '  import "./effect.js"\n  import "./effect.c"\n'
      + 'def main() -> U32:\n  Lib.value()\n'],
    ["lib.bend", "import Base\ndef value() -> U32:\n  42\n"],
    ["effect.js", "io_eff(CID(Probe.value), () => 42);\n"],
    ["effect.c", "// Foreign input.\n"],
  ].map(([name, text]) => [path.join(dir, name), text]));
  const main = path.join(dir, "main.bend");
  const options = { encoding: "utf8", timeout: 30000,
    env: { ...process.env, HOME: dir, BEND_ORIGIN: "http://127.0.0.1:9",
      BEND_NO_TELEMETRY: "1" },
  };
  const build = (...outs) => child.spawnSync(process.execPath,
    [path.resolve("bend2/main.ts"), main, ...outs.flatMap((out) => ["-o", out])],
    options);
  const intact = () => [...inputs].every(([file, text]) =>
    fs.readFileSync(file, "utf8") === text);
  const rejects = (got, msg) => got.status === 1 && got.stderr.includes(msg)
    && intact();
  try {
    for (const [file, text] of inputs) fs.writeFileSync(file, text);
    const link = path.join(dir, "out.js");
    const ok = path.join(dir, "ok.js");
    let code = 1;
    if (!rejects(build(main), "is a file the program reads")) return code;
    code++;
    fs.symlinkSync(main, link);
    if (!rejects(build(link), "is a file the program reads")) return code;
    fs.unlinkSync(link);
    code++;
    for (const file of inputs.keys()) {
      fs.linkSync(file, link);
      if (!rejects(build(link), "is a file the program reads")) return code;
      fs.unlinkSync(link);
      code++;
    }
    if (!rejects(build(dir), "or a directory")) return code;
    code++;
    // A rejected output fails the build before any output is written.
    fs.linkSync(main, link);
    if (!rejects(build(ok, link), "is a file the program reads")
      || fs.existsSync(ok)) return code;
    fs.unlinkSync(link);
    code++;
    // Outputs must also be distinct before any of them is written.
    const alias = path.join(dir, "alias.mjs");
    const duplicate = (a, b) => {
      const got = build(a, b);
      return got.status === 1 && got.stderr.includes("conflicts with another output")
        && !fs.existsSync(ok) && intact();
    };
    if (!duplicate(ok, ok)) return code;
    fs.symlinkSync(ok, alias); // dangling when the preflight runs
    if (!duplicate(ok, alias) || !duplicate(alias, ok)) return code;
    fs.unlinkSync(alias);
    const dirLink = path.join(dir, "linked-dir");
    fs.symlinkSync(dir, dirLink);
    if (!duplicate(ok, path.join(dirLink, "ok.js"))) return code;
    fs.unlinkSync(dirLink);
    fs.writeFileSync(alias, "keep");
    fs.linkSync(alias, ok);
    const hard = build(ok, alias);
    if (hard.status !== 1 || !hard.stderr.includes("conflicts with another output")
      || fs.readFileSync(alias, "utf8") !== "keep" || !intact()) return code;
    fs.unlinkSync(ok);
    fs.unlinkSync(alias);
    // Simulate toolkit detection, so a real GPU build would write the sidecar.
    const binAlias = path.join(dir, "other.mjs");
    const binPath = path.join(dir, "collision");
    const gpuMain = path.join(dir, "bang.bend");
    fs.writeFileSync(gpuMain, "import Base\ndef f(x: U32) -> U32:\n  x\n"
      + "def main() -> U32:\n  f!(42)\n");
    const cuda = path.join(dir, "cuda");
    fs.mkdirSync(path.join(cuda, "include"), { recursive: true });
    fs.writeFileSync(path.join(cuda, "include", "nvrtc.h"), "");
    fs.symlinkSync(binPath + ".gpu", binAlias);
    const gpu = child.spawnSync(process.execPath, [path.resolve("bend2/main.ts"),
      gpuMain, "-o", binPath, "-o", binAlias],
      { ...options, env: { ...options.env, CUDA_HOME: cuda } });
    if (!rejects(gpu, "conflicts with another output") || fs.existsSync(binPath)
      || fs.existsSync(binPath + ".gpu")) return code;
    fs.unlinkSync(binAlias);
    code++;
    // CPU binaries have no sidecar, so both output names are valid.
    const cpu = path.join(dir, "cpu");
    const cpuGpu = cpu + ".gpu";
    if (build(cpu, cpuGpu).status !== 0) return code;
    for (const file of [cpu, cpuGpu]) {
      const ran = child.spawnSync(file, [], options);
      if (ran.status !== 0 || ran.stdout.trim() !== "42") return code;
      fs.unlinkSync(file);
    }
    // On Linux without CUDA, a bang also builds two CPU-only binaries.
    if (process.platform === "linux" && ![process.env.CUDA_HOME, process.env.CUDA_PATH,
      "/usr/local/cuda", "/opt/cuda"].some((d) => d && fs.existsSync(d + "/include/nvrtc.h"))) {
      const fallback = child.spawnSync(process.execPath, [path.resolve("bend2/main.ts"),
        gpuMain, "-o", cpu, "-o", cpuGpu], options);
      if (fallback.status !== 0 || !fallback.stderr.includes("so ! runs on the CPU")) return code;
      for (const file of [cpu, cpuGpu]) {
        const ran = child.spawnSync(file, [], options);
        if (ran.status !== 0 || ran.stdout.trim() !== "42") return code;
        fs.unlinkSync(file);
      }
    }
    code++;
    if (build(ok).status !== 0 || !intact()) return code;
    const run = child.spawnSync(process.execPath, [ok], options);
    if (run.status !== 0 || run.stdout.trim() !== "42") return code;
    code++;
    // A GPU archive is an output too, even though it has no -o.
    const bin = path.join(dir, "program");
    const cache = bin + ".gpu";
    const entry = path.join(dir, "gpu.bend");
    const text = "import Base\ndef main() -> U32:\n  42\n";
    fs.unlinkSync(ok);
    fs.writeFileSync(cache, text);
    inputs.set(cache, text);
    fs.symlinkSync(cache, entry);
    const got = child.spawnSync(process.execPath, [path.resolve("bend2/main.ts"),
      entry, "-o", ok, "-o", bin], options);
    if (!rejects(got, "GPU output") || fs.existsSync(ok)
      || fs.existsSync(bin)) return code;
    return 0;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

io_eff(CID(Output.input_links), output_input_links);
