// The test's events, fed to the window's own handlers over a fake fullscreen
// viewport: its 64 x 48 image at 4x in a 256 x 256 window, bars 32 tall
// above and below (on X11, as window_viewport lays it out, its XRender
// transform stubbed). Then the window is put back as it was.
#ifdef __OBJC__

static NSEvent* fake_mouse(NSWindow* w, NSEventType type, NSPoint p, u32 k) {
  return [NSEvent mouseEventWithType:type location:p modifierFlags:0
    timestamp:4000000.0005 + k * 0.001 windowNumber:w.windowNumber
    context:nil eventNumber:0 clickCount:1 pressure:0];
}

Term fake_run(Env e, Term* f, IoWork* w) {
  NSWindow* win     = (__bridge NSWindow*)(void*)(uintptr_t)io_hand_v(f[0]);
  BendView* view    = (BendView*)win.contentView;
  NSSize    size    = view.frame.size;
  NSString* gravity = view.layer.contentsGravity;
  [view setFrameSize:NSMakeSize(256, 256)];
  view.layer.contentsGravity = kCAGravityResizeAspect;
#define FAKE_AT(x, y) [view convertPoint:NSMakePoint(x, y) toView:nil]
  [view mouseMoved:fake_mouse(win, NSEventTypeMouseMoved, FAKE_AT(128, 160), 1)];
  [view mouseMoved:fake_mouse(win, NSEventTypeMouseMoved, FAKE_AT(128, 10), 2)];
  [view mouseDown:fake_mouse(win, NSEventTypeLeftMouseDown, FAKE_AT(128, 10), 3)];
  [view mouseMoved:fake_mouse(win, NSEventTypeMouseMoved, FAKE_AT(64, 96), 4)];
  [view mouseDown:fake_mouse(win, NSEventTypeLeftMouseDown, FAKE_AT(64, 96), 5)];
  [view mouseUp:fake_mouse(win, NSEventTypeLeftMouseUp, FAKE_AT(64, 10), 6)];
  CGEventRef look = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved,
    CGPointZero, kCGMouseButtonLeft);
  CGEventSetIntegerValueField(look, kCGMouseEventDeltaX, 40);
  CGEventSetIntegerValueField(look, kCGMouseEventDeltaY, -20);
  view->grab = YES;
  [view mouseMoved:[NSEvent eventWithCGEvent:look]];
  view->grab = NO;
  CFRelease(look);
  view.layer.contentsGravity = gravity;
  [view setFrameSize:size];
  return io_tup(e, f[0], io_str(e, "mac", 3));
}

#elif defined(__linux__)

#define FAKE_T 4000000000u

// Devices 31 to 33: a mouse, a touch screen and a pen.
static WinXIClass  fake_touch = { XITouchClass, 32, XIDirectTouch };
static WinXIClass  fake_force;
static WinXIClass* fake_of[2] = { &fake_touch, &fake_force };
static WinXIDevice fake_devs[3];

static WinXIDevice* fake_query(Display* dpy, int id, int* n) {
  *n = id >= 31 && id <= 33;
  return *n ? &fake_devs[id - 31] : NULL;
}

static void fake_free(WinXIDevice* d) {
}

static void fake_transform(Display* dpy, XID p, BendRenderTransform* t) {
}

static void fake_xi(BendWin* win, int type, int dev, int detail, double x,
  double y, u32 ms, f32* dx, f32* dy) {
  unsigned char mask = 0;
  WinXIEvent ev = { .h = { .evtype = type, .serial = 1, .time = ms,
    .sourceid = dev, .detail = detail, .event_x = x, .event_y = y },
    .vals = { 1, &mask, NULL } };
  XGenericEventCookie c = { .evtype = type, .data = &ev };
  window_xi_event(win, &c, dx, dy);
}

Term fake_run(Env e, Term* f, IoWork* w) {
  BendWin* win = (BendWin*)(uintptr_t)io_hand_v(f[0]);
  BendWin  was = *win;
  WinXIDevice* (*query)(Display*, int, int*) = window_xi_query;
  void         (*drop)(WinXIDevice*)          = window_xi_free;
  void (*transform)(Display*, XID, BendRenderTransform*) =
    window_render.transform;
  f32      dx  = 0, dy = 0;
  fake_force   = (WinXIClass){ XIValuatorClass, 33, 2,
    XInternAtom(win->dpy, "Abs Pressure", False), 0, 1000 };
  fake_devs[0] = (WinXIDevice){ 31, "fake", 0, 0, True, 0, NULL };
  fake_devs[1] = (WinXIDevice){ 32, "fake", 0, 0, True, 1, fake_of };
  fake_devs[2] = (WinXIDevice){ 33, "fake", 0, 0, True, 1, fake_of + 1 };
  window_xi_query         = fake_query;
  window_xi_free          = fake_free;
  window_render.transform = fake_transform;
  win->nd       = 0;
  win->width    = 256;
  win->height   = 256;
  win->full_now = true;
  win->source   = 1;
  window_viewport(win);
  fake_xi(win, XI_Motion, 31, 0, 128, 160, FAKE_T + 1, &dx, &dy);
  fake_xi(win, XI_Motion, 31, 0, 128, 10, FAKE_T + 2, &dx, &dy);
  fake_xi(win, XI_ButtonPress, 31, 1, 128, 10, FAKE_T + 3, &dx, &dy);
  fake_xi(win, XI_Motion, 31, 0, 64, 96, FAKE_T + 4, &dx, &dy);
  fake_xi(win, XI_ButtonPress, 31, 1, 64, 96, FAKE_T + 5, &dx, &dy);
  fake_xi(win, XI_ButtonRelease, 31, 1, 64, 10, FAKE_T + 6, &dx, &dy);
  fake_xi(win, XI_TouchBegin, 32, 7, 128, 10, FAKE_T + 7, &dx, &dy);
  fake_xi(win, XI_TouchBegin, 32, 8, 128, 160, FAKE_T + 8, &dx, &dy);
  fake_xi(win, XI_TouchEnd, 32, 8, 128, 160, FAKE_T + 9, &dx, &dy);
  fake_xi(win, XI_Motion, 33, 0, 128, 160, FAKE_T + 10, &dx, &dy);
  fake_xi(win, XI_Motion, 33, 0, 128, 10, FAKE_T + 11, &dx, &dy);
  fake_xi(win, XI_Motion, 33, 0, 128, 20, FAKE_T + 12, &dx, &dy);
  win->grab        = 1;
  win->mouse_x     = 128;
  win->mouse_y     = 128;
  win->warp_serial = 0;
  win->warp_floor  = 0;
  fake_xi(win, XI_Motion, 31, 0, 168, 108, FAKE_T + 13, &dx, &dy);
  window_look_push(win, dx, dy);
  WinQueue q = win->q;
  *win = was;
  win->q = q;
  window_xi_query         = query;
  window_xi_free          = drop;
  window_render.transform = transform;
  return io_tup(e, f[0], io_str(e, "x11", 3));
}

#else

Term fake_run(Env e, Term* f, IoWork* w) {
  return io_tup(e, f[0], io_str(e, "", 0));
}

#endif

static void __attribute__((constructor)) fake_use(void) {
  io_eff(CID(fake), fake_run);
}
