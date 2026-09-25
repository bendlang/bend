// Window
// ======

#ifdef __OBJC__

#import <AppKit/AppKit.h>

static void window_grab(intptr_t at, bool on) {
  NSWindow* win = (__bridge NSWindow*)(void*)at;
  [win.contentView setValue:@(on) forKey:@"grab"];
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
  u32      grab;
  int      lx;
  int      ly;
} BendWin;
#endif

// The pointer is confined to the window under a blank cursor and warped
// to its centre, where each frame puts it back; only a focused window
// takes it.
static void window_grab(intptr_t at, bool on) {
  BendWin* win = (BendWin*)at;
  Window   focus;
  int      revert;
  XGetInputFocus(win->dpy, &focus, &revert);
  if (on && !win->grab && focus == win->win) {
    char   zero = 0;
    XColor none = { 0 };
    Pixmap pix  = XCreateBitmapFromData(win->dpy, win->win, &zero, 1, 1);
    Cursor cur  = XCreatePixmapCursor(win->dpy, pix, pix, &none, &none, 0, 0);
    win->grab = XGrabPointer(win->dpy, win->win, True, PointerMotionMask
      | ButtonPressMask | ButtonReleaseMask, GrabModeAsync, GrabModeAsync,
      win->win, cur, CurrentTime) == GrabSuccess;
    XFreeCursor(win->dpy, cur);
    XFreePixmap(win->dpy, pix);
    if (win->grab) {
      win->lx = win->img->width / 2;
      win->ly = win->img->height / 2;
      XWarpPointer(win->dpy, None, win->win, 0, 0, 0, 0, win->lx, win->ly);
    }
  } else if (!on && win->grab) {
    XUngrabPointer(win->dpy, CurrentTime);
    win->grab = 0;
  }
  XFlush(win->dpy);
}

#else

static void window_grab(intptr_t at, bool on) {
}

#endif

Term window_grab_run(Env e, Term* f, IoWork* w) {
  window_grab((intptr_t)io_hand_v(f[0]), term_aux(f[1]) == CID(True));
  return f[0];
}

static void __attribute__((constructor)) window_grab_use(void) {
  io_eff(CID(Window.grab), window_grab_run, 0);
}
