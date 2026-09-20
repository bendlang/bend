// Window
// ======

#ifdef __OBJC__

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

static void window_size(intptr_t at, u32* w, u32* h) {
  NSWindow* win = ((__bridge NSWindow*)(void*)at);
  NSSize size = [[[win contentView] layer] drawableSize];
  *w = (u32)size.width;
  *h = (u32)size.height;
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

static void window_size(intptr_t at, u32* w, u32* h) {
  BendWin* win = (BendWin*)at;
  *w = 0;
  *h = 0;
  if (win != NULL && win->img != NULL) {
    *w = (u32)win->img->width;
    *h = (u32)win->img->height;
  }
}

#else

static void window_size(intptr_t at, u32* w, u32* h) {
  (void)at;
  *w = 0;
  *h = 0;
}

#endif

Term window_size_run(Env e, Term* f, IoWork* w) {
  (void)w;
  u32 ww = 0;
  u32 hh = 0;
  window_size((intptr_t)io_hand_v(f[0]), &ww, &hh);
  return io_tup(e, f[0], io_tup(e, (u64)ww, (u64)hh));
}

static void __attribute__((constructor)) window_size_use(void) {
  io_eff(CID_WINDOW_SIZE, window_size_run, 0);
}
