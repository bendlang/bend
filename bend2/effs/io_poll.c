// IO
// ==

// IO.poll: a request's poll is its frames, innermost first. A poll's frame
// answers Inl{x} once act ends in IO.poll.end, or Inr{w} where act would
// park: io_wait_on and the channels ask io_holds under a frame, and io_step
// answers the held request's poll (io_hold); w keeps the frames above the
// poll's. IO.resume takes the held request's place over a raw frame, which
// answers its continuation the value alone, and runs it again once
// io_ready: its pack, as the loop would have. IO.cancel answers it instead.

#ifdef CID(IO.poll.run)

typedef struct IoPoll {
  Term           k;
  u32            raw;
  struct IoPoll* up;
} IoPoll;

static bool io_poll_holds(IoWork* w) {
  for (IoPoll* p = w->poll; p != NULL; p = p->up) {
    if (!p->raw) {
      w->held = 1;
      return true;
    }
  }
  return false;
}

static IoWork* io_poll_hold(Env e, IoWork* w) {
  IoPoll* in = NULL;
  IoPoll* p  = w->poll;
  for (; p->raw; p = p->up) {
    in = p;
  }
  IoWork* b = io_mem(calloc(1, sizeof(IoWork)));
  b->cont   = p->k;
  b->poll   = p->up;
  b->item   = io_box(e, CID(Inr), io_hand(w));
  if (in != NULL) {
    in->up = NULL;
  } else {
    w->poll = NULL;
  }
  w->held = 0;
  free(p);
  return b;
}

static bool io_ready(IoWork* w) {
  if (w->time != 0 && io_tick() >= w->time) {
    return true;
  }
  if (w->evts == 0) {
    return w->time == 0;
  }
  struct pollfd p = { (int)w->word, w->evts, 0 };
  return poll(&p, 1, 0) > 0;
}

Term io_poll_run(Env e, Term* f, IoWork* w) {
  IoPoll* p = io_mem(malloc(sizeof(IoPoll)));
  *p      = (IoPoll){ w->cont, 0, w->poll };
  w->poll = p;
  w->cont = f[0];
  return io_emit();
}

static void __attribute__((constructor)) io_poll_run_use(void) {
  io_eff(CID(IO.poll.run), io_poll_run, 0);
  io_holds = io_poll_holds;
  io_hold  = io_poll_hold;
}

Term io_poll_end(Env e, Term* f, IoWork* w) {
  IoPoll* p = w->poll;
  term_drop(e, w->cont);
  w->poll = p->up;
  w->cont = p->k;
  Term x  = p->raw ? f[0] : io_box(e, CID(Inl), f[0]);
  free(p);
  return x;
}

static void __attribute__((constructor)) io_poll_end_use(void) {
  io_eff(CID(IO.poll.end), io_poll_end, 0);
}

#endif

#if defined(CID(IO.resume)) || defined(CID(IO.cancel))

// Puts the held request f[0] in w's place, over a raw frame for w's cont.
static void io_poll_take(Term* f, IoWork* w) {
  IoWork* h = (IoWork*)io_hand_v(f[0]);
  IoPoll* g = io_mem(malloc(sizeof(IoPoll)));
  *g = (IoPoll){ w->cont, 1, w->poll };
  IoPoll* p = h->poll;
  while (p != NULL && p->up != NULL) {
    p = p->up;
  }
  if (p != NULL) {
    p->up = g;
  }
  *w      = *h;
  w->poll = h->poll != NULL ? h->poll : g;
  free(h);
}

#endif

#ifdef CID(IO.resume)

Term io_resume_run(Env e, Term* f, IoWork* w) {
  io_poll_take(f, w);
  return io_ready(w) ? w->pack(e, w)
    : io_wait_on(w, (int)w->word, w->evts, w->time, w->pack);
}

static void __attribute__((constructor)) io_resume_use(void) {
  io_eff(CID(IO.resume), io_resume_run, 0);
}

#endif

#ifdef CID(IO.cancel)

// A held channel step answers as a closed channel would: a send False (its
// value dropped), a recv None. Other effects cannot be cancelled yet.
Term io_cancel_run(Env e, Term* f, IoWork* w) {
  io_poll_take(f, w);
#ifdef CID(Chan.new)
  if (w->pack == chan_again && w->item == TERM_HOLE) {
#ifdef CID(Chan.recv)
    return term_pak(CID(None), 0);
#endif
  }
  if (w->pack == chan_again) {
#ifdef CID(Chan.send)
    term_drop(e, w->item);
    return term_pak(CID(False), 0);
#endif
  }
#endif
  err_fail("IO.cancel: this effect cannot be cancelled yet");
  return IO_PARK;
}

static void __attribute__((constructor)) io_cancel_use(void) {
  io_eff(CID(IO.cancel), io_cancel_run, 0);
}

#endif
