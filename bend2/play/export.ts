#!/usr/bin/env bun
// Static export of the browser playground: builds client/worker/runner with
// the same bundler config as play/server.ts, bakes base.bend and the effect
// sources, and writes a five-file dir servable by any static host
// (lighttpd, nginx, python -m http.server). Asset paths are relative, so the
// dir works at a domain root or under a subpath. No backend serves after.
//
//   bun bend2/play/export.ts [outdir=./play-dist]

import * as fs from "node:fs";
import * as path from "node:path";

const here = import.meta.dirname;
const root = path.dirname(here);
const out = path.resolve(process.argv[2] ?? path.join(root, "..", "play-dist"));

const files: Record<string, string> = {
  "/base.bend": fs.readFileSync(path.join(root, "base.bend"), "utf8"),
};
for (const name of fs.readdirSync(path.join(root, "effs"))) {
  if (/\.(c|js)$/.test(name)) {
    files["/effs/" + name] = fs.readFileSync(path.join(root, "effs", name), "utf8");
  }
}
const build = await Bun.build({
  entrypoints: [path.join(here, "client.ts"), path.join(here, "worker.ts"), path.join(here, "runner.ts")],
  target: "browser",
  format: "esm",
  minify: true,
  outdir: out,
  define: { "process.env.BEND_LIB": JSON.stringify("/packages"),
    "process.env.BEND_HUB": JSON.stringify("https://hub.bend-lang.com") },
  plugins: [{
    name: "bend-browser-platform",
    setup(build) {
      build.onResolve({ filter: /^node:(fs|os|path|url)$/ }, () =>
        ({ path: path.join(here, "platform.ts") }));
      build.onLoad({ filter: /\/play\/assets\.ts$/ }, () =>
        ({ contents: "export const FILES = " + JSON.stringify(files), loader: "js" }));
    },
  }],
});
if (!build.success) {
  throw new Error(build.logs.map(String).join("\n"));
}
// Relative asset paths: the same dir serves at / or under a subpath.
const html = fs.readFileSync(path.join(here, "index.html"), "utf8")
  .replace('href="/style.css"', 'href="./style.css"')
  .replace('src="/client.js"', 'src="./client.js"')
  .replace('href="/"', 'href="./"');
fs.writeFileSync(path.join(out, "index.html"), html);
fs.copyFileSync(path.join(here, "style.css"), path.join(out, "style.css"));
fs.mkdirSync(path.join(out, "vendor"), { recursive: true });
for (const name of ["ace.js", "theme-chrome.js", "mode-bend.js"]) {
  fs.copyFileSync(path.join(here, "vendor", name), path.join(out, "vendor", name));
}
// Demo sources ship as plain static files for the picker's fetch.
const copyDemos = (dir: string): void => {
  for (const name of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, name.name);
    if (name.isDirectory()) copyDemos(full);
    else if (name.name.endsWith(".bend")) {
      const dest = path.join(out, "demos", path.relative(path.join(root, "..", "demos"), full));
      fs.mkdirSync(path.dirname(dest), { recursive: true });
      fs.copyFileSync(full, dest);
    }
  }
};
copyDemos(path.join(root, "..", "demos"));
for (const name of ["client.js", "worker.js", "runner.js"]) {
  const file = path.join(out, name);
  fs.writeFileSync(file, fs.readFileSync(file, "utf8")
    .replaceAll('"/worker.js"', '"./worker.js"')
    .replaceAll('"/runner.js"', '"./runner.js"'));
}
console.log("Bend playground static export: " + out);
