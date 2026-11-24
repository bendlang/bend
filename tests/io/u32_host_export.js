function u32_host_export() {
  const fs = require("node:fs");
  const path = require("node:path");
  const child = require("node:child_process");
  const dir = fs.mkdtempSync(path.join(process.cwd(), ".bend-u32-export-"));
  try {
    const input = path.join(dir, "lib.bend");
    const output = path.join(dir, "lib.mjs");
    fs.writeFileSync(input, `import Base

def show(x: U32) -> String:
  U32.show(x)

def zero(x: U32) -> Bool:
  U32.is_zero(x)

def add(a: U32, b: U32) -> U32:
  U32.add(a, b)
`);
    const built = child.spawnSync(process.execPath,
      [path.resolve("bend2/main.ts"), input, "-o", output], {
        encoding: "utf8",
        env: { ...process.env, HOME: dir, BEND_ORIGIN: "http://127.0.0.1:9" },
      });
    if (built.status !== 0) {
      return 1;
    }
    const lib = require(output).default;
    const rows = [[7, "7", false], [2 ** 32, "0", true],
      [-1, "4294967295", false], [2 ** 32 + 5, "5", false]];
    for (const [x, s, z] of rows) {
      if (lib.show(x) !== s || lib.zero(x) !== z) {
        return 2;
      }
    }
    return lib.add(2 ** 32 - 1, 2 ** 32 + 1) === 0
      && lib.add(-1)(2 ** 32 + 2) === 1 ? 0 : 3;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

io_eff(CID(U32.host_export), u32_host_export);
