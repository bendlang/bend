function module_export_closure() {
  const fs = require("node:fs");
  const path = require("node:path");
  const child = require("node:child_process");
  const dir = fs.mkdtempSync(path.join(process.cwd(), ".bend-export-closure-"));
  try {
    const input = path.join(dir, "lib.bend");
    const output = path.join(dir, "lib.mjs");
    fs.writeFileSync(input, `import Base

def pre(-skip: U32, a: String) -> String -> String:
  String.append(a)

def first(c: Char, d: Char) -> Char:
  c

def keep(c: Char) -> Char -> Char:
  first(c)

def eta(a: String) -> String -> String:
  b => String.append(a, b)

def text(-skip: U32) -> String:
  SCon{Chr{55296}, SNil{}}
`);
    const bun = typeof Bun !== "undefined";
    const command = bun ? process.execPath : "bun";
    const prefix = bun && Bun.main.startsWith("/$bunfs/")
      ? [] : [path.resolve("bend2/main.ts")];
    const built = child.spawnSync(command, [...prefix, input, "-o", output], {
      encoding: "utf8",
      env: { ...process.env, HOME: dir, BEND_ORIGIN: "http://127.0.0.1:9" },
    });
    if (built.status !== 0) {
      throw built.error ?? new Error(built.stderr);
    }
    const lib = require(output).default;
    return lib.pre("hello ")("world") === "hello world"
      && lib.keep("A")("B") === "A"
      && lib.eta("hello ")("world") === "hello world"
      && lib.text() === "\ufffd" ? 0 : 1;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

io_eff(CID(Module.export_closure), module_export_closure);
