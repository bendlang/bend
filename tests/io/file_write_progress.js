const progress_fs = require("fs");
const progress_os = require("os");
const progress_path = require("path");
let progress_fd = -1;
let progress_original;
let progress_dir;
let progress_name;
let progress_owned = -1;
let progress_zero;

function progress_open() {
  progress_dir = progress_fs.mkdtempSync(
    progress_path.join(progress_os.tmpdir(), "bend-write-progress-"));
  progress_name = progress_path.join(progress_dir, "data");
  progress_fd = progress_fs.openSync(progress_name, "w+");
  progress_owned = progress_fd;
  progress_zero = true;
  progress_original = progress_fs.writeSync;
  let calls = 0;
  const forever = process.env.BEND_TEST_WRITE_ZERO_FOREVER !== undefined;
  progress_fs.writeSync = function(
    fd, buffer, offset = 0, length = buffer.length - offset, position = null
  ) {
    if (fd === progress_fd && length > 0) {
      if (progress_zero && calls === 1) {
        calls = 2;
        return 0;
      }
      if (progress_zero && forever && calls >= 2) {
        return 0;
      }
      calls += 1;
      length = Math.min(length, 7);
    }
    return progress_original.call(progress_fs, fd, buffer, offset, length, position);
  };
  return io_done(progress_fd);
}

function progress_resume() {
  progress_zero = false;
  return { $: CID(Unit) };
}

function progress_cleanup() {
  if (progress_original !== undefined) {
    progress_fs.writeSync = progress_original;
  }
  if (progress_owned >= 0) {
    progress_fs.closeSync(progress_owned);
    progress_owned = -1;
  }
  if (progress_name !== undefined) {
    progress_fs.unlinkSync(progress_name);
    progress_name = undefined;
  }
  if (progress_dir !== undefined) {
    progress_fs.rmdirSync(progress_dir);
    progress_dir = undefined;
  }
}

function progress_release() {
  progress_owned = -1;
  progress_cleanup();
  return { $: CID(Unit) };
}

io_eff(CID(Progress.open), progress_open);
io_eff(CID(Progress.resume), progress_resume);
io_eff(CID(Progress.release), progress_release);
process.once("exit", progress_cleanup);
