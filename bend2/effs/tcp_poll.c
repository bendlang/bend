// TCP
// ===

// TCP.poll(sock, max, ms) is recv with a deadline: None{} when nothing
// waits (ms = 0: at once) or when nothing arrives within ms, else
// Some{data} ("" is the peer's close, as TCP.recv answers it). The park
// carries the deadline, so the loop wakes it for data or for the clock,
// whichever comes first.
static Term tcp_poll_none(Env e, IoWork* w) {
  free(w->data);
  return io_tup(e, io_hand(w->hand), io_done(e, term_pak(CID_NONE, 0)));
}

static Term tcp_poll_pack(Env e, IoWork* w) {
  Term r = w->code ? io_fail(e, w->code, NULL)
    : io_done(e, io_box(e, CID_SOME, io_str(e, w->data, w->size), IO_HOTS & 32));
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

// Woken by data or by the clock: a recv that still finds nothing parks
// again until the same deadline, or answers None{} once it has passed.
static Term tcp_poll_more(Env e, IoWork* w) {
  int fd  = (int)w->hand;
  u64 at  = io_wait_time(w);
  w->size = io_sys_end(w, recv(fd, w->data, (size_t)w->made, 0));
  if (w->code != EAGAIN) {
    return tcp_poll_pack(e, w);
  }
  return io_tick() >= at ? tcp_poll_none(e, w)
    : io_wait_for(w, fd, POLLIN, at, tcp_poll_more);
}

Term tcp_poll_run(Env e, Term* f, IoWork* w) {
  u64 ms  = (u64)f[2];
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->made = f[1] < INT32_MAX ? (intptr_t)f[1] : INT32_MAX;
  w->data = io_mem(malloc((size_t)w->made + 1));
  w->size = io_sys_end(w, recv((int)w->hand, w->data, (size_t)w->made, 0));
  if (w->code != EAGAIN) {
    return tcp_poll_pack(e, w);
  }
  return ms == 0 ? tcp_poll_none(e, w) : io_wait_for(w, (int)w->hand,
    POLLIN, io_tick() + ms * 1000000ull, tcp_poll_more);
}

static void __attribute__((constructor)) tcp_poll_use(void) {
  io_eff(CID_TCP_POLL, tcp_poll_run, 0);
}
