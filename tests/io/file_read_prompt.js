let prompt_flushed = false;

function prompt_input() {
  const fs = require("node:fs");
  const path = require("node:path");
  const dir = fs.mkdtempSync(path.join(require("node:os").tmpdir(), "bend-read-prompt-"));
  let fd;
  try {
    const file = path.join(dir, "input");
    fs.writeFileSync(file, "hello\n");
    fd = fs.openSync(file, "r");
  } finally {
    fs.rmSync(dir, { recursive: true, force: true });
  }
  const write = fs.writeSync;
  const read = fs.readvSync;
  let output = "";
  fs.writeSync = function (fd, data, ...args) {
    const n = write(fd, data, ...args);
    const at = typeof args[0] === "number" ? args[0] : args[0]?.offset ?? 0;
    if (fd === 1) output += Buffer.from(data).subarray(at, at + n).toString();
    return n;
  };
  fs.readvSync = function (...args) {
    fs.writeSync = write;
    fs.readvSync = read;
    prompt_flushed = output === "prompt> ";
    return read(...args);
  };
  return fd;
}

function prompt_status() {
  return prompt_flushed ? 0 : 1;
}

io_eff(CID(Host.prompt_input), prompt_input);
io_eff(CID(Host.prompt_flushed), prompt_status);
