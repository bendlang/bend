// File
// ====

#include <sys/stat.h>

// read(2) answers what is there, not what was asked: a pipe, a terminal
// and a short read all stop before max. Fill the buffer or reach EOF, so
// a caller that asked for n bytes gets n unless the file ends first; a
// line reads at most step bytes at a time and stops after its '\n',
// seeking back over what it read past it, so nothing past the line leaves
// the file. An error after some bytes answers them (a pipe has already
// given them up); at reads at w->made and leaves the position.
static void file_read_fill(IoWork* w, int at, u64 step) {
  int   fd  = (int)w->hand;
  u64   got = 0;
  char* nl  = NULL;
  w->code = 0;
  do {
    u64     want = step && step < w->word - got ? step : w->word - got;
    ssize_t n;
    do {
      n = at ? pread(fd, w->data + got, want, (off_t)(w->made + got))
             : read(fd, w->data + got, want);
    } while (n < 0 && errno == EINTR);
    if (n <= 0) {
      w->size = got > 0 ? got : io_sys_end(w, n);
      return;
    }
    nl = step ? memchr(w->data + got, '\n', (u64)n) : NULL;
    if (nl != NULL && nl + 1 < w->data + got + n
      && lseek(fd, nl + 1 - (w->data + got + n), SEEK_CUR) < 0) {
      w->code = (u32)errno;
    }
    got = nl != NULL ? (u64)(nl + 1 - w->data) : got + (u64)n;
  } while (got < w->word && nl == NULL);
  w->size = got;
}

static void file_read_call(IoWork* w) {
  file_read_fill(w, 0, 0);
}

static Term file_read_start(Term file, u64 max, IoWork* w,
  IoCall call, IoPack pack) {
  w->hand = (intptr_t)io_hand_v(file);
  w->word = max < INT32_MAX ? max : INT32_MAX;
  w->data = io_mem(malloc(w->word + 1));
  return io_work(w, call, pack);
}

#if defined(CID(File.read)) || defined(CID(File.read_line))

static Term file_read_pack(Env e, IoWork* w) {
  Term r = io_res(e, w, io_str(e, w->data, w->size));
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

#endif

#ifdef CID(File.read)

Term file_read_run(Env e, Term* f, IoWork* w) {
  return file_read_start(f[0], f[1], w, file_read_call, file_read_pack);
}

static void __attribute__((constructor)) file_read_use(void) {
  io_eff(CID(File.read), file_read_run);
}

#endif

#ifdef CID(File.read_line)

// Only a regular file with a size can seek back, so a pipe, a terminal or
// a /proc file reads a byte at a time; the rest read ahead LINE_STEP bytes.
#define LINE_STEP 256

static void file_read_line_call(IoWork* w) {
  struct stat st;
  int regular = fstat((int)w->hand, &st) == 0 && S_ISREG(st.st_mode)
    && st.st_size > 0;
  file_read_fill(w, 0, regular ? LINE_STEP : 1);
}

Term file_read_line_run(Env e, Term* f, IoWork* w) {
  return file_read_start(f[0], f[1], w, file_read_line_call, file_read_pack);
}

static void __attribute__((constructor)) file_read_line_use(void) {
  io_eff(CID(File.read_line), file_read_line_run);
}

#endif

#if defined(CID(File.read_bytes)) || defined(CID(File.read_at))

static Term file_read_bytes_pack(Env e, IoWork* w) {
  Term r = io_res(e, w, io_list(e, w->data, w->size));
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

#endif

#ifdef CID(File.read_bytes)

Term file_read_bytes_run(Env e, Term* f, IoWork* w) {
  return file_read_start(f[0], f[1], w, file_read_call, file_read_bytes_pack);
}

static void __attribute__((constructor)) file_read_bytes_use(void) {
  io_eff(CID(File.read_bytes), file_read_bytes_run);
}

#endif

#ifdef CID(File.read_at)

// The bytes at an offset, as file_read_bytes gives them; the position of
// the file does not move.
static void file_read_at_call(IoWork* w) {
  file_read_fill(w, 1, 0);
}

Term file_read_at_run(Env e, Term* f, IoWork* w) {
  w->made = (intptr_t)f[1];
  return file_read_start(f[0], f[2], w, file_read_at_call, file_read_bytes_pack);
}

static void __attribute__((constructor)) file_read_at_use(void) {
  io_eff(CID(File.read_at), file_read_at_run);
}

#endif
