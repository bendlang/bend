import * as fs from "node:fs";
import * as path from "node:path";

// Only assets cross HTTP. Bend's loader, checker and emitters run in a worker.
export async function serve(port = 3000): Promise<void> {
  const here = import.meta.dirname;
  const root = path.dirname(here);
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
  const assets = new Map<string, { body: Blob; type: string }>([
    ["/", { body: Bun.file(path.join(here, "index.html")), type: "text/html; charset=utf-8" }],
    ["/style.css", { body: Bun.file(path.join(here, "style.css")), type: "text/css; charset=utf-8" }],
  ]);
  for (const output of build.outputs) {
    assets.set("/" + path.basename(output.path), { body: output, type: "text/javascript; charset=utf-8" });
  }
  const server = Bun.serve({
    hostname: "127.0.0.1", port,
    fetch(request) {
      if (request.method !== "GET" && request.method !== "HEAD") {
        return new Response("Method not allowed", { status: 405, headers: { Allow: "GET, HEAD" } });
      }
      const route = new URL(request.url).pathname;
      const asset = assets.get(route);
      // Workers evaluate C table constants and generated JavaScript.
      const evaluation = (route === "/worker.js" || route === "/runner.js") ? " 'unsafe-eval'" : "";
      if (!asset) return new Response("Not found", { status: 404 });
      return new Response(request.method === "HEAD" ? null : asset.body, { headers: {
        "Content-Type": asset.type,
        "Cache-Control": "no-cache",
        "X-Content-Type-Options": "nosniff",
        "Content-Security-Policy": "default-src 'none'; script-src 'self'" + evaluation + "; style-src 'self'; worker-src 'self'; img-src 'self' data:; connect-src 'none'; base-uri 'none'; frame-ancestors 'none'",
      } });
    },
  });
  console.log("Bend playground: " + server.url);
  console.log("Compile in your browser. Press Ctrl+C to stop the server.");
}
