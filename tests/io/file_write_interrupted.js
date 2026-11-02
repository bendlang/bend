// Interrupt before and after a short write, as in the native lane.
let interrupted_fd = -1;
let interrupted_stage = 0;
const interrupted_fs = require("fs");
const interrupted_write = interrupted_fs.writeSync;
interrupted_fs.writeSync = function(fd, buffer, offset, length, position) {
  if (fd === interrupted_fd && length > 0) {
    const stage = interrupted_stage++;
    if (stage === 0 || stage === 2) {
      const error = new Error("interrupted");
      error.code = "EINTR";
      error.errno = -4;
      throw error;
    }
    if (stage === 1) length = Math.min(length, 2);
  }
  return interrupted_write.call(this, fd, buffer, offset, length, position);
};
function interrupted_arm(file) {
  interrupted_fd = file;
  interrupted_stage = 0;
  return file;
}
function interrupted_check(file) {
  if (interrupted_stage !== 4) throw new Error("missing interruption stage");
  interrupted_fd = -1;
  return file;
}
io_eff(CID(Interrupted.arm), interrupted_arm);
io_eff(CID(Interrupted.check), interrupted_check);
