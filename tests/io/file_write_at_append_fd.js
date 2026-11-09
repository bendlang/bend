function fd_append_run(path) {
  return require("fs").openSync(str_out(path), "a");
}

io_eff(CID(Fd.append), fd_append_run);
