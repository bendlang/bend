// safe.ts's node side: runs `bend <f> --verdict` on each file named on
// stdin, PAR at a time, each capped at CAP s, and prints one JSON array
// of Got. On a mismatch (bend2 checks, the kernel does not), diagnostic
// says why: the defs `-o` leaves out of scope, or else the kernel's error
// on the translation, with the failing call if live. ms times the verdict
// only; a failed diagnostic never changes it, and an infrastructure error
// is never a proof rejection.
import * as child from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

export type Got = {
  f: string; code: number | null; ms: number; out: string; timeout: boolean;
  signal?: string; error?: string;
  diagnostic?: string; diagnostic_error?: string; diagnostic_ms?: number;
};

// a report row's reason: one line, at most 300 chars
export function one_line(s: string): string {
  return s.replace(/\s+/g, " ").slice(0, 300);
}

// Classification consumes explicit process outcomes, never elapsed diagnostics.
export function judge(g: Got): [string, string] {
  const out = g.out.trim();
  if (g.timeout) {
    return ["t", g.error ? "timeout; " + one_line(g.error) : "timeout"];
  }
  if (g.error || g.code === null || g.code < 0) {
    const why = one_line(g.error ?? out);
    return ["e", "infrastructure: " + why];
  }
  if (g.code === 0 && out === "ALL PROOFS CHECK") {
    return [" ", "agree"];
  }
  if (/^Error: \d+ defs? rel(y|ies) on unsafe or foreign code/m.test(out)) {
    return ["u", "unsafe: " + [...out.matchAll(
      /^defs that depend on (?:@unsafe|foreign effects): (.+)$/gm)]
      .flatMap((m) => m[1].split(", ")).slice(0, 3).join(" ")];
  }
  if (!out.includes("Sorry - ")) {
    return [" ", "bend2 rejects: " + out.split("\n").slice(1, 3).join(" ").slice(0, 80)];
  }
  const tt = g.diagnostic ?? out;
  if (tt.startsWith("out of scope")) {
    return ["-", "out of scope: " + [...tt.matchAll(/^- \S+: (.*)$/gm)].map((m) => m[1]).slice(0, 2).join(" | ").slice(0, 160)];
  }
  // the kernel's first line is SOME PROOFS FAIL; why starts at In <def>:
  return ["!", tt.split("\n").slice(1, 3).join(" | ").slice(0, 300)];
}

// a check's deadline kills its whole process group: bend2 runs the
// kernel as its child, and a SIGKILL to bend2 alone left the kernel
// running, orphaned, while the next check started. Each check leads its
// own group (detached), which the kernel joins; one kill(-pid) reaches
// all of it at once, and no pid is reused while its group has a member.
// live maps a group to the check that leads it, from its spawn to its
// close, so a group a check left is never signalled under its pid. If
// the group kill fails but the group exists (ESRCH says it is empty),
// bend2 alone is killed, as before
const live = new Map<number, child.ChildProcess>();

function kill_group(kid: child.ChildProcess): boolean {
  if (kid.pid === undefined || live.get(kid.pid) !== kid) {
    return false;
  }
  try {
    process.kill(-kid.pid, "SIGKILL");
    return true;
  } catch (e) {
    return (e as NodeJS.ErrnoException).code !== "ESRCH" && kid.kill("SIGKILL");
  }
}

async function run(bin: string, args: string[], cap: number): Promise<Omit<Got, "f">> {
  const g: Omit<Got, "f"> = { code: null, ms: 0, out: "", timeout: false };
  const t0 = Date.now();
  await new Promise<void>((done) => {
    const kid = child.spawn(bin, args,
      { env: { ...process.env, BEND_NO_TELEMETRY: "1" }, detached: true });
    if (kid.pid !== undefined) {
      live.set(kid.pid, kid);
    }
    kid.stdout.on("data", (d) => { g.out += d; });
    kid.stderr.on("data", (d) => { g.out += d; });
    kid.on("error", (e) => { g.error = e.message; });
    const bomb = setTimeout(() => { g.timeout = kill_group(kid); }, cap);
    kid.on("close", (code, signal) => {
      clearTimeout(bomb);
      if (kid.pid !== undefined && live.get(kid.pid) === kid) {
        live.delete(kid.pid);
      }
      g.code = code;
      g.ms = Date.now() - t0;
      if (signal) {
        g.signal = signal;
        if (!g.timeout) {
          g.error = "child terminated by " + signal;
        }
      }
      done();
    });
  });
  return g;
}

async function one(f: string, cap: number): Promise<Got> {
  const g: Got = { f, ...await run(process.execPath, ["bend2/main.ts", f, "--verdict"], cap) };
  if (g.out.includes("Error: BendTT infrastructure:")) {
    g.error = g.out.trim();
  }
  if (!g.timeout && !g.error && g.out.includes("Sorry - ")) {
    const t1 = Date.now();
    let dir: string | undefined;
    try {
      dir = fs.mkdtempSync(path.join(os.tmpdir(), "bend-safe-"));
      const tt = path.join(dir, "diagnostic.bendtt");
      const emitted = await run(process.execPath, ["bend2/main.ts", f, "-o", tt], 20000);
      if (emitted.error || emitted.timeout || emitted.code !== 0) {
        throw new Error("elaboration diagnostic: " + (emitted.error ?? (emitted.out.trim()
          || "exit " + emitted.code + ", signal " + emitted.signal)));
      }
      if (emitted.out.trim() !== "") {
        g.diagnostic = "out of scope\n" + emitted.out.trim();
      } else {
        const kernel = await run(process.env.BENDTT ?? "", [tt], 20000);
        if (kernel.error || kernel.timeout || kernel.code === null
          || (kernel.code !== 0 && !kernel.out.startsWith("SOME PROOFS FAIL"))) {
          throw new Error("kernel diagnostic: " + (kernel.error ?? (kernel.out.trim()
            || "exit " + kernel.code + ", signal " + kernel.signal)));
        }
        g.diagnostic = kernel.out.trim();
        const m = /^In (\S+):\naffine live code/m.exec(kernel.out);
        if (m !== null) {
          const detail = await run(process.execPath, ["gates/safe_diag.ts", tt, m[1]], 20000);
          if (detail.error || detail.timeout || detail.code !== 0) {
            throw new Error("descent diagnostic: " + (detail.error ?? (detail.out.trim()
              || "exit " + detail.code + ", signal " + detail.signal)));
          }
          g.diagnostic += "\n" + detail.out.trim().slice(0, 300);
        }
      }
    } catch (e) {
      g.diagnostic_error = String(e);
    } finally {
      if (dir !== undefined) {
        fs.rmSync(dir, { recursive: true, force: true });
      }
      g.diagnostic_ms = Date.now() - t1;
    }
  }
  return g;
}

if (import.meta.main) {
  // a check's group is not the runner's, so a ^C or a kill that ends the
  // runner ends every live check first
  for (const sig of ["SIGINT", "SIGTERM", "SIGHUP", "SIGQUIT"] as const) {
    process.once(sig, () => {
      for (const kid of live.values()) {
        kill_group(kid);
      }
      process.kill(process.pid, sig);
    });
  }
  const files = fs.readFileSync(0, "utf8").split("\n").filter((l) => l !== "");
  const cap = Number(process.env.CAP ?? 30) * 1000;
  const res: Got[] = [];
  let next = 0;
  await Promise.all(Array.from({ length: Number(process.env.PAR ?? 8) }, async () => {
    while (next < files.length) {
      res.push(await one(files[next++], cap));
    }
  }));
  process.stdout.write(JSON.stringify(res));
}
