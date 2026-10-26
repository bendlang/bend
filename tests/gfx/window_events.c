// The test's events, fed to the window's own handlers: its platform's name.
#ifdef __OBJC__

static NSEvent* feed_mouse(NSWindow* w, NSEventType type, double s) {
  return [NSEvent mouseEventWithType:type location:NSMakePoint(5, 42)
    modifierFlags:0 timestamp:s windowNumber:w.windowNumber context:nil
    eventNumber:0 clickCount:1 pressure:0];
}

Term feed_run(Env e, Term* f, IoWork* w) {
  NSWindow* win  = (__bridge NSWindow*)(void*)(uintptr_t)io_hand_v(f[0]);
  BendView* view = (BendView*)win.contentView;
  [view mouseMoved:feed_mouse(win, NSEventTypeMouseMoved, 4000000.0075)];
  [view mouseDown:feed_mouse(win, NSEventTypeLeftMouseDown, 4000000.0085)];
  [view mouseUp:feed_mouse(win, NSEventTypeLeftMouseUp, 4000000.0095)];
  return io_tup(e, f[0], io_str(e, "mac", 3));
}

#elif defined(__linux__)

#include <pthread.h>
#include <unistd.h>

#define FEED_T 4000000000u

// XIGesturePinchEvent as libXi's XInput2.h lays it out
typedef struct {
  WinXIHead h;
  double    dx, dy, raw_dx, raw_dy, scale, angle;
  int       flags;
  int       mods[4];
  int       group[4];
} FeedPinch;

// Devices 21 to 23: a touch screen, a pen and an evdev touchpad (a
// dependent touch class, 2, with a force).
static WinXIClass  feed_cls[6];
static WinXIClass* feed_of[3][2] = { { &feed_cls[0], &feed_cls[1] },
  { &feed_cls[2], &feed_cls[3] }, { &feed_cls[4], &feed_cls[5] } };
static WinXIDevice feed_devs[3];

static WinXIDevice* feed_query(Display* dpy, int id, int* n) {
  *n = id >= 21 && id <= 23;
  return *n ? &feed_devs[id - 21] : NULL;
}

static void feed_free(WinXIDevice* d) {
}

static void feed_devices(Display* dpy) {
  Atom mt = XInternAtom(dpy, "Abs MT Pressure", False);
  Atom p  = XInternAtom(dpy, "Abs Pressure", False);
  feed_cls[0] = (WinXIClass){ XITouchClass, 21, XIDirectTouch };
  feed_cls[1] = (WinXIClass){ XIValuatorClass, 21, 2, mt, 0, 255 };
  feed_cls[2] = (WinXIClass){ XIValuatorClass, 22, 2, p, 0, 1000 };
  feed_cls[3] = (WinXIClass){ XIValuatorClass, 22, 3,
    XInternAtom(dpy, "Abs Tilt X", False), -64, 63 };
  feed_cls[4] = (WinXIClass){ XITouchClass, 23, 2 };
  feed_cls[5] = (WinXIClass){ XIValuatorClass, 23, 2, p, 0, 255 };
  for (int i = 0; i < 3; i += 1) {
    feed_devs[i] = (WinXIDevice){ 21 + i, "feed", 0, 0, True, 2, feed_of[i] };
  }
}

// A device event of dev at (x, y), its valuators those of mask.
static void feed_xi(BendWin* win, int type, int dev, int detail, double x,
  double y, u32 ms, unsigned char mask, double* vals) {
  WinXIEvent ev = { .h = { .evtype = type, .time = ms, .sourceid = dev,
    .detail = detail, .event_x = x, .event_y = y },
    .vals = { 1, &mask, vals } };
  XGenericEventCookie c = { .evtype = type, .data = &ev };
  int gx, gy;
  window_xi_event(win, &c, &gx, &gy);
}

static void feed_pinch(BendWin* win, int type, double scale, double angle) {
  FeedPinch ev = { .h = { .evtype = type, .detail = 2, .event_x = 7,
    .event_y = 8 }, .scale = scale, .angle = angle };
  XGenericEventCookie c = { .evtype = type, .data = &ev };
  int gx, gy;
  window_xi_event(win, &c, &gx, &gy);
}

static void feed_tell(Display* d, Window to, Window src, const char* msg,
  long a, long b) {
  XEvent ev = { .xclient = { .type = ClientMessage, .window = to,
    .message_type = XInternAtom(d, msg, False), .format = 32,
    .data.l = { (long)src, a, b, 0, 0 } } };
  XSendEvent(d, to, False, NoEventMask, &ev);
  XFlush(d);
}

// The connection's next event, or false after 3 s of none.
static bool feed_next(Display* d, XEvent* ev) {
  for (int i = 0; i < 3000 && XPending(d) == 0; i += 1) {
    usleep(1000);
  }
  if (XPending(d) == 0) {
    return false;
  }
  XNextEvent(d, ev);
  return true;
}

static char feed_big[300000];

// The drag source, on its own connection: a drag at a time onto the window
// (to), the next once it says Finished.
static void* feed_drag(void* arg) {
  Window      to    = (Window)(uintptr_t)arg;
  Display*    d     = XOpenDisplay(NULL);
  Window      src   = XCreateSimpleWindow(d, DefaultRootWindow(d), 0, 0, 1, 1,
    0, 0, 0);
  Atom        utf8  = XInternAtom(d, "UTF8_STRING", False);
  Atom        fin   = XInternAtom(d, "XdndFinished", False);
  const char* files = "file:///tmp/a%20b\r\nhello\r\nfile:///etc/x\r\n";
  XEvent      ev;
  XSetSelectionOwner(d, XInternAtom(d, "XdndSelection", False), src,
    CurrentTime);
  for (int k = 0; k < 3; k += 1) {
    Window req  = None;
    Atom   prop = None;
    u64    sent = 0;
    bool   end  = k != 1;
    feed_tell(d, to, src, "XdndEnter", 5L << 24,
      k == 0 ? XInternAtom(d, "text/uri-list", False) : utf8);
    feed_tell(d, to, src, "XdndPosition", 0, 0);
    feed_tell(d, to, src, "XdndDrop", 0, CurrentTime);
    while (feed_next(d, &ev)
      && !(ev.type == ClientMessage && ev.xclient.message_type == fin)) {
      if (ev.type == SelectionRequest) {
        XSelectionRequestEvent* r = &ev.xselectionrequest;
        long                    n = sizeof feed_big;
        req  = r->requestor;
        prop = k == 2 ? None : r->property;
        if (k == 0) {
          XChangeProperty(d, req, prop, r->target, 8, PropModeReplace,
            (const unsigned char*)files, (int)strlen(files));
        } else if (k == 1) {
          XSelectInput(d, req, PropertyChangeMask);
          XChangeProperty(d, req, prop, XInternAtom(d, "INCR", False), 32,
            PropModeReplace, (const unsigned char*)&n, 1);
        }
        XEvent no = { .xselection = { .type = SelectionNotify,
          .requestor = req, .selection = r->selection, .target = r->target,
          .property = prop, .time = r->time } };
        XSendEvent(d, req, False, NoEventMask, &no);
        XFlush(d);
      } else if (ev.type == PropertyNotify && !end
        && ev.xproperty.state == PropertyDelete && ev.xproperty.atom == prop) {
        u64 c = sizeof feed_big - sent < 65536 ? sizeof feed_big - sent : 65536;
        XChangeProperty(d, req, prop, utf8, 8, PropModeReplace,
          (const unsigned char*)feed_big + sent, (int)c);
        XFlush(d);
        sent += c;
        end   = c == 0;
      }
    }
  }
  XDestroyWindow(d, src);
  XCloseDisplay(d);
  return NULL;
}

Term feed_run(Env e, Term* f, IoWork* w) {
  BendWin* win = (BendWin*)(uintptr_t)io_hand_v(f[0]);
  WinXIDevice* (*query)(Display*, int, int*) = window_xi_query;
  void         (*drop)(WinXIDevice*)          = window_xi_free;
  double   full[] = { 255 }, half[] = { 128 }, hover[] = { 0, 30 };
  double   down[] = { 500 }, up[] = { 0 }, pad[] = { 40 };
  feed_devices(win->dpy);
  window_xi_query = feed_query;
  window_xi_free  = feed_free;
  win->nd         = 0;
  feed_xi(win, XI_TouchBegin, 21, 5, 10, 20, FEED_T + 1, 1 << 2, full);
  feed_xi(win, XI_TouchUpdate, 21, 5, 12, 20, FEED_T + 2, 1 << 2, half);
  feed_xi(win, XI_TouchEnd, 21, 5, 12, 20, FEED_T + 3, 0, NULL);
  feed_xi(win, XI_Motion, 22, 0, 30, 40, FEED_T + 4, 1 << 2 | 1 << 3, hover);
  feed_xi(win, XI_ButtonPress, 22, 1, 30, 40, FEED_T + 5, 1 << 2, down);
  feed_xi(win, XI_ButtonRelease, 22, 1, 30, 40, FEED_T + 6, 1 << 2, up);
  feed_xi(win, XI_Motion, 23, 0, 5, 6, FEED_T + 7, 1 << 2, pad);
  feed_xi(win, XI_ButtonPress, 23, 1, 5, 6, FEED_T + 8, 0, NULL);
  feed_xi(win, XI_ButtonRelease, 23, 1, 5, 6, FEED_T + 9, 0, NULL);
  feed_pinch(win, XI_GesturePinchBegin, 1, 0);
  feed_pinch(win, XI_GesturePinchUpdate, 2, 90);
  feed_pinch(win, XI_GesturePinchEnd, 2, 0);
  window_xi_query = query;
  window_xi_free  = drop;
  win->nd         = 0;
  for (u64 i = 0; i < sizeof feed_big; i += 1) {
    feed_big[i] = (char)('a' + i % 26);
  }
  pthread_t drag;
  pthread_create(&drag, NULL, feed_drag, (void*)(uintptr_t)win->win);
  pthread_detach(drag);
  return io_tup(e, f[0], io_str(e, "x11", 3));
}

#else

Term feed_run(Env e, Term* f, IoWork* w) {
  return io_tup(e, f[0], io_str(e, "", 0));
}

#endif

static void __attribute__((constructor)) feed_use(void) {
  io_eff(CID(feed), feed_run);
}
