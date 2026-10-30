// File
// ====

function file_close(file) {
  const fs = require("fs");
  try {
    fs.closeSync(file);
  } catch (e) {
  }
  io_file_append.delete(file);
  return { $: CID(Unit) };
}

io_eff(CID(File.close), file_close);
