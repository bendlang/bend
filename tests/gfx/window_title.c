// bend-ids 1
// CID :title BEND_CID_title
// bend-ids end
Term title_run(Env e, Term* f, IoWork* w) {
#ifdef __OBJC__
  NSWindow* win = (__bridge NSWindow*)(void*)(uintptr_t)io_hand_v(f[0]);
  const char* text = win.title.UTF8String;
  return io_tup(e, f[0], io_str(e, text, strlen(text)));
#elif defined(__linux__)
  BendWin* win = (BendWin*)(uintptr_t)io_hand_v(f[0]);
  Atom           type;
  int            fmt;
  unsigned long  n = 0, left;
  unsigned char* text = NULL;
  XGetWindowProperty(win->dpy, win->win,
    XInternAtom(win->dpy, "_NET_WM_NAME", False), 0, 1 << 16, False,
    XInternAtom(win->dpy, "UTF8_STRING", False), &type, &fmt, &n, &left,
    &text);
  Term got = io_str(e, text == NULL ? "" : (char*)text, text == NULL ? 0 : n);
  if (text != NULL) {
    XFree(text);
  }
  return io_tup(e, f[0], got);
#else
  return io_tup(e, f[0], io_str(e, "", 0));
#endif
}

static void __attribute__((constructor)) title_use(void) {
  io_eff(BEND_CID_title, title_run);
}
