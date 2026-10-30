let positioned_restore;
let positioned_stage;

function positioned_arm(file, mode) {
  const fs = require("fs");
  const real = fs.writeSync;
  let next = 17;
  positioned_stage = 0;
  fs.writeSync = (fd, b, at, size, offset) => {
    if (fd !== file || size === 0) {
      return real.call(fs, fd, b, at, size, offset);
    }
    if (offset !== next) {
      throw new Error("a positioned retry used the wrong offset");
    }
    const stage = positioned_stage++;
    if (mode === 1 && stage === 1) {
      return 0;
    }
    if (mode === 2 && stage === 1) {
      throw Object.assign(new Error("controlled EACCES"), { errno: -13 });
    }
    if (stage === 0 && size > 2) {
      size = 2;
    }
    const n = real.call(fs, fd, b, at, size, offset);
    next += n;
    return n;
  };
  positioned_restore = () => { fs.writeSync = real; };
  return file;
}

function positioned_check(file) {
  positioned_restore();
  if (positioned_stage !== 2) {
    throw new Error("the positioned write did not run every control stage");
  }
  return file;
}

io_eff(CID(Control.arm), positioned_arm);
io_eff(CID(Control.check), positioned_check);
