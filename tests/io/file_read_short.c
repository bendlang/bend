#include <fcntl.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>

// A File on the read end of a FIFO whose writer sends n bytes one at a
// time. A single read(2) answers the first byte; a read that fills its
// buffer answers all n.
static void short_file_call(IoWork* w) {
  char path[64];
  snprintf(path, sizeof path, "/tmp/bend_read_short_%d", (int)getpid());
  unlink(path);
  int rd = mkfifo(path, 0600) < 0 ? -1 : open(path, O_RDONLY | O_NONBLOCK);
  int wr = rd < 0 ? -1 : open(path, O_WRONLY | O_NONBLOCK);
  unlink(path);
  if (wr < 0) {
    perror("file_read_short: fifo");
    _exit(1);
  }
  // The writer is a grandchild, so the child exits at once and is
  // reaped here; no zombie stays behind the runtime.
  pid_t pid = fork();
  if (pid == 0) {
    if (fork() != 0) {
      _exit(0);
    }
    close(rd);
    for (u32 i = 0; i < w->word; i += 1) {
      write(wr, "x", 1);
      usleep(1000);
    }
    close(wr);
    _exit(0);
  }
  waitpid(pid, NULL, 0);
  close(wr);
  int flags = fcntl(rd, F_GETFL);
  fcntl(rd, F_SETFL, flags & ~O_NONBLOCK);
  w->hand = rd;
}

static Term short_file_pack(Env e, IoWork* w) {
  return io_hand(w->hand);
}

Term short_file_run(Env e, Term* f, IoWork* w) {
  w->word = (u32)f[0];
  return io_work(w, short_file_call, short_file_pack);
}

static void __attribute__((constructor)) short_file_use(void) {
  io_eff(CID(short.file), short_file_run);
}
