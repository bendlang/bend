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

#define FEED_T 4000000000u

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
  f32 dx = 0, dy = 0;
  window_xi_event(win, &c, &dx, &dy);
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
  window_xi_query = query;
  window_xi_free  = drop;
  win->nd         = 0;
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
