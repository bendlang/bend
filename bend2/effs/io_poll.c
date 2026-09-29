// IO
// ==

// IO.poll (see base.bend). A request's poll is its computation's frames,
// innermost first: a poll's (k, until), or a raw one (k), which IO.resume
// and IO.cancel push under a continuation that is not a polled act's end.
// A polled act runs with io_emit as its continuation, so the Emit that ends
// it pops the top frame: a poll's answers Ready{x}, a raw one x; a request
// whose continuation is that end answers the frame itself, with no Emit.
// Under a poll's frame, io_poll_step takes a request that IO.cancel can
// answer (a
// channel step, a sleep, or an effect that asks IO_HAND and waits on its
// handle) and that would wait: past the poll's until, it answers the poll
// Wait{rest}, rest being the untouched request and the frames above the
// poll's, all terms; before, the request waits for its handle or until,
// whichever comes first, a sleep ends in time or is held at until, and a
// channel step parks on its row as usual, with a timer that takes it back
// out at until. A rest is the request alone, or a node of IO.poll's three
// fields: the request, the frames' continuations (the same nodes, the
// nearest the poll first, down to 0), and 0. io_poll_step answers io_step
// 1 to go on with w's cont and item, 2 to stop (w waits), 0 to run the
// request as usual. Frames are recycled (io_poll_idle).

#ifdef CID(IO.poll)

typedef struct IoPoll {
  Term           k;
  u64            until;
  u32            raw;
  struct IoPoll* up;
} IoPoll;

static u32     io_poll_serial;
static IoPoll* io_poll_idle;

static Term io_poll_ctr(Env e, u32 cid, u32 n, Term* fs) {
  u64 l = heap_alloc(e, cls_fit(n));
  for (u32 i = 0; i < n; i += 1) {
    e.mem[l + i] = io_seal(e, fs[i], cid);
  }
  return term_ctr(cid, l);
}

static void io_poll_take(Env e, Term t, u32 n, Term* fs) {
  spare_free(e, cls_fit(n), ctr_take(e, t, n, fs));
}

static void io_poll_push(IoWork* w, Term k, u64 until, u32 raw) {
  IoPoll* p = io_poll_idle;
  if (p != NULL) {
    io_poll_idle = p->up;
  } else {
    p = io_mem(malloc(sizeof(IoPoll)));
  }
  *p      = (IoPoll){ k, until, raw, w->poll };
  w->poll = p;
}

// Pops w's top frame and goes on with its continuation, answering x.
static void io_poll_pop(Env e, IoWork* w, Term x) {
  IoPoll* f    = w->poll;
  w->poll      = f->up;
  w->cont      = f->k;
  w->item      = f->raw ? x : io_box(e, CID(Ready), x);
  f->up        = io_poll_idle;
  io_poll_idle = f;
}

static IoPoll* io_poll_of(IoWork* w) {
  IoPoll* p = w->poll;
  while (p != NULL && p->raw) {
    p = p->up;
  }
  return p;
}

// Answers p Wait{rest} for w's request, the frames above p going with it.
static Term io_poll_hold(Env e, IoWork* w, IoPoll* p) {
  Term fr = 0;
  while (w->poll != p) {
    IoPoll* f = w->poll;
    w->poll = f->up;
    fr = io_poll_ctr(e, CID(IO.poll), 3, (Term[]){ f->k, fr, 0 });
    f->up        = io_poll_idle;
    io_poll_idle = f;
  }
  Term rest = fr == 0 ? w->cont
    : io_poll_ctr(e, CID(IO.poll), 3, (Term[]){ w->cont, fr, 0 });
  w->cont      = p->k;
  w->poll      = p->up;
  p->up        = io_poll_idle;
  io_poll_idle = p;
  return io_box(e, CID(Wait), rest);
}

static Term io_poll_late(Env e, IoWork* w) {
  return io_poll_hold(e, w, io_poll_of(w));
}

static bool io_poll_ready(IoWork* w) {
  struct pollfd p = { (int)w->word, w->evts, 0 };
  return poll(&p, 1, 0) > 0;
}

static Term io_poll_wake(Env e, IoWork* w) {
  return io_poll_ready(w) ? io_exec(e, w) : io_poll_late(e, w);
}

#ifdef CID(Chan.new)

// The deadline of a channel step parked on its row: if it still waits
// there (the same serial), it leaves the row and its poll holds it.
static Term io_poll_expire(Env e, IoWork* t) {
  IoWork*  w   = (IoWork*)t->hand;
  ChanRow* row = chan_at(io_hand(t->made));
  IoWork*  q   = row != NULL ? row->wait : NULL;
  while (q != NULL && (q->next != w || w->word != t->word)) {
    q = q->next != row->wait ? q->next : NULL;
  }
  if (q != NULL) {
    q->next   = w->next;
    row->wait = row->wait != w ? row->wait : q != w ? q : NULL;
    Term h    = io_hand(w->hand);
#ifdef CID(Chan.recv)
    if (w->item == TERM_HOLE) {
      w->cont = io_poll_ctr(e, CID(Chan.recv), 2, (Term[]){ h, w->cont });
    }
#endif
#ifdef CID(Chan.send)
    if (w->item != TERM_HOLE) {
      w->cont = io_poll_ctr(e, CID(Chan.send), 3,
        (Term[]){ h, w->item, w->cont });
    }
#endif
    w->item   = io_poll_late(e, w);
    io_push(&io_runs, w);
  }
  free(t);
  return IO_PARK;
}

#endif

// Whether IO.cancel can answer request c, and whether it would wait now.
static bool io_poll_can(u32 c, u32 ask) {
  bool ok = (ask & IO_HAND) && (ask & (IO_READ | IO_IN | IO_OUT));
#ifdef CID(IO.sleep)
  ok = ok || c == CID(IO.sleep);
#endif
#ifdef CID(Chan.send)
  ok = ok || c == CID(Chan.send);
#endif
#ifdef CID(Chan.recv)
  ok = ok || c == CID(Chan.recv);
#endif
  return ok;
}

static bool io_poll_waits(u32 c, u32 ask, Term* x) {
#ifdef CID(Chan.new)
  ChanRow* row = chan_at(x[0]);
  bool     rcv = row != NULL && row->wait != NULL
    && row->wait->next->item == TERM_HOLE;
#endif
#ifdef CID(Chan.send)
  if (c == CID(Chan.send)) {
    return row != NULL && !row->shut && !rcv && row->size >= row->room;
  }
#endif
#ifdef CID(Chan.recv)
  if (c == CID(Chan.recv)) {
    return row != NULL && !row->shut && row->size == 0
      && (row->wait == NULL || rcv);
  }
#endif
  if (ask & IO_TIME) {
    return (u32)x[0] > 0;
  }
  IoWork w = { .word = (u32)io_hand_v(x[0]),
    .evts = ask & IO_OUT ? POLLOUT : POLLIN };
  return !io_poll_ready(&w);
}

static u32 io_poll_step(Env e, IoWork* w) {
  Term  req = w->cont;
  u32   c   = (u32)term_aux(req);
  Term* x   = e.mem + term_peek(e.mem, req);
  if (c == CID(Emit)) {
    Term v;
    io_poll_take(e, req, 1, &v);
    io_poll_pop(e, w, v);
    return 1;
  }
  IoPoll* p   = io_poll_of(w);
  u32     ask = io_eff_rows[c].ask;
  bool    can = p != NULL && io_poll_can(c, ask);
  if (can && io_poll_waits(c, ask, x)) {
    u64 now = io_tick();
    if (now >= p->until) {
      w->item = io_poll_hold(e, w, p);
      return 1;
    }
    if (ask & IO_TIME) {
      if (now + (u64)(u32)x[0] * 1000000ull <= p->until) {
        return 0;
      }
      io_wait_on(w, 0, 0, p->until, io_poll_late);
      return 2;
    }
#ifdef CID(Chan.new)
    if (!(ask & IO_HAND)) {
      IoWork* t = io_mem(calloc(1, sizeof(IoWork)));
      t->hand   = (intptr_t)w;
      t->made   = (intptr_t)io_hand_v(x[0]);
      t->word   = w->word = ++io_poll_serial;
      t->time   = p->until;
      t->pack   = io_poll_expire;
      io_park_add(t);
      return 0;
    }
#endif
    io_wait_on(w, (int)io_hand_v(x[0]), ask & IO_OUT ? POLLOUT : POLLIN,
      p->until, io_poll_wake);
    return 2;
  }
  // a polled act's last request (its continuation the act's end) that
  // needs no wait from the loop answers the top frame itself, unless it
  // set another continuation (IO.poll, IO.resume, IO.cancel)
  u32 n = cid_arity(c);
  if (io_eff_rows[c].run == NULL || x[n - 1] != io_emit()
    || ((ask & (IO_READ | IO_TIME)) && !can)) {
    return 0;
  }
  Term v = io_exec(e, w);
  if (v == IO_PARK) {
    return 2;
  }
  if (w->cont != io_emit()) {
    w->item = v;
    return 1;
  }
  io_poll_pop(e, w, v);
  return 1;
}

Term io_poll_run(Env e, Term* f, IoWork* w) {
  io_poll_push(w, w->cont,
    f[0] == 0 ? 0 : io_tick() + (u64)(u32)f[0] * 1000000ull, 0);
  w->cont = f[1];
  return io_emit();
}

static void __attribute__((constructor)) io_poll_run_use(void) {
  io_eff(CID(IO.poll), io_poll_run, 0);
  io_polled = io_poll_step;
}

// Puts rest's frames back, over a raw frame for w's continuation unless it
// is a polled act's end, and answers rest's request.
static Term io_poll_back(Env e, Term rest, IoWork* w) {
  if (w->cont != io_emit()) {
    io_poll_push(w, w->cont, 0, 1);
  }
  if (term_tag(rest) != TAG_CTR || term_aux(rest) != CID(IO.poll)) {
    return rest;
  }
  Term fs[3];
  io_poll_take(e, rest, 3, fs);
  for (Term l = fs[1]; l != 0;) {
    Term c[3];
    io_poll_take(e, l, 3, c);
    io_poll_push(w, c[0], 0, 1);
    l = c[1];
  }
  return fs[0];
}

#endif

#ifdef CID(IO.resume)

// The request goes back to the loop: io_step takes an item with no cont as
// the request itself.
Term io_resume_run(Env e, Term* f, IoWork* w) {
  Term req = io_poll_back(e, f[0], w);
  w->cont  = 0;
  return req;
}

static void __attribute__((constructor)) io_resume_use(void) {
  io_eff(CID(IO.resume), io_resume_run, 0);
}

#endif

#ifdef CID(IO.cancel)

// The request answers cancelled, not run: a send False (its value
// dropped), a recv None, a sleep Unit, a handle's effect (handle,
// Fail{ECANCELED}).
Term io_cancel_run(Env e, Term* f, IoWork* w) {
  Term req = io_poll_back(e, f[0], w);
  u32  c   = (u32)term_aux(req);
  u32  n   = cid_arity(c);
  Term fs[16];
  io_poll_take(e, req, n, fs);
  w->cont = fs[n - 1];
  for (u32 i = 1; i + 1 < n; i += 1) {
    term_drop(e, fs[i]);
  }
#ifdef CID(Chan.send)
  if (c == CID(Chan.send)) {
    return term_pak(CID(False), 0);
  }
#endif
#ifdef CID(Chan.recv)
  if (c == CID(Chan.recv)) {
    return term_pak(CID(None), 0);
  }
#endif
#ifdef CID(IO.sleep)
  if (c == CID(IO.sleep)) {
    return term_pak(CID(Unit), 0);
  }
#endif
  return io_tup(e, fs[0], io_fail(e, ECANCELED, NULL));
}

static void __attribute__((constructor)) io_cancel_use(void) {
  io_eff(CID(IO.cancel), io_cancel_run, 0);
}

#endif
