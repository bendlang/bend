#ifdef __OBJC__
#import <Foundation/Foundation.h>
#endif

Term framework_guard_run(Env e, Term* f, IoWork* w) {
#ifdef __APPLE__
  return [@"hello" length];
#else
  return 5;
#endif
}

static void __attribute__((constructor)) framework_guard_use(void) {
  io_eff(CID(Framework.guard), framework_guard_run);
}
