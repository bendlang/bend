// Pulled by Window.open/frame/set_title/close (`// @src window_host.c`).
// The X11 window: its own connection (so its queue holds only its
// events), the frame's image and the events pumped since the last
// frame, five words each (kind, a, b, c, d) as on the Mac.
#if defined(__linux__)
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
