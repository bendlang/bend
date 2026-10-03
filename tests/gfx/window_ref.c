#if defined(__linux__)
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#endif

Term windowreftest_probe_run(Env e, Term* f, IoWork* w) {
  u64 dn = 0, tn = 0;
  char* display = io_cstr(e, f[0], &dn);
  char* title = io_cstr(e, f[2], &tn);
  bool ok = false;
#if defined(__linux__)
  Display* dpy = XOpenDisplay(display);
  if (dpy != NULL) {
    Window id = (u32)f[1];
    XWindowAttributes attrs;
    XSizeHints hints;
    long supplied;
    char* name = NULL;
    ok = XGetWindowAttributes(dpy, id, &attrs) && XFetchName(dpy, id, &name)
      && name != NULL && strcmp(name, title) == 0
      && XGetWMNormalHints(dpy, id, &hints, &supplied)
      && (hints.flags & (PMinSize | PMaxSize)) == (PMinSize | PMaxSize)
      && hints.min_width == 320 && hints.min_height == 200
      && hints.max_width == 320 && hints.max_height == 200;
    if (name != NULL) {
      XFree(name);
    }
    if (ok && term_aux(f[3]) == CID(True)) {
      XEvent ev = {0};
      ev.xclient.type = ClientMessage;
      ev.xclient.window = id;
      ev.xclient.message_type = XInternAtom(dpy, "WM_PROTOCOLS", False);
      ev.xclient.format = 32;
      ev.xclient.data.l[0] = XInternAtom(dpy, "WM_DELETE_WINDOW", False);
      ok = XSendEvent(dpy, id, False, NoEventMask, &ev) != 0;
      XSync(dpy, False);
    }
    XCloseDisplay(dpy);
  }
#endif
  free(display);
  free(title);
  return term_pak(ok ? CID(True) : CID(False), 0);
}

static void __attribute__((constructor)) window_ref_test_use(void) {
  io_eff(CID(WindowRefTest.probe), windowreftest_probe_run, 0);
}
