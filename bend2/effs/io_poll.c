// IO
// ==

// IO.poll (see base.bend). A request's poll is its computation's poll
// frames, innermost first: (k, until, late, own), until clipped to the
// enclosing frame's, own the frame whose deadline it is. A polled act runs
// with io_emit as its continuation, so the Emit that ends it pops the top
// frame, which answers Ready{x}, or Late{x} once an effect in the act was
// cancelled; a request whose continuation is that end answers the frame
// itself, with no Emit. Under a frame, io_poll_step takes a request that
// can be cancelled (a channel step, a sleep, or an effect that asks IO_IN
// or IO_OUT: its handle first, (handle, Result) back) and that would wait:
// past the frame's until, it answers the request cancelled, unrun, and
// yields to the other computations, as a wait would; before, the request
// waits for its handle or until, whichever comes first, a sleep ends in
// time or is cancelled at until, and a channel step parks on its row with
// a timer the waiter owns (in made): waking the waiter disarms it
// (chan_disarm), and at until it takes the waiter back out. io_poll_step
// answers io_step 1 to go on with w's cont and item, 2 to stop (w waits
// or was requeued), 0 to run the request as usual. Frames are recycled.

#ifdef CID(IO.poll)

typedef struct IoPoll {
  Term           k;
  u64            until;
  u32            late;
  struct IoPoll* own;
  struct IoPoll* up;
} IoPoll;

static IoPoll* io_poll_idle;

// A cancel under p: p and the frames up to the one whose deadline it was
// turn late.
static void io_poll_late(IoPoll* p) {
  for (;; p = p->up) {
    p->late = 1;
    if (p == p->own) {
      return;
    }
  }
}

// Pops w's top frame and goes on with its continuation, answering x.
static void io_poll_pop(Env e, IoWork* w, Term x) {
  IoPoll* f    = w->poll;
  w->poll      = f->up;
  w->cont      = f->k;
  w->item      = io_box(e, f->late ? CID(Late) : CID(Ready), x);
  f->up        = io_poll_idle;
  io_poll_idle = f;
}

// A cancelled channel step's answer: a send False, a recv None.
static Term io_poll_chan(bool send) {
#ifdef CID(Chan.send)
  if (send) {
    return term_pak(CID(False), 0);
  }
#endif
#ifdef CID(Chan.recv)
  if (!send) {
    return term_pak(CID(None), 0);
  }
#endif
  return 0;
}

// w's request cancelled, unrun: its continuation goes on with what it
// answers cancelled, its other fields dropped (a send's value too), and
// its frame turns late. A channel step answers io_poll_chan, a sleep Unit,
// an effect on a handle (handle, Fail{ECANCELED}).
static Term io_poll_cancel(Env e, IoWork* w) {
  u32  c = (u32)term_aux(w->cont);
  u32  n = cid_arity(c);
  Term fs[256];
  spare_free(e, cls_fit(n), ctr_take(e, w->cont, n, fs));
  w->cont = fs[n - 1];
  io_poll_late(w->poll);
  for (u32 i = 1; i + 1 < n; i += 1) {
    term_drop(e, fs[i]);
  }
#ifdef CID(Chan.send)
  if (c == CID(Chan.send)) {
    return io_poll_chan(true);
  }
#endif
#ifdef CID(Chan.recv)
  if (c == CID(Chan.recv)) {
    return io_poll_chan(false);
  }
#endif
#ifdef CID(IO.sleep)
  if (c == CID(IO.sleep)) {
    return term_pak(CID(Unit), 0);
  }
#endif
  return io_tup(e, fs[0], io_fail(e, ECANCELED, NULL));
}

// Whether fd is ready now, by select as io_wait asks (macOS poll misses a
// FIFO's EOF).
static bool io_poll_fd(int fd, short evts) {
  u64 len = (u64)fd / 64 * 8 + 8;
  u8  small[128];
  u8* set = len <= sizeof small ? small : io_mem(malloc(len));
  memset(set, 0, len);
  io_bit(set, fd, true);
  struct timeval tv = { 0, 0 };
  int n = select(fd + 1, evts == POLLIN ? (fd_set*)set : NULL,
    evts == POLLIN ? NULL : (fd_set*)set, NULL, &tv);
  if (set != small) {
    free(set);
  }
  return n > 0;
}

static Term io_poll_wake(Env e, IoWork* w) {
  return io_poll_fd((int)w->word, w->evts) ? io_exec(e, w)
    : io_poll_cancel(e, w);
}

#ifdef CID(Chan.new)

// A channel step's deadline, unless chan_wake disarmed it (hand 0): its
// waiter, still parked on its row, leaves the row and answers cancelled.
static Term io_poll_expire(Env e, IoWork* t) {
  IoWork* w = (IoWork*)t->hand;
  if (w != NULL) {
    ChanRow* row = chan_at(io_hand(t->made));
    IoWork*  q   = row->wait;
    while (q->next != w) {
      q = q->next;
    }
    bool send = w->item != TERM_HOLE;
    q->next   = w->next;
    row->wait = row->wait != w ? row->wait : q != w ? q : NULL;
    w->made   = 0;
    io_poll_late(w->poll);
    if (send) {
      term_drop(e, w->item);
    }
    w->item = io_poll_chan(send);
    io_push(&io_runs, w);
  }
  free(t);
  return IO_PARK;
}

#endif

// Whether request c can be cancelled, and whether it would wait now.
static bool io_poll_can(u32 c, u32 ask) {
  bool ok = (ask & (IO_IN | IO_OUT)) != 0;
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
  if (ask & (IO_IN | IO_OUT)) {
    return !io_poll_fd((int)io_hand_v(x[0]), ask & IO_OUT ? POLLOUT : POLLIN);
  }
  if (ask & IO_TIME) {
    return (u32)x[0] > 0;
  }
#ifdef CID(Chan.new)
  ChanRow* row = chan_at(x[0]);
  if (row == NULL || row->shut) {
    return false;
  }
  bool rcv = row->wait != NULL && row->wait->next->item == TERM_HOLE;
#ifdef CID(Chan.send)
  if (c == CID(Chan.send)) {
    return !rcv && row->size >= row->room;
  }
#endif
  return row->size == 0 && (row->wait == NULL || rcv);
#else
  return false;
#endif
}

#ifdef CID(Chan.new)

// A channel step that would wait parks on its row now, with a timer for
// until that the waiter owns.
static u32 io_poll_park(Env e, IoWork* w, u64 until) {
  Term chan = e.mem[term_peek(e.mem, w->cont)];
  Term v    = io_exec(e, w);
  if (v != IO_PARK) {
    w->item = v;
    return 1;
  }
  IoWork* t = io_mem(calloc(1, sizeof(IoWork)));
  t->hand   = (intptr_t)w;
  t->made   = (intptr_t)io_hand_v(chan);
  t->time   = until;
  t->pack   = io_poll_expire;
  w->made   = (intptr_t)t;
  io_park_add(t);
  return 2;
}

#endif

static u32 io_poll_step(Env e, IoWork* w) {
  u32   c = (u32)term_aux(w->cont);
  Term* x = e.mem + term_peek(e.mem, w->cont);
  if (c == CID(Emit)) {
    Term v;
    spare_free(e, cls_fit(1), ctr_take(e, w->cont, 1, &v));
    io_poll_pop(e, w, v);
    return 1;
  }
  u32  ask = io_eff_rows[c].ask;
  bool can = io_poll_can(c, ask);
  if (can && io_poll_waits(c, ask, x)) {
    u64 until = w->poll->until;
    u64 now   = until == 0 ? 0 : io_tick();
    if (now >= until) {
      w->item = io_poll_cancel(e, w);
      if (w->cont == io_emit()) {
        io_poll_pop(e, w, w->item);
      }
      io_push(&io_runs, w);
      return 2;
    }
    if (ask & IO_TIME) {
      if (now + (u64)(u32)x[0] * 1000000ull <= until) {
        return 0;
      }
      io_wait_on(w, 0, 0, until, io_poll_cancel);
      return 2;
    }
#ifdef CID(Chan.new)
    if (!(ask & (IO_IN | IO_OUT))) {
      return io_poll_park(e, w, until);
    }
#endif
    io_wait_on(w, (int)io_hand_v(x[0]), ask & IO_OUT ? POLLOUT : POLLIN,
      until, io_poll_wake);
    return 2;
  }
  // a polled act's last request (its continuation the act's end) that
  // needs no wait from the loop answers the frame itself, unless it set
  // another continuation (a nested IO.poll)
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
  IoPoll* up = w->poll;
  IoPoll* p  = io_poll_idle;
  if (p != NULL) {
    io_poll_idle = p->up;
  } else {
    p = io_mem(malloc(sizeof(IoPoll)));
  }
  u64  ms    = (u32)f[0];
  u64  until = ms == 0 ? 0 : io_tick() + ms * 1000000ull;
  bool clip  = up != NULL && up->until <= until;
  *p         = (IoPoll){ w->cont, clip ? up->until : until, 0,
    clip ? up->own : p, up };
  w->poll    = p;
  w->cont    = f[1];
  return io_emit();
}

static void __attribute__((constructor)) io_poll_run_use(void) {
  io_eff(CID(IO.poll), io_poll_run, 0);
  io_polled = io_poll_step;
}

#endif
