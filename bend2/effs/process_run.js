// Process
// =======

function process_run(program, args, input, maxOutput, timeoutMs) {
  const argv = [program];
  for (let xs = args; xs.$ === "Con"; xs = xs.tail) {
    argv.push(xs.head);
  }
  if (maxOutput === 0 || timeoutMs === 0
    || argv.some((arg) => arg.includes("\0"))) {
    return io_fail(22);
  }
  let got;
  try {
    got = Bun.spawnSync({ cmd: argv, stdin: Buffer.from(input),
      stdout: "pipe", stderr: "pipe", timeout: timeoutMs,
      maxBuffer: maxOutput + 1 });
  } catch (e) {
    return io_fail(typeof e.errno === "number" ? Math.abs(e.errno) : 5);
  }
  const out = Buffer.from(got.stdout ?? []);
  const err = Buffer.from(got.stderr ?? []);
  if (got.exitedDueToMaxBuffer || out.length + err.length > maxOutput) {
    return io_fail(27);
  }
  if (got.exitedDueToTimeout) {
    return io_fail(process.platform === "darwin" ? 60 : 110);
  }
  const sig = got.signalCode === null ? 0
    : require("node:os").constants.signals[got.signalCode];
  const code = got.exitCode ?? (128 + (sig ?? 0));
  return io_done(io_tup(code, out.toString("utf8"), err.toString("utf8")));
}
