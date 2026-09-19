import { cp, mkdir, rm } from "node:fs/promises";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { build } from "esbuild";

const here = dirname(fileURLToPath(import.meta.url));
const at = (file) => join(here, file);
await rm(at("dist"), { recursive: true, force: true });
await mkdir(at("dist"), { recursive: true });
await build({
  absWorkingDir: here,
  entryPoints: [at("src/server.ts")],
  outdir: at("dist"),
  platform: "node",
  format: "esm",
  target: "node22",
  bundle: false,
  sourcemap: true,
});
await build({
  absWorkingDir: here,
  entryPoints: [at("src/analysis-worker.ts")],
  outfile: at("dist/analysis-worker.js"),
  platform: "node",
  format: "esm",
  target: "node22",
  bundle: true,
  sourcemap: true,
});
await build({
  absWorkingDir: here,
  entryPoints: [at("src/formatter.ts"), at("src/analysis.ts"), at("src/lexical.ts")],
  outdir: at("dist"),
  platform: "node",
  format: "esm",
  target: "node22",
  bundle: false,
  sourcemap: true,
});
await build({
  absWorkingDir: here,
  entryPoints: [at("src/test/formatter.test.ts"), at("src/test/server.test.ts"), at("src/test/analysis.test.ts")],
  outdir: at("dist/test"),
  platform: "node",
  format: "esm",
  target: "node22",
  bundle: false,
  sourcemap: true,
});
await cp(at("../../bend2/base.bend"), at("dist/base.bend"));
