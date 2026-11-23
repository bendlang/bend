function bundle_own_exports() {
  const fs = require("node:fs");
  const path = require("node:path");
  const child = require("node:child_process");
  const dir = fs.mkdtempSync(path.join(process.cwd(), ".bend-own-exports-"));
  const run = (...args) => child.spawnSync(process.execPath, args, {
    encoding: "utf8",
    env: { ...process.env, HOME: dir, BEND_ORIGIN: "http://127.0.0.1:9" },
  });
  const put = (name, text) => fs.writeFileSync(path.join(dir, name), text);
  const out = path.join(dir, "out");
  try {
    put("lib.bend", 'import Base\n\ndef used() -> U32: 7\n\ndef unused() -> String: "BEND_UNUSED_7f3a"\n');
    put("m.bend", "import Base\nimport ./lib.bend as L\n\ndef pick() -> U32: L.used()\n");
    put("p.html", '<script type="module">import M from "./m.bend";'
      + ' console.log(M.pick(), Object.keys(M).join());</script>\n');
    if (run(path.resolve("bend2/main.ts"), path.join(dir, "p.html"), "-o", out).status !== 0) return 1;
    const js = fs.readdirSync(out).filter((f) => f.endsWith(".js"))
      .map((f) => fs.readFileSync(path.join(out, f), "utf8")).join("");
    if (js.includes("BEND_UNUSED_7f3a")) return 2;
    const src = /src="([^"]+)"/.exec(fs.readFileSync(path.join(out, "p.html"), "utf8"))?.[1];
    if (!src) return 3;
    const got = run(path.resolve(out, src));
    return got.status === 0 && got.stdout.trim() === "7 pick" ? 0 : 4;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

io_eff(CID(Bundle.own_exports), bundle_own_exports);
