// IO
// ==

Term io_read_line_run(Env e, Term* f, IoWork* w) {
  (void)f;
  (void)w;
  size_t cap = 128, len = 0;
  char*  buf = io_mem(malloc(cap));
  int c, eof = 0;
  for (;;) {
    c = getchar();
    if (c == EOF) {
      eof = 1;
      break;
    }
    if (c == '\n') {
      break;
    }
    if (len + 1 >= cap) {
      cap *= 2;
      buf = io_mem(realloc(buf, cap));
    }
    buf[len++] = (char)c;
  }
  if (eof && len == 0) {
    free(buf);
    return term_pak(CID_NONE, 0);
  }
  if (len > 0 && buf[len - 1] == '\r') {
    len -= 1;
  }
  Term r = io_box(e, CID_SOME, io_str(e, buf, len), IO_HOTS & 32);
  free(buf);
  return r;
}

static void __attribute__((constructor)) io_read_line_use(void) {
  io_eff(CID_IO_READ_LINE, io_read_line_run, 0);
}
