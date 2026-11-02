// Every name the module defines is an HID but the include guard and the
// macro, whose definitions its paste takes back.
#ifndef COUNTER
#define COUNTER
#define START 70
static u32 HID(count) = START;

static u32 HID(next)(void) {
  return ++HID(count);
}
#endif

Term HID(now_run)(Env e, Term* f, IoWork* w) {
  return term_pak(CID(Instant), HID(next)());
}

static void __attribute__((constructor)) HID(now_use)(void) {
  io_eff(CID(now), HID(now_run));
}
