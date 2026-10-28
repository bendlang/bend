function fd_append_run() {
  return require("fs").openSync("/tmp/bend_io_file_write_at_append_fd", "a");
}

io_eff(CID(Fd.append), fd_append_run);
