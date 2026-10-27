// bend-ids 1
// CID :Interrupted.arm BEND_CID_Interrupted_arm
// CID :Interrupted.check BEND_CID_Interrupted_check
// bend-ids end
// The JS lane uses the host's ordinary file writes.
function interrupted_keep(file) {
  return file;
}

io_eff(BEND_CID_Interrupted_arm, interrupted_keep);
io_eff(BEND_CID_Interrupted_check, interrupted_keep);
