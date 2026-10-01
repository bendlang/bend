// TCP
// ===

// Sends what is left; a full socket (non-blocking, so EAGAIN) parks the
// computation until the socket is writable, or, for try_, until its
// deadline w->time, then answers Wait{rest}. A failure answers
// Fail{(error, rest)}. rest, what the kernel did not take, is a String
// (io_str) or a List of bytes (io_list), as make builds it.
static Term tcp_send_with(Env e, IoWork* w, IoPack more,
  Term (*make)(Env, const char*, u64)) {
  int fd = (int)w->hand;
  u64 at = w->time;
  while (w->code == 0 && (u64)w->made < w->size) {
    ssize_t n = send(fd, w->data + w->made, w->size - (u64)w->made, 0);
    if (n < 0 && errno == EAGAIN && (at == 0 || io_tick() < at)) {
      return io_wait_on(w, fd, POLLOUT, at, more);
    }
    if (n < 0 && errno == EAGAIN) {
      Term rest = make(e, w->data + w->made, w->size - (u64)w->made);
      free(w->data);
      return io_tup(e, io_hand(w->hand), io_box(e, CID(Wait), rest));
    }
    w->made += io_sys_end(w, n);
  }
  Term r = io_done(e, term_pak(CID(Unit), 0));
  if (w->code != 0) {
    const char* s = strerror((int)w->code);
    r = io_box(e, CID(Fail), io_tup(e, io_tup(e, w->code, io_str(e, s,
      strlen(s))), make(e, w->data + w->made, w->size - (u64)w->made)));
  }
  free(w->data);
  return io_tup(e, io_hand(w->hand), at != 0 ? io_box(e, CID(Ready), r) : r);
}

static Term tcp_send_more(Env e, IoWork* w) {
  return tcp_send_with(e, w, tcp_send_more, io_str);
}

// at is the try_ deadline, 0 for the blocking twins.
static Term tcp_send_start(Env e, Term* f, IoWork* w, u64 at) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  w->data = io_cstr(e, f[1], &w->size);
  w->made = 0;
  w->code = 0;
  w->time = at;
  return tcp_send_more(e, w);
}

#ifdef CID(Con)

static Term tcp_send_bytes_more(Env e, IoWork* w) {
  return tcp_send_with(e, w, tcp_send_bytes_more, io_list);
}

// A value past 255 fails with EINVAL before any byte is sent, and the
// list comes back whole: it is read in place before it is taken.
static Term tcp_send_bytes_start(Env e, Term* f, IoWork* w, u64 at) {
  w->hand = (intptr_t)io_hand_v(f[0]);
  for (Term s = f[1]; term_aux(s) == CID(Con);) {
    u64 l = term_peek(e.mem, s);
    if (e.mem[l] > 255) {
      const char* m = strerror(EINVAL);
      Term r = io_box(e, CID(Fail), io_tup(e, io_tup(e, EINVAL, io_str(e, m,
        strlen(m))), f[1]));
      return io_tup(e, f[0], at != 0 ? io_box(e, CID(Ready), r) : r);
    }
    s = e.mem[l + 1];
  }
  w->data = io_cbuf(e, f[1], &w->size, CID(Con));
  w->made = 0;
  w->code = 0;
  w->time = at;
  return tcp_send_bytes_more(e, w);
}

#endif

#ifdef CID(TCP.send)

Term tcp_send_run(Env e, Term* f, IoWork* w) {
  return tcp_send_start(e, f, w, 0);
}

static void __attribute__((constructor)) tcp_send_use(void) {
  io_eff(CID(TCP.send), tcp_send_run);
}

#endif

#ifdef CID(TCP.send_bytes)

Term tcp_send_bytes_run(Env e, Term* f, IoWork* w) {
  return tcp_send_bytes_start(e, f, w, 0);
}

static void __attribute__((constructor)) tcp_send_bytes_use(void) {
  io_eff(CID(TCP.send_bytes), tcp_send_bytes_run);
}

#endif

#ifdef CID(TCP.try_send)

Term tcp_try_send_run(Env e, Term* f, IoWork* w) {
  return tcp_send_start(e, f, w, io_tick() + (u64)f[2] * 1000000ull);
}

static void __attribute__((constructor)) tcp_try_send_use(void) {
  io_eff(CID(TCP.try_send), tcp_try_send_run);
}

#endif

#ifdef CID(TCP.try_send_bytes)

Term tcp_try_send_bytes_run(Env e, Term* f, IoWork* w) {
  return tcp_send_bytes_start(e, f, w, io_tick() + (u64)f[2] * 1000000ull);
}

static void __attribute__((constructor)) tcp_try_send_bytes_use(void) {
  io_eff(CID(TCP.try_send_bytes), tcp_try_send_bytes_run);
}

#endif
