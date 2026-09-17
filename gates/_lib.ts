// Shared by the gates: local and cluster exec (ssh through the bastion's
// mux), a slot of 48 minis (the live ones), a pool that hands jobs to free
// nodes, and the verdict line.

import * as child from "node:child_process";
import * as fs from "node:fs";
import * as path from "node:path";

// Types
// =====

export type Exec = { out: string; err: string; code: number };

export type Job = (node: number) => Promise<void>;

// Constants
// =========

export const GATE = process.argv.includes("--gate");

export const ROOT = path.join(import.meta.dirname, "..");

// the site repo (bendlang/bend-lang.com): the installer, the launcher, the
// hub and release.ts live there, beside this checkout or at $SITE_REPO
export const SITE = process.env.SITE_REPO ?? path.join(ROOT, "..", "bend-lang.com");

export const BUN = "/usr/local/bun/bin/bun";

const SLOTS = { dir: "/tmp/bend-cluster-slots", count: 4, size: 48, base: 2 };

const STALE = 20 * 60 * 1000;

const MUX = ["-o", "BatchMode=yes", "-o", "ConnectTimeout=8",
  "-o", "ControlMaster=auto", "-o", "ControlPath=/tmp/bend-cluster-mux",
  "-o", "ControlPersist=600"];

const SSH = ["-o", "BatchMode=yes", "-o", "ConnectTimeout=8",
  "-o", "ProxyCommand=ssh " + MUX.join(" ") + " -W %h:%p cluster"];

const DROP = new RegExp("Connection reset|closed by remote host"
  + "|Broken pipe|kex_exchange_identification|mux_client|timed out");

let held = "";

// Exec
// ====

export function exec(bin: string, args: string[], input?: Buffer | string,
  timeout = 600_000, env?: Record<string, string>, cwd = ROOT): Promise<Exec> {
  return new Promise((resolve) => {
    const kid = child.spawn(bin, args, { cwd, env: { ...process.env,
      ...env }, stdio: ["pipe", "pipe", "pipe"] });
    const outs: Buffer[] = [];
    const errs: Buffer[] = [];
    const bomb = setTimeout(() => kid.kill("SIGKILL"), timeout);
    kid.stdout.on("data", (d: Buffer) => outs.push(d));
    kid.stderr.on("data", (d: Buffer) => errs.push(d));
    kid.stdin.on("error", () => {});
    kid.on("error", (e) => {
      clearTimeout(bomb);
      resolve({ out: "", err: String(e), code: 255 });
    });
    kid.on("close", (code) => {
      clearTimeout(bomb);
      resolve({ out: Buffer.concat(outs).toString(),
        err: Buffer.concat(errs).toString(), code: code ?? 1 });
    });
    kid.stdin.end(input);
  });
}

export function node_name(node: number): string {
  return "cluster-" + node.toString(16).padStart(2, "0");
}

// A session the transport dropped (or that timed out in the banner
// exchange: the shared bastion path stalled, not the node) is retried
// twice; a node the bastion cannot reach (channel refused) fails at once.
export async function ssh(node: number, script: string,
  input?: Buffer | string, timeout?: number): Promise<Exec> {
  for (let hop = 0; ; hop += 1) {
    const got = await exec("ssh", [...SSH, node_name(node), script], input,
      timeout);
    if (hop >= 2 || got.code !== 255 || !DROP.test(got.err)) {
      return got;
    }
    await sleep(500 + Math.random() * 1500);
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((wake) => setTimeout(wake, ms));
}

// Node
// ====

// Locks a slot of 48 minis, after one session to the bastion opens the
// mux the rest share. A bastion that refuses that session (the agent lost
// id_rsa at a reboot, the host is down) fails the gate at once with its
// reason; without this every node's first session dies as "Connection
// closed by UNKNOWN" and the pool runs dry. A dead node is found by its
// first job (node_pool requeues the job and drops the node), not by a
// probe.
export async function node_lock(): Promise<number[]> {
  const nodes = slot_lock();
  const got = await exec("ssh", [...MUX, "cluster", "true"]);
  if (got.code !== 0) {
    throw new Error("the bastion refused the mux session (is id_rsa in the"
      + " agent? ssh-add ~/.ssh/id_rsa): "
      + (got.err.trim().split("\n").pop() ?? ""));
  }
  return nodes;
}

// Copies what a node needs to build a program: the compiler, Base and
// the effect kit (not bend.lean, docs or pack).
export function bend2_copy(to: string): void {
  fs.cpSync(path.join(ROOT, "bend2"), to, { recursive: true,
    filter: (p) => fs.statSync(p).isDirectory() ? !/\/(docs|pack)$/.test(p)
      : /\.(ts|bend|c|js)$/.test(p) });
}

function slot_lock(): number[] {
  fs.mkdirSync(SLOTS.dir, { recursive: true });
  for (let slot = 0; slot < SLOTS.count; slot += 1) {
    const dir = path.join(SLOTS.dir, "slot" + String(slot));
    const file = path.join(dir, "lock.json");
    try {
      const lock = JSON.parse(fs.readFileSync(file, "utf8")) as
        { pid: number; time: number };
      let dead = Date.now() - lock.time > STALE;
      try {
        process.kill(lock.pid, 0);
      } catch {
        dead = true;
      }
      if (dead) {
        fs.rmSync(dir, { recursive: true, force: true });
      }
    } catch {}
    try {
      fs.mkdirSync(dir);
      fs.writeFileSync(file, JSON.stringify({ pid: process.pid,
        time: Date.now() }));
      held = dir;
      process.on("exit", node_free);
      const first = SLOTS.base + SLOTS.size * slot;
      return Array.from({ length: SLOTS.size }, (_, i) => first + i);
    } catch {}
  }
  process.stderr.write("cluster out of capacity: every slot is busy\n");
  process.exit(2);
}

export function node_free(): void {
  if (held !== "") {
    fs.rmSync(held, { recursive: true, force: true });
    held = "";
  }
}

// A job that throws "node" (its cause: the session's last error line) goes
// back to the queue and its node leaves the pool; a node with nothing to do
// waits while others still run, since their jobs may come back.
export async function node_pool(nodes: number[], jobs: Job[]): Promise<void> {
  const queue = [...jobs];
  let busy = 0;
  let why = "";
  await Promise.all(nodes.map(async (node) => {
    for (;;) {
      const job = queue.shift();
      if (job === undefined) {
        if (busy === 0) {
          return;
        }
        await sleep(200);
        continue;
      }
      busy += 1;
      try {
        await job(node);
        busy -= 1;
      } catch (e) {
        busy -= 1;
        queue.unshift(job);
        if (!(e instanceof Error && e.message === "node")) {
          throw e;
        }
        why = String(e.cause ?? "").trim().split("\n").pop() ?? "";
        return;
      }
    }
  }));
  if (queue.length > 0) {
    throw new Error("the cluster ran out of live nodes: " + why);
  }
}

// Verdict
// =======

export function verdict(pass: number, total: number): never {
  console.log("PASS: " + String(pass) + " / " + String(total));
  process.exit(pass === total ? 0 : 1);
}
