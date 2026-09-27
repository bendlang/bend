// File
// ====

// File.sendfile(sock, file, off, len): the file's bytes from off, len of
// them, onto the socket with the kernel's sendfile(2), so no byte passes
// through the program; the file's own position does not move, the offset
// travels by value. A full socket (non-blocking, so EAGAIN) parks the
// computation until it is writable and the loop resumes here: the socket
// rides w->word (io_wait_on rewrites word when it parks, to the same
// value) and the file rides w->hand. Done once all len are out; a file
// that ends first fails with ENODATA, and a file the kernel will not
// send (EINVAL, ENOSYS, EOPNOTSUPP) fails with that errno.
#include <sys/types.h>
#include <sys/uio.h>
#if defined(__linux__)
#include <sys/sendfile.h>
#endif

// one move: bytes moved (> 0), 0 at the end of the file, -1 with errno
static ssize_t file_sendfile_at(int sock, int file, u64 off, u64 want) {
  want = want < (1u << 30) ? want : (1u << 30);
#if defined(__linux__)
  off_t o = (off_t)off;
  return sendfile(sock, file, &o, (size_t)want);
#elif defined(__APPLE__)
  off_t len = (off_t)want;
  int   r   = sendfile(file, sock, (off_t)off, &len, NULL, 0);
  if (r < 0 && len > 0) {
    return (ssize_t)len;
  }
  return r < 0 ? -1 : (ssize_t)len;
#else
  (void)sock;
  (void)file;
  (void)off;
  errno = ENOSYS;
  return -1;
#endif
}

static Term file_sendfile_more(Env e, IoWork* w) {
  int sock = (int)w->word;
  int file = (int)w->hand;
  while (w->code == 0 && (u64)w->made < w->size) {
    ssize_t n = file_sendfile_at(sock, file, (u64)w->made,
      w->size - (u64)w->made);
    if (n < 0 && errno == EINTR) {
      continue;
    }
    if (n < 0 && errno == EAGAIN) {
      return io_wait_on(w, sock, POLLOUT, 0, file_sendfile_more);
    }
    if (n == 0) {
      w->code = ENODATA;
      break;
    }
    w->made += (intptr_t)io_sys_end(w, n);
  }
  Term r = w->code != 0 ? io_fail(e, w->code, NULL)
    : io_done(e, term_pak(CID(Unit), 0));
  return io_tup(e, io_hand(w->word), io_tup(e, io_hand(w->hand), r));
}

Term file_sendfile_run(Env e, Term* f, IoWork* w) {
  w->word = (u32)io_hand_v(f[0]);
  w->hand = (intptr_t)io_hand_v(f[1]);
  w->made = (intptr_t)(u64)(u32)f[2];
  w->size = (u64)(u32)f[2] + (u64)(u32)f[3];
  w->code = 0;
  return file_sendfile_more(e, w);
}

static void __attribute__((constructor)) file_sendfile_use(void) {
  io_eff(CID(File.sendfile), file_sendfile_run, 0);
}
