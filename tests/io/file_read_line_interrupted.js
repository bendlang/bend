// The JS lane uses the host's ordinary file reads.
function interrupted_keep(file) {
  return file;
}

io_eff(CID(Interrupted.arm), interrupted_keep);
io_eff(CID(Interrupted.check), interrupted_keep);
