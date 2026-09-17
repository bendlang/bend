#!/usr/bin/env bun
// The launcher, the installer, a release and the ping, on this machine: a
// hub.ts on a random localhost port with its log and DL_DIR in a temp dir,
// behind a Bun.serve that plays Caddy (/dl/* from DL_DIR, /ping to the hub,
// /install.sh from the site repo, lib.SITE), a release.ts --dry into that
// DL_DIR, an install.sh against it (Bun is here, so it installs nothing), then
// bend --help through the launcher. Checks: the help and the guide print,
// current points at app/<ver>, the log has the run's cmd, the installer
// discloses the telemetry once and puts bin on the PATH of the shell's rc, an
// old bend on PATH is left alone and named, a run with a file logs cmd "run", a
// second release with a notice prints it and switches current (on the run after
// the ping that learned of it: a run reads the previous reply and pings in the
// background, so the gate waits for the reply file after each run),
// BEND_NO_TELEMETRY=1 sends nothing and installs nothing. Then the launcher
// under attack:
// ten runs at once during an update all pass and leave one whole release; a ver
// of ../../victim deletes nothing and installs nothing; an HTML answer, a wrong
// sha256, a tarball without bend2/main.ts, a dead origin and a notice with
// newlines and escapes leave the installed release running (a failed ver is
// remembered in `bad` and not fetched again); a BEND_HOME with a space and a
// quote installs; a read-only BEND_HOME runs; a current left dangling is
// installed again; a first run with nothing installed and no origin says so in
// one line; a reply whose sha256 is not 64 hex digits installs nothing; a
// BEND_HOME with a backslash activates the release (Bun itself cannot run from
// such a path); a bunfig.toml preload in the cwd cannot hang the update; a real
// directory at current is moved aside; a staging directory that cannot be made
// (app/<ver> is a file) touches nothing (a .tgz in the cwd survives); a hub
// that is down still updates through /dl/latest.json; a 2 KiB ping is refused
// and an unwritable log still answers; a reinstall over a symlinked bin/bend
// leaves its target alone. Last, the npm shim (the site repo's front/npm),
// packed and installed under a prefix, installs and runs bend once and only
// runs it the second time (SKIP without npm). The whole gate is SKIP when the
// site repo is not at lib.SITE.

import * as child from "node:child_process";
import * as crypto from "node:crypto";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

import * as lib from "./_lib";

// Constants
// =========

if (!fs.existsSync(path.join(lib.SITE, "front", "install.sh"))) {
  console.log("SKIP the site repo is not at " + lib.SITE + " (set SITE_REPO)");
  lib.verdict(0, 0);
}

const PORT   = 20000 + Math.floor(Math.random() * 40000);
const ORIGIN = "http://localhost:" + String(PORT);
const HUB    = "http://localhost:" + String(PORT + 1);
const TMP    = fs.mkdtempSync(path.join(os.tmpdir(), "bend-ping-"));
const HOME   = path.join(TMP, "home");
const DL     = path.join(TMP, "dl");
const LOG    = path.join(TMP, "log.jsonl");
const TELL   = "bend sends anonymous usage data and updates itself";
const SAID   = "Bend sends anonymous usage data";
// install.sh names the `bend` it finds on PATH: never hand it the real one
// (bun's own bin dir holds it), so PATH is a private dir with only bun.
const SAFE   = path.join(TMP, "path") + ":/usr/bin:/bin";
fs.mkdirSync(path.join(TMP, "path"));
fs.symlinkSync(process.execPath, path.join(TMP, "path", "bun"));

const fails: string[] = [];
let total = 0;

// Run
// ===

// the runs are async: the gate's own server answers them meanwhile
function run(bin: string, args: string[], env: Record<string, string>,
  cwd?: string): Promise<lib.Exec> {
  return lib.exec(bin, args, undefined, 25_000, env, cwd);
}

// a run's ping lands after it exits: wait (up to 1 s) for the reply file
async function bend(args: string[], env: Record<string, string> = {},
  cwd?: string): Promise<lib.Exec> {
  const t0 = Date.now();
  const r = await run(path.join(HOME, "bin", "bend"), args,
    { BEND_HOME: HOME, BEND_ORIGIN: ORIGIN, ...env }, cwd);
  for (let i = 0; i < 20; i += 1) {
    try {
      if (fs.statSync(path.join(HOME, "rep")).mtimeMs >= t0) {
        break;
      }
    } catch {}
    await new Promise((wake) => setTimeout(wake, 50));
  }
  return r;
}

function check(what: string, ok: boolean): void {
  total += 1;
  if (!ok) {
    fails.push(what);
  }
}

function release(ver: string, url: string, sha256: string, notice = ""): void {
  fs.writeFileSync(path.join(DL, "latest.json"),
    JSON.stringify({ ver, url, sha256, notice }));
}

function current(): string {
  return fs.readlinkSync(path.join(HOME, "current"));
}

function logs(): Record<string, unknown>[] {
  return fs.readFileSync(LOG, "utf8").trim().split("\n")
    .map((l) => JSON.parse(l) as Record<string, unknown>);
}

async function hub_wait(): Promise<void> {
  for (let i = 0; i < 50; i += 1) {
    try {
      await fetch(HUB + "/");
      return;
    } catch {
      await new Promise((wake) => setTimeout(wake, 100));
    }
  }
  throw new Error("hub.ts did not come up on " + HUB);
}

let html = false;
let down = false;

const caddy = Bun.serve({
  port: PORT,
  fetch(req) {
    const at = new URL(req.url).pathname;
    if (html && at === "/ping") {
      return new Response("<html><body>maintenance</body></html>");
    }
    if (down && at === "/ping") {
      return new Response("bad gateway", { status: 502 });
    }
    if (at === "/install.sh") {
      return new Response(Bun.file(path.join(lib.SITE, "front", "install.sh")));
    }
    if (at.startsWith("/dl/")) {
      const file = path.join(DL, path.basename(at));
      return fs.existsSync(file) ? new Response(Bun.file(file))
        : new Response(null, { status: 404 });
    }
    return fetch(HUB + at, { method: req.method, headers: req.headers, body: req.body });
  },
});

// Main
// ====

const hub = child.spawn(process.execPath, [path.join(lib.SITE, "deploy", "hub.ts")],
  { stdio: "ignore", env: { ...process.env, HUB_PORT: String(PORT + 1),
    HUB_STORE: path.join(TMP, "store"), PING_LOG: LOG, DL_DIR: DL } });
try {
  await hub_wait();
  const rel = await run(process.execPath, [path.join(lib.SITE, "deploy", "release.ts"),
    "--dry"], { DL_DIR: DL, BEND_ORIGIN: ORIGIN, BEND_REPO: lib.ROOT });
  check("release.ts --dry: " + rel.err, rel.code === 0);
  const latest = JSON.parse(fs.readFileSync(path.join(DL, "latest.json"),
    "utf8")) as { ver: string; url: string; sha256: string };
  const old = path.join(TMP, "old", "bend");
  fs.mkdirSync(path.dirname(old));
  fs.writeFileSync(old, "#!/bin/sh\necho bend 1\n", { mode: 0o755 });
  // HOME is the temp dir too: install.sh writes the PATH line into its rc
  const ins = await run("sh", [path.join(lib.SITE, "front", "install.sh")],
    { HOME: TMP, SHELL: "/bin/zsh", BEND_HOME: HOME, BEND_ORIGIN: ORIGIN,
      PATH: path.dirname(old) + ":" + SAFE });
  check("install.sh: " + ins.err, ins.code === 0);
  check("the old bend on PATH is left alone and named",
    ins.out.includes("Another bend is at " + old + ".")
    && fs.readFileSync(old, "utf8").includes("bend 1"));
  check("the installer discloses the telemetry once", ins.out.split(SAID).length === 2);
  check("the install card names " + latest.ver, ins.out.includes(latest.ver));
  check("the shell rc got bin on PATH",
    fs.readFileSync(path.join(TMP, ".zshrc"), "utf8")
      .includes('export PATH="' + HOME + '/bin:$PATH"'));
  check("current -> app/" + latest.ver, current().startsWith("app/" + latest.ver + "/"));
  const guide = await bend(["guide"]);
  check("bend guide prints the guide", guide.code === 0 && guide.out.includes("# "));
  const help = await bend(["--help"]);
  check("bend --help prints the help", help.code === 0 && help.out.includes("usage:"));
  check("no disclosure on the second run", !help.err.includes(TELL));
  const line = logs().pop() ?? {};
  check("the log has cmd --help", line.cmd === "--help" && line.ver === latest.ver
    && typeof line.id === "string" && line.exit === 0 && typeof line.ms === "number");
  await bend([path.join(TMP, "secret.bend")]);
  check("a run with a file logs cmd run", (logs().pop() ?? {}).cmd === "run");
  const tgz = path.join(DL, latest.ver + ".tar.gz");
  fs.copyFileSync(tgz, path.join(DL, "v2.tar.gz"));
  release("v2", ORIGIN + "/dl/v2.tar.gz", latest.sha256, "hello from v2");
  const same = await bend(["--help"]);
  check("the run that pings the release runs the installed one", same.code === 0
    && !same.err.includes("hello from v2") && current().startsWith("app/" + latest.ver + "/"));
  const next = await bend(["--help"]);
  check("the notice prints", next.err.includes("hello from v2"));
  check("the launcher updated to v2", next.code === 0
    && next.err.includes("bend updated to v2") && current().startsWith("app/v2/"));
  release("v3", ORIGIN + "/dl/v2.tar.gz", latest.sha256);
  await bend(["--help"]);
  const n = logs().length;
  const mute = await bend(["--help"], { BEND_NO_TELEMETRY: "1" });
  check("BEND_NO_TELEMETRY=1 sends nothing and installs nothing", mute.code === 0
    && logs().length === n && current().startsWith("app/v2/"));
  const many = await Promise.all(Array.from({ length: 10 }, () => bend(["--help"])));
  const after = await bend(["--help"]);
  check("ten runs during an update all pass and leave one whole release",
    many.every((r) => r.code === 0 && r.out.includes("usage:"))
    && current().startsWith("app/v3/") && after.code === 0 && after.out.includes("usage:"));
  const was = current();
  fs.mkdirSync(path.join(TMP, "victim"));
  fs.writeFileSync(path.join(TMP, "victim", "keep"), "");
  release("../../victim", ORIGIN + "/dl/v2.tar.gz", latest.sha256);
  await bend(["--help"]);
  const evil = await bend(["--help"]);
  check("a ver of ../../victim deletes nothing and installs nothing", evil.code === 0
    && fs.existsSync(path.join(TMP, "victim", "keep")) && current() === was
    && !fs.existsSync(path.join(TMP, "victim", "bend2")));
  html = true;
  const page = await bend(["--help"]);
  html = false;
  check("an HTML answer to the ping leaves the release running", page.code === 0
    && page.out.includes("usage:") && current() === was);
  release("v4", ORIGIN + "/dl/v2.tar.gz", "0".repeat(64));
  await bend(["--help"]);
  const fake = await bend(["--help"]);
  check("a wrong sha256 installs nothing and is remembered", fake.code === 0
    && current() === was && fs.readFileSync(path.join(HOME, "bad"), "utf8") === "v4\n");
  const bare = path.join(TMP, "bare");
  fs.mkdirSync(path.join(bare, "guide"), { recursive: true });
  fs.writeFileSync(path.join(bare, "guide", "GUIDE.md"), "# nothing\n");
  child.execFileSync("tar", ["-czf", path.join(DL, "v5.tar.gz"), "-C", bare, "guide"]);
  release("v5", ORIGIN + "/dl/v5.tar.gz",
    crypto.hash("sha256", fs.readFileSync(path.join(DL, "v5.tar.gz"))));
  await bend(["--help"]);
  const hole = await bend(["--help"]);
  check("a tarball without bend2/main.ts installs nothing", hole.code === 0
    && hole.out.includes("usage:") && current() === was);
  release("v3", ORIGIN + "/dl/v2.tar.gz", latest.sha256, "one\ntwo \u001b[31mred");
  await bend(["--help"]);
  const wild = await bend(["--help"]);
  check("a notice with newlines and escapes leaves the release running",
    wild.code === 0 && wild.out.includes("usage:") && wild.err.includes("one"));
  const dead = await bend(["--help"], { BEND_ORIGIN: "http://127.0.0.1:1" });
  check("a dead origin runs the installed release", dead.code === 0
    && dead.out.includes("usage:"));
  const odd = path.join(TMP, "we ird's home");
  const ins2 = await run("sh", [path.join(lib.SITE, "front", "install.sh")],
    { BEND_HOME: odd, BEND_ORIGIN: ORIGIN, PATH: SAFE });
  check("a BEND_HOME with a space and a quote installs: " + ins2.err, ins2.code === 0
    && fs.readlinkSync(path.join(odd, "current")).startsWith("app/v3/"));
  fs.chmodSync(HOME, 0o555);
  const ro = await bend(["--help"]);
  fs.chmodSync(HOME, 0o755);
  check("a read-only BEND_HOME runs the installed release", ro.code === 0
    && ro.out.includes("usage:"));
  fs.rmSync(path.join(HOME, current()), { recursive: true });
  const back = await bend(["--help"]);
  check("a current left dangling is installed again", back.code === 0
    && back.out.includes("usage:") && back.err.includes("bend updated to v3")
    && fs.existsSync(path.join(HOME, "current", "bend2", "main.ts")));
  release("v4", ORIGIN + "/dl/v2.tar.gz", latest.sha256.slice(1));
  await bend(["--help"]);
  const short = await bend(["--help"]);
  release("v4", ORIGIN + "/dl/v2.tar.gz", "");
  await bend(["--help"]);
  const nosha = await bend(["--help"]);
  check("a sha256 that is not 64 hex digits installs nothing", short.code === 0
    && nosha.code === 0 && current().startsWith("app/v3/"));
  release("v3", ORIGIN + "/dl/v2.tar.gz", latest.sha256);
  const bs = path.join(TMP, "back\\slash");
  const ins3 = await run("sh", [path.join(lib.SITE, "front", "install.sh")],
    { BEND_HOME: bs, BEND_ORIGIN: ORIGIN, PATH: SAFE });
  check("a BEND_HOME with a backslash verifies and activates the release (Bun then"
    + " cannot run from such a path): " + ins3.err,
  fs.readlinkSync(path.join(bs, "current")).startsWith("app/v3/"));
  const proj = path.join(TMP, "proj");
  fs.mkdirSync(proj);
  fs.writeFileSync(path.join(proj, "bunfig.toml"), "preload = [\"./pre.ts\"]\n");
  fs.writeFileSync(path.join(proj, "pre.ts"),
    "if (process.env.N) { await new Promise(() => {}); }\n");
  release("v6", ORIGIN + "/dl/v2.tar.gz", latest.sha256);
  await bend(["--help"]);
  const pre = await bend(["--help"], {}, proj);
  check("a bunfig.toml preload in the cwd cannot hang the update", pre.code === 0
    && pre.err.includes("bend updated to v6") && current().startsWith("app/v6/"));
  fs.unlinkSync(path.join(HOME, "current"));
  fs.mkdirSync(path.join(HOME, "current"));
  release("v7", ORIGIN + "/dl/v2.tar.gz", latest.sha256);
  const real = await bend(["--help"]);
  check("a real directory at current is moved aside", real.code === 0
    && current().startsWith("app/v7/") && fs.existsSync(path.join(HOME, "current.old"))
    === false && fs.readdirSync(HOME).some((f) => f.startsWith("current.")));
  fs.writeFileSync(path.join(HOME, "app", "v8"), "");
  fs.writeFileSync(path.join(lib.ROOT, ".tgz"), "keep");
  release("v8", ORIGIN + "/dl/v2.tar.gz", latest.sha256);
  await bend(["--help"]);
  const full = await bend(["--help"]);
  const kept = fs.readFileSync(path.join(lib.ROOT, ".tgz"), "utf8");
  fs.unlinkSync(path.join(lib.ROOT, ".tgz"));
  check("a staging directory that cannot be made touches nothing", full.code === 0 && kept === "keep"
    && current().startsWith("app/v7/"));
  down = true;
  release("v9", ORIGIN + "/dl/v2.tar.gz", latest.sha256);
  await bend(["--help"]);
  const fall = await bend(["--help"]);
  down = false;
  check("a hub that is down still updates through /dl/latest.json", fall.code === 0
    && fall.err.includes("bend updated to v9") && current().startsWith("app/v9/"));
  const big = await fetch(ORIGIN + "/ping", { method: "POST", body: "x".repeat(2048) });
  fs.chmodSync(LOG, 0o444);
  const nolog = await fetch(ORIGIN + "/ping", { method: "POST", body: "{}" });
  const got = await nolog.json() as { ver?: string };
  fs.chmodSync(LOG, 0o644);
  check("a 2 KiB ping is refused and an unwritable log still answers",
    big.status === 413 && nolog.status === 200 && got.ver === "v9");
  const alt = path.join(TMP, "alt");
  fs.mkdirSync(path.join(alt, "bin"), { recursive: true });
  fs.writeFileSync(path.join(TMP, "target"), "#!/bin/sh\necho target\n");
  fs.symlinkSync(path.join(TMP, "target"), path.join(alt, "bin", "bend"));
  const ins4 = await run("sh", [path.join(lib.SITE, "front", "install.sh")],
    { BEND_HOME: alt, BEND_ORIGIN: ORIGIN, PATH: SAFE });
  check("a reinstall over a symlinked bin/bend leaves its target alone", ins4.code === 0
    && fs.readFileSync(path.join(TMP, "target"), "utf8").includes("echo target")
    && !fs.lstatSync(path.join(alt, "bin", "bend")).isSymbolicLink());
  const none = path.join(TMP, "none");
  fs.mkdirSync(path.join(none, "bin"), { recursive: true });
  fs.copyFileSync(path.join(HOME, "bin", "bend"), path.join(none, "bin", "bend"));
  const first = await run(path.join(none, "bin", "bend"), ["--help"],
    { BEND_HOME: none, BEND_ORIGIN: "http://127.0.0.1:1" });
  check("a first run with no release and no origin says so", first.code === 1
    && first.err.includes("bend: no release installed"));
  const npm = Bun.which("npm");
  if (npm === null) {
    console.log("SKIP the npm shim: no npm on this machine");
  } else {
    const nh = path.join(TMP, "npm");
    fs.mkdirSync(nh);
    const env = { HOME: nh, PATH: SAFE, BEND_ORIGIN: ORIGIN, BEND_NO_TELEMETRY: "1" };
    const nenv = { ...env, PATH: path.dirname(npm) + ":" + SAFE };
    const pack = await run(npm, ["pack", "--pack-destination", nh,
      path.join(lib.SITE, "front", "npm")], nenv);
    const ins5 = await run(npm, ["install", "-g", "--prefix", nh, "--no-audit", "--no-fund",
      path.join(nh, pack.out.trim())], nenv);
    check("npm install -g of the shim: " + ins5.err, pack.code === 0 && ins5.code === 0);
    const one = await run(path.join(nh, "bin", "bend"), ["--help"], env);
    const two = await run(path.join(nh, "bin", "bend"), ["--help"], env);
    check("the npm shim installs bend and prints the help", one.code === 0
      && one.out.includes("code bender") && one.out.includes("usage:")
      && fs.existsSync(path.join(nh, ".bend", "current", "bend2", "main.ts")));
    check("the second run of the npm shim does not reinstall", two.code === 0
      && !two.out.includes("code bender") && two.out.includes("usage:"));
  }
} catch (e) {
  check(String(e), false);
} finally {
  hub.kill();
  caddy.stop(true);
  fs.rmSync(TMP, { recursive: true, force: true });
}
if (!lib.GATE) {
  for (const f of fails) {
    console.log("FAIL " + f);
  }
}
lib.verdict(total - fails.length, total);
