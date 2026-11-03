#ifdef __APPLE__
#define PROBE_FRAMEWORK <Foundation/Foundation.h>
/* before */ #/**/import PROBE_FRAMEWORK
#elif defined(__linux__)
#define PROBE_X11 "X11/Xlib.h"
/* before */ #/**/include PROBE_X11
#define PROBE_ALSA <alsa/asoundlib.h>
#include/**/PROBE_ALSA
#endif

Term answer_run(Env e, Term* f, IoWork* w) {
#ifdef __APPLE__
  return [@"hello" length];
#elif defined(__linux__)
  return XInitThreads() && snd_asoundlib_version() != NULL ? 5 : 0;
#else
  return 5;
#endif
}

static void __attribute__((constructor)) answer_use(void) {
  io_eff(CID(answer), answer_run);
}
