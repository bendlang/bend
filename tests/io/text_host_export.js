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

def poly(-A: Data, x: A) -> A:
  x

def deep() -> List<String>:
  ["a", odd()]

def cell() -> Array<String>:
  Array.new(String, 1n, odd())

def pre() -> String -> String:
  s => SCon{Chr{55296}, s}

def apply(f: String -> String) -> U32:
  count(f(odd()))

def bump(a: Array<U32>) -> Array<U32>:
  Array.set(U32, a, 0, 9)
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
    const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
    if (!["", "plain", "é", "\u{1F600}x"].every((s) => lib.identity(s) === s)
      || lib.identity("\uDC00\0\u001B\0") !== "\uFFFD\0\u001B\0") {
      return 2;
    }
    if (lib.count("\uDC00\0\u001B\0x") !== 5 || lib.code("\uDC00") !== 65533
      || lib.odd() !== "\uFFFDx" || lib.odd_char() !== "\uFFFD") {
      return 3;
    }
    const tup = lib.poly({$: "Tuple", fst: "\uD800", snd: ["ok", "\uDFFF"]});
    if (!same(tup, {$: "Tuple", fst: "\uFFFD", snd: ["ok", "\uFFFD"]})
      || lib.deep().tail.head !== "\uFFFDx" || !same(lib.cell(), ["\uFFFDx", "\uFFFDx"])) {
      return 4;
    }
    let got;
    const n = lib.apply((s) => (got = s, s + "\uD800"));
    if (lib.pre()("\uD800") !== "\uFFFD\uFFFD" || got !== "\uFFFDx" || n !== 3) {
      return 5;
    }
    const arr = [1, 2], kept = {$: "Tuple", fst: "ok", snd: arr};
    return lib.bump(arr) === arr && arr[0] === 9 && lib.poly(kept) === kept ? 0 : 6;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

io_eff(CID(Text.host_export), text_host_export);
