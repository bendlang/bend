function bundle_inline() {
  const fs = require("node:fs");
  const path = require("node:path");
  const child = require("node:child_process");
  const assert = require("node:assert/strict");
  const dir = fs.mkdtempSync(path.join(process.cwd(), ".bend-page-inline-"));
  const cli = path.resolve("bend2/main.ts");
  const deadline = Date.now() + 3500;
  const run_cli = (args) => child.spawnSync(process.execPath, args, {
    encoding: "utf8",
    env: { ...process.env, HOME: dir, BEND_ORIGIN: "http://127.0.0.1:9" },
    timeout: Math.max(1, deadline - Date.now()),
  });
  try {
    const page = path.join(dir, "page.html");
    const out = path.join(dir, "out");
    fs.writeFileSync(path.join(dir, "state.js"),
      "export const state = {value: 0};\n");
    fs.writeFileSync(page, "<!doctype html>\n"
      + '<script type="module">\n'
      + 'import {state} from "./state.js";\n'
      + "globalThis.__bend_bundle_rows.push(++state.value);\n</script>\n"
      + '<script type=" module ">\n'
      + 'import {state} from "./state.js";\n'
      + "globalThis.__bend_bundle_rows.push(++state.value);\n</script>\n");
    const build = (file, target) => run_cli([cli, file, "-o", target]);
    const snapshot = () => fs.readdirSync(out).sort().map((file) =>
      [file, fs.readFileSync(path.join(out, file))]);
    const first = build(page, out);
    assert.equal(first.status, 0, first.stderr);
    const initial = snapshot();
    const second = build(page, out);
    assert.equal(second.status, 0, second.stderr);
    assert.deepEqual(snapshot(), initial);
    const runner = path.join(dir, "run.mjs");
    fs.writeFileSync(runner, `
import { pathToFileURL } from "node:url";
globalThis.__bend_bundle_rows = [];
const modules = [];
let code = null;
await new HTMLRewriter().on("script", {
  element(el) {
    code = null;
    if (el.getAttribute("type")?.trim() === "module") {
      code = [];
      modules.push({src: el.getAttribute("src"), code});
    }
  },
  text(text) {
    code?.push(text.text);
  },
}).transform(new Response(Bun.file(process.argv[2]))).text();
const root = new URL(".", pathToFileURL(process.argv[2]));
for (const [index, module] of modules.entries()) {
  const file = new URL(module.src ?? "inline-" + index + ".mjs", root);
  if (module.src === null) {
    await Bun.write(file, module.code.join(""));
  }
  await import(file.href);
}
console.log(JSON.stringify(globalThis.__bend_bundle_rows));
`);
    const run = run_cli([runner, path.join(out, "page.html")]);
    assert.equal(run.status, 0, run.stderr);
    assert.equal(run.stdout.trim(), "[1,2]");
    const bad = path.join(dir, "bad.html");
    fs.writeFileSync(bad, "<!doctype html>\n"
      + '<!-- <script type="module">const broken = ;</script> -->\n'
      + '<div data-fake="<script>fake</script>">quoted fake</div>\n'
      + '<script\n type="module" data-other=">">\n'
      + "const valid = 1;\nconst broken = ;\n</script>\n");
    const failure = build(bad, path.join(dir, "bad-out"));
    assert.equal(failure.status, 1);
    assert.ok(failure.stderr.includes(bad + ":7:"), failure.stderr);
    return 0;
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

io_eff(CID(Bundle.inline), bundle_inline);
