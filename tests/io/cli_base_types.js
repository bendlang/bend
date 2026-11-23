function cli_base_types() {
  const child = require("node:child_process");
  const path = require("node:path");
  const bun = typeof Bun !== "undefined";
  const command = bun ? process.execPath : "bun";
  const cli = bun && Bun.main.startsWith("/$bunfs/") ? [] : [path.resolve("bend2/main.ts")];
  const out = child.spawnSync(command, [...cli, "base", "--types"], {
    encoding: "utf8", env: { ...process.env, BEND_NO_TELEMETRY: "1" },
  });
  if (out.status !== 0) return 1;
  if (!["IO", "Set", "Word", "Pair"].every((name) => out.stdout.includes("\ndef " + name + "("))) return 2;
  if (!out.stdout.includes("\ntype List<") || !out.stdout.includes("\nlaw File:")) return 3;
  return /^(?:def|law) (?:IO\.print|Set\.has|Word\.zero|Nat\.add)[:(]/m.test(out.stdout) ? 4 : 0;
}

io_eff(CID(Cli.base_types), cli_base_types);
