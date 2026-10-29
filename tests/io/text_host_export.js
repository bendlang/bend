function text_host_export() {
  const fs = require("node:fs");
  const path = require("node:path");
  const child = require("node:child_process");
  const dir = fs.mkdtempSync(path.join(process.cwd(), ".bend-text-export-"));
  try {
    const input = path.join(dir, "lib.bend");
    const output = path.join(dir, "lib.mjs");
    fs.writeFileSync(input, `import Base

def identity(s: String) -> String:
  s

def count(s: String) -> U32:
  match s:
    case SNil{}:
      0
    case SCon{h, t}:
      U32.add(1, count(t))

def code(c: Char) -> U32:
  Char.to_u32(c)

def odd() -> String:
  SCon{Chr{55296}, "x"}

def odd_char() -> Char:
  Chr{55296}
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
    const odd = "\uDC00\0\u001B\0";
    if (!["", "plain", "é", "\u{1F600}x", odd].every((s) => lib.identity(s) === s)) {
      return 2;
    }
    if (lib.count(odd + "x") !== 2 || lib.code(odd) !== 55296) {
      return 3;
    }
    return lib.odd() === odd + "x" && lib.odd_char() === odd ? 0 : 4;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

io_eff(CID(Text.host_export), text_host_export);
