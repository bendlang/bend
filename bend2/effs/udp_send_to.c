// UDP
// ===

// A datagram goes whole or not at all; a full send buffer (non-blocking,
// so EAGAIN) parks the computation until the socket is writable, or, for
// try_, until its deadline w->time, then answers Wait{data}. A failure
// answers Fail{(error, data)}: the datagram comes back either way.
static Term udp_send_to_more(Env e, IoWork* w) {
  struct sockaddr_in at;
  int     fd = (int)w->hand;
  u64     by = w->time;
  ssize_t n  = -1;
  errno      = EINVAL;
  if (io_sys_addr(w->text, (u32)w->made, &at) == 0) {
    n = sendto(fd, w->data, w->size, 0, (struct sockaddr*)&at, sizeof(at));
  }
  io_sys_end(w, n);
  if (w->code == EAGAIN && (by == 0 || io_tick() < by)) {
    return io_wait_on(w, fd, POLLOUT, by, udp_send_to_more);
  }
  Term r = io_done(e, term_pak(CID(Unit), 0));
  if (w->code == EAGAIN) {
    r = io_box(e, CID(Wait), io_str(e, w->data, w->size));
  } else if (w->code != 0) {
    const char* s = strerror((int)w->code);
    r = io_box(e, CID(Fail), io_tup(e, io_tup(e, w->code,
      io_str(e, s, strlen(s))), io_str(e, w->data, w->size)));
  }
  if (by != 0 && w->code != EAGAIN) {
    r = io_box(e, CID(Ready), r);
  }
  free(w->text);
  free(w->data);
  return io_tup(e, io_hand(w->hand), r);
}

// A host with a NUL byte fails with EINVAL, as an unparsable one does.
// by is the try_ deadline, 0 for the blocking twin.
static Term udp_send_to_start(Env e, Term* f, IoWork* w, u64 by) {
  uint64_t hn = 0;
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->text = io_cstr(e, f[1], &hn);
  w->made = (intptr_t)f[2];
  w->data = io_cstr(e, f[3], &w->size);
  w->time = by;
  if (io_nul(w->text, hn)) {
    free(w->text);
    w->text = io_mem(strdup("-"));
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
  return udp_send_to_start(e, f, w, io_tick() + (u64)f[4] * 1000000ull);
}

static void __attribute__((constructor)) udp_try_send_to_use(void) {
  io_eff(CID(UDP.try_send_to), udp_try_send_to_run, 0);
}

#endif
