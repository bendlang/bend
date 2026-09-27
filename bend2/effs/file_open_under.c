// File
// ====

#include <sys/stat.h>

// path, opened for reading one component at a time below root: every
// step is an openat with O_NOFOLLOW, so a symbolic link anywhere under
// root, to a file or to a directory, fails (ELOOP) rather than being
// followed out of it. A component that is empty, "." or ".." fails with
// EACCES; an intermediate that is not a directory fails with ENOTDIR
// before it is opened (O_DIRECTORY; a link there is re-read and still
// answers ELOOP); an end that is not a regular file fails too (EISDIR
// for a directory). O_NONBLOCK keeps a FIFO from parking the helper
// thread. Every component is opened, so each needs read permission; a
// search-only intermediate would have answered the one-shot resolver.
// root itself is opened as given: it is the program's, not a peer's.
static int file_open_under_walk(const char* root, char* at) {
  int dir = open(root, O_RDONLY | O_DIRECTORY | O_CLOEXEC);
  while (dir >= 0) {
    char* cut  = strchr(at, '/');
    int   last = cut == NULL;
    if (!last) {
      *cut = 0;
    }
    if (*at == 0 || strcmp(at, ".") == 0 || strcmp(at, "..") == 0) {
      close(dir);
      errno = EACCES;
      return -1;
    }
    int fd = openat(dir, at, O_RDONLY | O_NOFOLLOW | O_CLOEXEC | O_NOCTTY
      | (last ? O_NONBLOCK : O_DIRECTORY));
    int no = errno;
    if (!last && fd < 0 && no == ENOTDIR) {
      struct stat lst;
      if (fstatat(dir, at, &lst, AT_SYMLINK_NOFOLLOW) == 0
        && S_ISLNK(lst.st_mode)) {
        no = ELOOP;
      }
    }
    close(dir);
    errno = no;
    if (fd >= 0 && last) {
      return fd;
    }
    dir = fd;
    if (!last) {
      at = cut + 1;
    }
  }
  return -1;
}

// the end, opened, must be a regular file
static int file_open_under_end(int fd) {
  struct stat st;
  if (fd < 0) {
    return -1;
  }
  if (fstat(fd, &st) != 0) {
    int no = errno;
    close(fd);
    errno = no;
    return -1;
  }
  if (!S_ISREG(st.st_mode)) {
    close(fd);
    errno = S_ISDIR(st.st_mode) ? EISDIR : EACCES;
    return -1;
  }
  return fd;
}

static void file_open_under_call(IoWork* w) {
  w->made = (intptr_t)io_sys_end(w,
    file_open_under_end(file_open_under_walk(w->text, w->data)));
}

static Term file_open_under_pack(Env e, IoWork* w) {
  free(w->data);
  free(w->text);
  return w->code != 0 ? io_fail(e, w->code, NULL)
    : io_done(e, io_hand(w->made));
}

Term file_open_under_run(Env e, Term* f, IoWork* w) {
  uint64_t rn = 0;
  w->text = io_cstr(e, f[0], &rn);
  w->data = io_cstr(e, f[1], &w->size);
  if (io_nul(w->text, rn) || io_nul(w->data, w->size)) {
    w->code = EILSEQ;
    return file_open_under_pack(e, w);
  }
  return io_work(w, file_open_under_call, file_open_under_pack);
}

static void __attribute__((constructor)) file_open_under_use(void) {
  io_eff(CID(File.open_under), file_open_under_run, 0);
}
