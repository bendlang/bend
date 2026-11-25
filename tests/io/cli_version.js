function cli_version() {
  const { spawnSync } = require("node:child_process");
  const path = require("node:path");
  const bun = typeof Bun !== "undefined";
  const command = bun ? process.execPath : "bun";
  const cli = bun && Bun.main.startsWith("/$bunfs/") ? [] : [path.resolve("bend2/main.ts")];
  const run = (arg) => spawnSync(command, [...cli, arg], {
    encoding: "utf8", env: { ...process.env, BEND_NO_TELEMETRY: "1" },
  });
  const commandForm = run("version");
  const flagForm = run("--version");
  return commandForm.status === 0 && flagForm.status === 0
    && /^bend \d+\.\d+\.\d+/.test(flagForm.stdout)
    && flagForm.stdout === commandForm.stdout && flagForm.stderr === "" ? 0 : 1;
}

io_eff(CID(Cli.version), cli_version);
