// TCP
// ===

// Sends what is left; a full socket (non-blocking, so EAGAIN) parks the
// computation until the socket is writable, and the loop resumes here.
static Term tcp_send_more(Env e, IoWork* w) {
  int fd = (int)w->hand;
  while (w->code == 0 && (u64)w->made < w->size) {
    ssize_t n = send(fd, w->data + w->made, w->size - (u64)w->made, 0);
    if (n < 0 && errno == EAGAIN) {
      return io_wait_on(w, fd, POLLOUT, 0, tcp_send_more);
    }
    w->made += io_sys_end(w, n);
  }
  Term r = w->code != 0 ? io_fail(e, w->code, NULL)
    : io_done(e, term_pak(CID(Unit), 0));
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

#ifdef CID(TCP.send)

Term tcp_send_run(Env e, Term* f, IoWork* w) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->data = io_cstr(e, f[1], &w->size);
  w->made = 0;
  w->code = 0;
  return tcp_send_more(e, w);
}

static void __attribute__((constructor)) tcp_send_use(void) {
  io_eff(CID(TCP.send), tcp_send_run, 0);
}

#endif

#ifdef CID(TCP.send_bytes)

Term tcp_send_bytes_run(Env e, Term* f, IoWork* w) {
  int bad;
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->data = io_clist(e, f[1], &w->size, &bad);
  w->made = 0;
  w->code = bad ? EINVAL : 0;
  return tcp_send_more(e, w);
}

static void __attribute__((constructor)) tcp_send_bytes_use(void) {
  io_eff(CID(TCP.send_bytes), tcp_send_bytes_run, 0);
}

#endif
