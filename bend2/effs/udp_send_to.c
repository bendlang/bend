// UDP
// ===

// The datagram's answer: Done{}, or Fail{(error, data)}; Wait{data} past
// a try_ deadline.
static Term udp_send_to_end(Env e, IoWork* w) {
  Term r = io_poll_end(e, w, io_str(e, w->data, w->size), w->code == 0
    ? io_done(e, term_pak(CID(Unit), 0)) : io_box(e, CID(Fail),
      io_tup(e, io_err(e, w->code, NULL), io_str(e, w->data, w->size))));
  free(w->text);
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

// A datagram goes whole or not at all; a full send buffer (non-blocking,
// so EAGAIN) parks the computation until the socket is writable.
static Term udp_send_to_more(Env e, IoWork* w) {
  struct sockaddr_in at;
  int     fd = (int)w->hand;
  ssize_t n  = -1;
  errno      = EINVAL;
  if (io_sys_addr(w->text, (u32)w->made, &at) == 0) {
    n = sendto(fd, w->data, w->size, 0, (struct sockaddr*)&at, sizeof(at));
  }
  io_sys_end(w, n);
  if (io_again(w)) {
    return io_wait_on(w, fd, POLLOUT, w->time, udp_send_to_more);
  }
  return udp_send_to_end(e, w);
}

// at is the try_ deadline (past it, Wait{data}), 0 for the blocking twin.
// A host with a NUL in it is no address: EINVAL.
static Term udp_send_to_start(Env e, Term* f, IoWork* w, u64 at) {
  uint64_t hn = 0;
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->text = io_cstr(e, f[1], &hn);
  w->made = (intptr_t)f[2];
  w->data = io_cstr(e, f[3], &w->size);
  w->time = at;
  if (io_nul(w->text, hn)) {
    w->code = EINVAL;
    return udp_send_to_end(e, w);
  }
  return udp_send_to_more(e, w);
}

#ifdef CID(UDP.send_to)

Term udp_send_to_run(Env e, Term* f, IoWork* w) {
  return udp_send_to_start(e, f, w, 0);
}

static void __attribute__((constructor)) udp_send_to_use(void) {
  io_eff(CID(UDP.send_to), udp_send_to_run, 0);
}

#endif

#ifdef CID(UDP.try_send_to)

Term udp_try_send_to_run(Env e, Term* f, IoWork* w) {
  return udp_send_to_start(e, f, w, io_until(f[4]));
}

static void __attribute__((constructor)) udp_try_send_to_use(void) {
  io_eff(CID(UDP.try_send_to), udp_try_send_to_run, 0);
}

#endif
