// Window
// ======

// @src window_host.c

#ifdef __OBJC__

#import <AppKit/AppKit.h>

static void window_close(intptr_t at) {
  NSWindow* win = CFBridgingRelease((void*)at);
  [win close];
}

#elif defined(__linux__)

static void window_close(intptr_t at) {
  BendWin* win = (BendWin*)at;
  XDestroyImage(win->img);
  XCloseDisplay(win->dpy);
  free(win->evs);
  free(win);
}

#else

static void window_close(intptr_t at) {
}

#endif

Term window_close_run(Env e, Term* f, IoWork* w) {
  window_close((intptr_t)io_hand_v(f[0]));
  return term_pak(CID_UNIT, 0);
}

static void __attribute__((constructor)) window_close_use(void) {
  io_eff(CID_WINDOW_CLOSE, window_close_run, 0);
}
