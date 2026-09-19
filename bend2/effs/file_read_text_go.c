// File
// ====

// File.read through a decoder state: the carried bytes (pend, low byte
// first; need of them) go before the ones read, and a scalar cut by the
// end of the chunk (a lead and its continuations, 3 bytes at most) is
// carried out instead of replaced. A lead always starts a sequence in
// io_str's walk, so cutting it off first decodes the rest as the whole
// buffer would. A read of 0 bytes is the end of the file: the carry is
// replaced byte by byte and need answers 4.
static void file_read_text_go_call(IoWork* w) {
  int fd = (int)w->hand;
  w->size = io_sys_end(w, read(fd, w->data + w->made, w->word));
}

// The decode of p[0..n) less the scalar its end cuts, which goes to pend
// and need; at the end of the file nothing is cut and need is 4.
static Term file_read_text_go_dec(Env e, const char* p, u64 n, bool eof,
  u32* pend, u32* need) {
  u64 cut = 0;
  for (u64 j = 1; !eof && j <= 3 && j <= n; j += 1) {
    u32 b = (u8)p[n - j];
    if ((b & 0xc0) != 0x80) {
      u64 k = b >= 0xc2 && b <= 0xdf ? 2 : b >= 0xe0 && b <= 0xef ? 3
        : b >= 0xf0 && b <= 0xf4 ? 4 : 0;
      cut = k > j ? j : 0;
      break;
    }
  }
  *pend = 0;
  *need = eof ? 4 : (u32)cut;
  for (u64 m = 0; m < cut; m += 1) {
    *pend |= (u32)(u8)p[n - cut + m] << (8 * m);
  }
  return io_str(e, p, n - cut);
}

static Term file_read_text_go_pack(Env e, IoWork* w) {
  Term r;
  if (w->code) {
    r = io_fail(e, w->code, NULL);
  } else {
    u32  pend, need;
    Term s = file_read_text_go_dec(e, w->data, (u64)w->made + w->size,
      w->size == 0 && w->word != 0, &pend, &need);
    r = io_done(e, io_tup(e, pend, io_tup(e, need, s)));
  }
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

Term file_read_text_go_run(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->made = f[2] < 4 ? (intptr_t)f[2] : 0;
  w->word = f[3] < INT32_MAX ? f[3] : INT32_MAX;
  w->data = io_mem(malloc((size_t)w->word + 4));
  for (intptr_t m = 0; m < w->made; m += 1) {
    w->data[m] = (char)(f[1] >> (8 * m));
  }
  return io_work(w, file_read_text_go_call, file_read_text_go_pack);
}

static void __attribute__((constructor)) file_read_text_go_use(void) {
  io_eff(CID_FILE_READ_TEXT_GO, file_read_text_go_run, 0);
}
