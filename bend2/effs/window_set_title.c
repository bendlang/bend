// Window
// ======

#ifdef __OBJC__

#import <AppKit/AppKit.h>

static void window_set_title(intptr_t at, const char* text, u64 n) {
  NSWindow* win = (__bridge NSWindow*)(void*)at;
  win.title = [[NSString alloc] initWithBytes:text length:n
    encoding:NSUTF8StringEncoding];
}

#elif defined(__linux__)

#ifndef BendWin
#define BendWin BendWin
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>

typedef struct {
  Display* dpy;
  Window   win;
  Atom     del;
  XImage*  img;
  u32      n;
  u32      cap;
  u32*     evs;
} BendWin;
#endif

static void window_set_title(intptr_t at, const char* text, u64 n) {
  BendWin* win = (BendWin*)at;
  XStoreName(win->dpy, win->win, text);
  XFlush(win->dpy);
}

#else

static void window_set_title(intptr_t at, const char* text, u64 n) {
}

#endif

Term window_set_title_run(Env e, Term* f, IoWork* w) {
  u64   n    = 0;
  char* text = io_cstr(e, f[1], &n);
  window_set_title((intptr_t)io_hand_v(f[0]), text, n);
  free(text);
  return f[0];
}

static void __attribute__((constructor)) window_set_title_use(void) {
  io_eff(CID(Window.set_title), window_set_title_run, 0);
}
