// Chan
// ====

// Chan.new, send, recv and close share this file: the rows live here, and
// each effect registers when the program uses it.

typedef struct {
  u32   gen;
  u32   next;
  u32   room;
  u32   size;
  u32   head;
  u32   live;
  u32   shut;
  Term* ring;
  IoWork* wait;
} ChanRow;

// A channel is Data: its handle is copied and may outlive the row, so it
// names the row by index and generation, a freed row waits on a list and
// comes back one generation up, and a stale copy finds no row (closed).
static ChanRow* chan_rows;
static u32      chan_len;
static u32      chan_idle = ~0u;

#define chan_some(e, v) io_box(e, CID(Some), v)
#define chan_bool(b)    term_pak((b) ? CID(True) : CID(False), 0)

static Term chan_open(u32 room) {
  u32 i = chan_idle;
  if (i != ~0u) {
    chan_idle = chan_rows[i].next;
  } else {
    if (chan_len == 1u << 24) {
      err_fail("more than 16777216 channels at once");
    }
    if ((chan_len & (chan_len - 1)) == 0) {
      chan_rows = io_mem(realloc(chan_rows,
        (chan_len == 0 ? 1 : 2 * chan_len) * sizeof(ChanRow)));
    }
    i = chan_len;
    chan_len += 1;
    chan_rows[i].gen = 0;
  }
  ChanRow* row = &chan_rows[i];
  *row = (ChanRow){ .gen = row->gen + 1, .room = room, .live = 1,
    .ring = room == 0 ? NULL : io_mem(malloc(room * sizeof(Term))) };
  return io_hand(((u64)row->gen << 24) | i);
}

static ChanRow* chan_at(Term t) {
  u64      v   = io_hand_v(t);
  u32      i   = (u32)v & 0xFFFFFF;
  ChanRow* row = i < chan_len ? &chan_rows[i] : NULL;
  return row != NULL && row->live && row->gen == (u32)(v >> 24) ? row : NULL;
}

// Parks the effect's activation on row with item: a sent value, or
// TERM_HOLE for a receiver.
static Term chan_park(ChanRow* row, IoWork* w, Term item) {
  w->item = item;
  io_push(&row->wait, w);
  return IO_PARK;
}

static Term chan_wake(ChanRow* row, Term x) {
  IoWork* a = io_pop(&row->wait);
  Term item = a->item;
  a->item   = x;
  io_push(&io_runs, a);
  return item;
}

static Term chan_take(ChanRow* row) {
  Term v = row->ring[row->head];
  row->head = (row->head + 1) % row->room;
  row->size -= 1;
  if (row->wait != NULL) {
    Term item = chan_wake(row, chan_bool(true));
    row->ring[(row->head + row->size) % row->room] = item;
    row->size += 1;
  }
  return v;
}

static void chan_free(ChanRow* row) {
  free(row->ring);
  row->live = 0;
  row->next = chan_idle;
  chan_idle = (u32)(row - chan_rows);
}

static void chan_shut(Env e, ChanRow* row) {
  row->shut = 1;
  while (row->wait != NULL) {
    bool rcv = row->wait->next->item == TERM_HOLE;
    Term x = rcv ? term_pak(CID(None), 0) : chan_bool(false);
    term_sink(e, chan_wake(row, x));
  }
  if (row->size == 0) {
    chan_free(row);
  }
}

#ifdef CID(Chan.new)

Term chan_new_run(Env e, Term* f, IoWork* w) {
  return chan_open((u32)f[0]);
}

static void __attribute__((constructor)) chan_new_use(void) {
  io_eff(CID(Chan.new), chan_new_run, 0);
}

#endif

#ifdef CID(Chan.send)

Term chan_send_run(Env e, Term* f, IoWork* w) {
  ChanRow* row = chan_at(f[0]);
  if (row == NULL || row->shut) {
    term_drop(e, f[1]);
    return chan_bool(false);
  }
  if (row->wait != NULL && row->wait->next->item == TERM_HOLE) {
    chan_wake(row, chan_some(e, f[1]));
    return chan_bool(true);
  }
  if (row->size < row->room) {
    row->ring[(row->head + row->size) % row->room] = f[1];
    row->size += 1;
    return chan_bool(true);
  }
  return chan_park(row, w, f[1]);
}

static void __attribute__((constructor)) chan_send_use(void) {
  io_eff(CID(Chan.send), chan_send_run, 0);
}

#endif

#ifdef CID(Chan.recv)

Term chan_recv_run(Env e, Term* f, IoWork* w) {
  ChanRow* row = chan_at(f[0]);
  if (row == NULL) {
    return term_pak(CID(None), 0);
  }
  if (row->size > 0) {
    Term v = chan_take(row);
    if (row->shut && row->size == 0) {
      chan_free(row);
    }
    return chan_some(e, v);
  }
  if (row->wait != NULL && row->wait->next->item != TERM_HOLE) {
    return chan_some(e, chan_wake(row, chan_bool(true)));
  }
  if (row->shut) {
    chan_free(row);
    return term_pak(CID(None), 0);
  }
  return chan_park(row, w, TERM_HOLE);
}

static void __attribute__((constructor)) chan_recv_use(void) {
  io_eff(CID(Chan.recv), chan_recv_run, 0);
}

#endif

#ifdef CID(Chan.close)

Term chan_close_run(Env e, Term* f, IoWork* w) {
  ChanRow* row = chan_at(f[0]);
  if (row != NULL && !row->shut) {
    chan_shut(e, row);
  }
  return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) chan_close_use(void) {
  io_eff(CID(Chan.close), chan_close_run, 0);
}

#endif
