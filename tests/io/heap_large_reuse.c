static void reuse_need(bool ok, const char* message) {
  if (!ok) err_fail(message);
}

static bool reuse_empty(Env e, u32 cls) {
  return ALC_AT(e, cls) == 0 && ALC_LEN(e, cls) == 0
    && ALC_COLD(e, cls) == 0;
}

// Private lane rows share the real corpus and bank.
static void reuse_large(Env e, u32 cls) {
  u64 rows[2][3 * NCLS_ALL] = {0};
  Env a = {e.mem, rows[0]}, b = {e.mem, rows[1]};
  u64 first = heap_alloc(a, cls);
  heap_free(a, cls, first);
  u32 bump = a32_load(a32_at(e.mem, H_BUMP));
  u64 next = heap_alloc(b, cls);
  reuse_need(next == first && a32_load(a32_at(e.mem, H_BUMP)) == bump,
    "a large block stayed on the freeing lane");
  reuse_need(reuse_empty(a, cls) && reuse_empty(b, cls),
    "a large block left a local free chain");
  u64 words = 1ull << cls;
  for (u64 i = 1; i < words; i += 1) e.mem[next + i] = i ^ 12345;
  u64 other = heap_alloc(a, cls);
  reuse_need(other != next, "live blocks share one address");
  for (u64 i = 1; i < words; i += 1) e.mem[other + i] = ~i;
  for (u64 i = 1; i < words; i += 1) {
    reuse_need(e.mem[next + i] == (i ^ 12345) && e.mem[other + i] == ~i,
      "live block contents changed");
  }
  heap_free(b, cls, next);
  heap_free(a, cls, other);
  reuse_need(reuse_empty(a, cls) && reuse_empty(b, cls),
    "a large free left a local generation");
}

// Smaller blocks keep their one-block or two-block generations.
static void reuse_small(Env e, u32 cls) {
  u64 rows[2][3 * NCLS_ALL] = {0};
  Env a = {e.mem, rows[0]}, b = {e.mem, rows[1]};
  u64 blocks[4];
  u32 keep = KEEP(cls);
  reuse_need(2 * keep <= 4, "a small generation outgrew the check");
  for (u32 i = 0; i < 2 * keep; i += 1) blocks[i] = heap_alloc(a, cls);
  u32 bank = bank_at(e.mem, cls)->rd;
  for (u32 i = 0; i < keep; i += 1) {
    heap_free(a, cls, blocks[i]);
    if (i + 1 < keep) {
      reuse_need(ALC_AT(a, cls) == blocks[i] && ALC_COLD(a, cls) == 0,
        "a small partial generation left its lane");
    }
  }
  reuse_need(ALC_AT(a, cls) == 0 && ALC_COLD(a, cls) == blocks[keep - 1]
    && bank_at(e.mem, cls)->rd == bank,
    "the first small generation was not kept locally");
  for (u32 i = keep; i < 2 * keep; i += 1) heap_free(a, cls, blocks[i]);
  reuse_need(ALC_COLD(a, cls) == blocks[2 * keep - 1]
    && bank_at(e.mem, cls)->rd == bank + 1,
    "the next small generation did not bank the old one");
  u32 bump = a32_load(a32_at(e.mem, H_BUMP));
  for (u32 i = 0; i < keep; i += 1) {
    reuse_need(heap_alloc(b, cls) == blocks[keep - 1 - i]
      && heap_alloc(a, cls) == blocks[2 * keep - 1 - i],
      "small generations did not return all their blocks");
  }
  reuse_need(a32_load(a32_at(e.mem, H_BUMP)) == bump,
    "a small allocation grew the heap instead of reusing its generation");
  reuse_need(reuse_empty(a, cls) && reuse_empty(b, cls),
    "a consumed small generation kept a local chain");
  // Return both exact generations before the private rows leave scope.
  for (u32 i = 0; i < 2 * keep; i += keep) {
    for (u32 j = 0; j < keep; j += 1) {
      e.mem[blocks[i + j]] = j + 1 < keep ? blocks[i + j + 1] : 0;
    }
    bank_push(e.mem, cls, blocks[i]);
  }
}

Term heap_large_reuse_run(Env e, Term* f, IoWork* w) {
  u32 cls = cls_fit(CAP_WORDS);
  reuse_large(e, cls);
  reuse_large(e, cls + 2);
  reuse_small(e, cls_fit(KEEP_WORDS) - 1);
  if (KEEP_WORDS < CAP_WORDS) {
    reuse_small(e, cls_fit(KEEP_WORDS));
    reuse_small(e, cls - 1);
  }
  return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) heap_large_reuse_use(void) {
  io_eff(CID(Heap.check), heap_large_reuse_run);
}
