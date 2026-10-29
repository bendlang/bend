#include <sys/stat.h>

// The peer: echo the first line to the real stdout, write "hi" into the
// FIFO ($1) and remove it, then copy the rest through. A run that dies
// first must not leave it holding stdout: no line, it exits; a FIFO still
// unread after 10 s, a watchdog removes it and kills the peer.
#define PEER_SH "IFS= read -r l || { rm -f \"$1\"; exit 1; };" \
  " printf '%s\\n' \"$l\"; (sleep 10; [ -p \"$1\" ] && rm -f \"$1\"" \
  " && kill $$) >/dev/null 2>&1 & printf hi > \"$1\"; rm -f \"$1\"; exec cat"

static int peer_out = -1;

// Moves fd 1 onto a pipe the peer reads, and answers the FIFO's path.
Term peer_arm_run(Env e, Term* f, IoWork* w) {
  char path[64];
  int  p[2];
  snprintf(path, sizeof path, "/tmp/bend_peer_%d", (int)getpid());
  unlink(path);
  pid_t child = -1;
  if (mkfifo(path, 0600) != 0 || pipe(p) != 0 || (child = fork()) < 0) {
    err_fail("peer_arm: the FIFO, pipe or peer failed");
  }
  if (child == 0) {
    dup2(p[0], 0);
    close(p[0]);
    close(p[1]);
    execl("/bin/sh", "sh", "-c", PEER_SH, "sh", path, (char*)NULL);
    _exit(127);
  }
  peer_out = dup(1);
  dup2(p[1], 1);
  close(p[0]);
  close(p[1]);
  return io_str(e, path, strlen(path));
}

// Puts fd 1 back; the peer's cat sees the pipe close and exits.
Term peer_done_run(Env e, Term* f, IoWork* w) {
  dup2(peer_out, 1);
  close(peer_out);
  return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) peer_use(void) {
  io_eff(CID(peer_arm), peer_arm_run);
  io_eff(CID(peer_done), peer_done_run);
}
