// File
// ====

#ifdef CID(File.read_line)

// A handle File.read_line reads keeps what it read past its line in a
// buffer of its own, so a line costs one read(2) per FILE_LINE_CAP bytes,
// not one per byte, on a pipe or a terminal as on a file. The bytes in it
// are the handle's, not the fd's: File.read answers them first, a write
// and File.close give them back to a file that seeks (lseek), and on a
// pipe they stay for the next read. A handle runs one effect at a time,
// so only the table, which handles on other threads grow, needs the lock.
// A line whole in the buffer answers on the loop, which polls its timers
// and helpers every 64 answers, as for any effect that answers at once;
// at most FILE_LINE_CAP lines fit, then a refill goes through the helper.
#define FILE_LINE_CAP 16384

typedef struct {
  u64  head;
  u64  tail;
  char data[FILE_LINE_CAP];
} FileLine;

static FileLine**      file_lines;
static u32             file_lines_len;
static pthread_mutex_t file_lines_gate = PTHREAD_MUTEX_INITIALIZER;

static FileLine* file_line_of(int fd, bool make) {
  FileLine* b = NULL;
  pthread_mutex_lock(&file_lines_gate);
  if (fd >= 0 && (u32)fd < file_lines_len) {
    b = file_lines[fd];
  }
  if (b == NULL && make && fd >= 0) {
    if ((u32)fd >= file_lines_len) {
      u32 len = (u32)fd * 2 + 8;
      file_lines = io_mem(realloc(file_lines, len * sizeof *file_lines));
      memset(file_lines + file_lines_len, 0,
        (len - file_lines_len) * sizeof *file_lines);
      file_lines_len = len;
    }
    b = file_lines[fd] = io_mem(malloc(sizeof *b));
    b->head = b->tail = 0;
  }
  pthread_mutex_unlock(&file_lines_gate);
  return b;
}

// How many buffered bytes the next answer takes: up to max, through the
// first '\n' when line is set, which sets *end.
static u64 file_line_cut(FileLine* b, u64 max, int line, int* end) {
  u64   len  = b->tail - b->head < max ? b->tail - b->head : max;
  char* from = b->data + b->head;
  char* nl   = line ? memchr(from, '\n', len) : NULL;
  if (end != NULL) {
    *end = nl != NULL;
  }
  return nl != NULL ? (u64)(nl + 1 - from) : len;
}

// Moves file_line_cut's bytes to out; answers how many.
static u64 file_line_take(FileLine* b, char* out, u64 max, int line,
  int* end) {
  u64 len = file_line_cut(b, max, line, end);
  memcpy(out, b->data + b->head, len);
  b->head += len;
  return len;
}

// Before a write, the position goes back to the end of the last line read,
// and the bytes past it leave the buffer. A pipe or a terminal keeps them:
// its reads and writes are apart. So does a device whose seek answers
// without landing where it was asked. 0, or the errno of a failed seek on
// a file that seeks, which keeps the bytes.
static int file_line_sync(int fd) {
  FileLine* b = file_line_of(fd, false);
  if (b == NULL || b->head == b->tail || isatty(fd)) {
    return 0;
  }
  off_t at = lseek(fd, 0, SEEK_CUR);
  off_t to = at - (off_t)(b->tail - b->head);
  if (at < 0 || to < 0) {
    return 0;
  }
  off_t got = lseek(fd, to, SEEK_SET);
  if (got < 0) {
    return errno;
  }
  if (got == to) {
    b->head = b->tail = 0;
  }
  return 0;
}

// File.close, and File.open, which may get the number of an fd closed
// past File.close, drop the buffer of fd.
static void file_line_drop(int fd) {
  pthread_mutex_lock(&file_lines_gate);
  if (fd >= 0 && (u32)fd < file_lines_len) {
    free(file_lines[fd]);
    file_lines[fd] = NULL;
  }
  pthread_mutex_unlock(&file_lines_gate);
}

#endif

// read(2) answers what is there, not what was asked: a pipe, a terminal
// and a short read all stop before max. Fill the buffer or reach EOF, so
// a caller that asked for n bytes gets n unless the file ends first,
// starting with what File.read_line buffered. An error after some bytes
// answers them (a pipe has already given them up); at reads at w->made,
// past the buffer, and leaves the position.
static void file_read_fill(IoWork* w, int at) {
  int fd  = (int)w->hand;
  u64 got = 0;
  w->code = 0;
#ifdef CID(File.read_line)
  FileLine* b = at ? NULL : file_line_of(fd, false);
  got = b != NULL ? file_line_take(b, w->data, w->word, 0, NULL) : 0;
  if (got > 0 && got == w->word) {
    w->size = got;
    return;
  }
#endif
  do {
    u64     want = w->word - got;
    ssize_t n;
    do {
      n = at ? pread(fd, w->data + got, want, (off_t)(w->made + got))
             : read(fd, w->data + got, want);
    } while (n < 0 && errno == EINTR);
    if (n <= 0) {
      w->size = got > 0 ? got : io_sys_end(w, n);
      return;
    }
    got += (u64)n;
  } while (got < w->word);
  w->size = got;
}

static void file_read_call(IoWork* w) {
  file_read_fill(w, 0);
}

static Term file_read_start(Term file, u64 max, IoWork* w,
  IoCall call, IoPack pack) {
  w->hand = (intptr_t)io_hand_v(file);
  w->word = max < INT32_MAX ? max : INT32_MAX;
  w->data = io_mem(malloc(w->word + 1));
  io_sync();
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

// One read(2) refills the buffer with what is there, so a terminal or a
// pipe answers a line as soon as it has come.
static void file_read_line_call(IoWork* w) {
  // The loop below reads nothing for max 0, so a bad handle would answer
  // "": file_read_fill makes the 0-byte read(2) that File.read does.
  if (w->word == 0) {
    file_read_fill(w, 0);
    return;
  }
  int       fd  = (int)w->hand;
  FileLine* b   = file_line_of(fd, true);
  u64       got = 0;
  int       end = 0;
  w->code = 0;
  while (got < w->word && !end) {
    if (b->head == b->tail) {
      ssize_t n;
      do {
        n = read(fd, b->data, FILE_LINE_CAP);
      } while (n < 0 && errno == EINTR);
      if (n <= 0) {
        w->size = got > 0 ? got : io_sys_end(w, n);
        return;
      }
      b->head = 0;
      b->tail = (u64)n;
    }
    got += file_line_take(b, w->data + got, w->word - got, 1, &end);
  }
  w->size = got;
}

// A line already whole in the buffer, or max bytes of one, answers here,
// straight from the buffer: it reads no fd, so it neither blocks nor
// flushes stdout, and skips the helper thread's round trip.
Term file_read_line_run(Env e, Term* f, IoWork* w) {
  u64       hand = io_hand_v(f[0]);
  FileLine* b    = file_line_of((int)hand, false);
  u64       max  = f[1] < INT32_MAX ? f[1] : INT32_MAX;
  int       end  = 0;
  u64       len  = b != NULL ? file_line_cut(b, max, 1, &end) : 0;
  if (b != NULL && b->head < b->tail && (end || len == max)) {
    w->code = 0;
    Term r = io_res(e, w, io_str(e, b->data + b->head, len));
    b->head += len;
    return io_tup(e, io_hand(hand), r);
  }
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
  file_read_fill(w, 1);
}

Term file_read_at_run(Env e, Term* f, IoWork* w) {
  w->made = (intptr_t)f[1];
  return file_read_start(f[0], f[2], w, file_read_at_call, file_read_bytes_pack);
}

static void __attribute__((constructor)) file_read_at_use(void) {
  io_eff(CID(File.read_at), file_read_at_run);
}

#endif
