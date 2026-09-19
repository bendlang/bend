// TCP
// ===

// TCP.recv through a decoder state, as file_read_text_go.c: the carried
// bytes (pend, low byte first; need of them) go before the ones received,
// and a scalar cut by the end of the chunk is carried out instead of
// replaced. A recv of 0 bytes is the end of the stream: the carry is
// replaced byte by byte and need answers 4. A recv that only feeds the
// carry would answer "" with the peer still open, so it parks again.
static u64 tcp_recv_text_go_cut(const char* p, u64 n) {
  for (u64 j = 1; j <= 3 && j <= n; j += 1) {
    u32 b = (u8)p[n - j];
    if ((b & 0xc0) != 0x80) {
      u64 k = b >= 0xc2 && b <= 0xdf ? 2 : b >= 0xe0 && b <= 0xef ? 3
        : b >= 0xf0 && b <= 0xf4 ? 4 : 0;
      return k > j ? j : 0;
    }
  }
  return 0;
}

static Term tcp_recv_text_go_pack(Env e, IoWork* w, u64 n, u64 cut, bool eof) {
  Term r;
  if (w->code) {
    r = io_fail(e, w->code, NULL);
  } else {
    u32 pend = 0;
    for (u64 m = 0; m < cut; m += 1) {
      pend |= (u32)(u8)w->data[n - cut + m] << (8 * m);
    }
    r = io_done(e, io_tup(e, pend, io_tup(e, eof ? 4 : (u32)cut,
      io_str(e, w->data, n - cut))));
  }
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

// The loop parked the request until the socket was readable; a recv that
// still finds nothing (the socket is non-blocking) parks again.
static Term tcp_recv_text_go_more(Env e, IoWork* w) {
  int fd  = (int)w->hand;
  w->size = io_sys_end(w, recv(fd, w->data + w->made, (size_t)w->word, 0));
  if (w->code == EAGAIN) {
    return io_wait_on(w, fd, POLLIN, tcp_recv_text_go_more);
  }
  if (w->code) {
    return tcp_recv_text_go_pack(e, w, 0, 0, false);
  }
  bool eof = w->size == 0 && w->word != 0;
  u64  n   = (u64)w->made + w->size;
  u64  cut = eof ? 0 : tcp_recv_text_go_cut(w->data, n);
  if (w->size > 0 && cut == n) {
    w->made = (intptr_t)n;
    return io_wait_on(w, fd, POLLIN, tcp_recv_text_go_more);
  }
  return tcp_recv_text_go_pack(e, w, n, cut, eof);
}

Term tcp_recv_text_go_run(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->made = f[2] < 4 ? (intptr_t)f[2] : 0;
  w->word = f[3] < INT32_MAX ? f[3] : INT32_MAX;
  w->data = io_mem(malloc((size_t)w->word + 4));
  for (intptr_t m = 0; m < w->made; m += 1) {
    w->data[m] = (char)(f[1] >> (8 * m));
  }
  return tcp_recv_text_go_more(e, w);
}

static void __attribute__((constructor)) tcp_recv_text_go_use(void) {
  io_eff(CID_TCP_RECV_TEXT_GO, tcp_recv_text_go_run, IO_READ);
}
