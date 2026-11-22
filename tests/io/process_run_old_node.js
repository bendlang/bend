function process_run_old_node() {
  const bun = typeof Bun !== "undefined";
  const node = bun ? Bun.which("node") : process.execPath;
  if (node === null) return 0;
  const fs = require("node:fs");
  const path = require("node:path");
  const child = require("node:child_process");
  const dir = fs.mkdtempSync(path.join(require("node:os").tmpdir(),
    ".bend-process-node-"));
  try {
    const input = path.join(dir, "main.bend");
    const output = path.join(dir, "main.cjs");
    const preload = path.join(dir, "preload.cjs");
    fs.writeFileSync(input, `import Base

def answer(r: Result<&1, &1, U32 & String, U32 & (String & String)>) -> Bool:
  match r:
    case Fail{error}: False{}
    case Done{(code, (out, err))}:
      Bool.and(U32.is_eq(code, 0),
        Bool.and(String.eq(out, "hello\\n"), String.eq(err, "")))

def main() -> IO(Unit):
  do IO<Unit>:
    r : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("/bin/echo", ["hello"], "", 128, 1000)
    IO.print(Bool.show(answer(r)))
`);
    fs.writeFileSync(preload, "delete process.getBuiltinModule;\n");
    const command = bun ? process.execPath : "bun";
    const prefix = bun && Bun.main.startsWith("/$bunfs/")
      ? [] : [path.resolve("bend2/main.ts")];
    const options = {
      encoding: "utf8",
      env: { ...process.env, HOME: dir, BEND_ORIGIN: "http://127.0.0.1:9" },
    };
    delete options.env.NODE_OPTIONS;
    const built = child.spawnSync(command,
      [...prefix, input, "-o", output], options);
    if (built.status !== 0) {
      throw built.error ?? new Error(built.stderr);
    }
    const ran = child.spawnSync(node, ["--require", preload, output],
      { ...options, timeout: 5000 });
    if (ran.error) {
      throw ran.error;
    }
    if (ran.status !== 0 || ran.stdout !== "True\n" || ran.stderr !== "") {
      return 1;
    }
    return 0;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

io_eff(CID(Host.process_run_old_node), process_run_old_node);
