// Window
// ======

// All window effects share this source; each entry is present only when
// its effect is reachable.

// An event: its constructor's id, then its fields as the compiler lays
// them out (a Tool inline, as its tag and five words).
#define WIN_EV 12

// a Press's words
enum { WIN_TAG = 2, WIN_BUTTON = 10, WIN_DOWN = 11 };

// A Tool's tag
enum { WIN_MOUSE, WIN_FINGER, WIN_PEN };

typedef struct {
  u32 tag;
  f32 v[5];
} WinTool;

// A window's events since its last frame, and what they leave held: per
// pointer id (the mouse 0, the others 1 to 15) its system name and buttons
// down, the ids live (the mouse while over the window), the keys down and
// the focus.
typedef struct {
  u32* evs;
  u32  n;
  u32  cap;
  u64  name[16];
  u32  down[16];
  u32  live;
  u32  keys[32];
  u32  nk;
  bool focus;
} WinQueue;

#ifdef __OBJC__

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

#elif defined(__linux__)

#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>
#include <dlfcn.h>
#include <langinfo.h>
#include <locale.h>

// The X11 window: its own connection (so its queue holds only its
// events), its input method and context (NULL if none opened), the
// time and code of the last key the method took, the frame's image,
// its events, whether it holds the pointer and the display's refresh
// period in ns.
typedef struct {
  Display* dpy;
  Window   win;
  XIM      im;
  XIC      ic;
  Time     kt;
  u32      kc;
  Atom     del;
  XImage*  img;
  WinQueue q;
  u32      grab;
  u64      period;
} BendWin;

// Names the window in UTF-8: _NET_WM_NAME, which window managers show,
// and WM_NAME, which XStoreName types Latin-1, for those that read only it.
static inline void window_x_title(Display* dpy, Window w, const char* text,
  u64 n) {
  XStoreName(dpy, w, text);
  XChangeProperty(dpy, w, XInternAtom(dpy, "_NET_WM_NAME", False),
    XInternAtom(dpy, "UTF8_STRING", False), 8, PropModeReplace,
    (const unsigned char*)text, (int)n);
}

#endif

#ifdef CID(Window.open)

#if defined(__OBJC__) || defined(__linux__)

// Typed text, from *at on, as the next Text event: up to 16 bytes of
// UTF-8 in its four words, cut between characters, so a long input
// method commit comes as several. Control characters and the Mac's
// function-key characters (U+F700 on) are keys, not text: dropped.
static inline bool window_chunk(const char* s, u64 n, u64* at,
  u32 ev[WIN_EV]) {
  char b[16] = { 0 };
  u32  k = 0;
  while (*at < n) {
    u8  c = (u8)s[*at];
    u32 l = c < 0x80 ? 1 : c < 0xE0 ? 2 : c < 0xF0 ? 3 : 4;
    u32 u = l == 1 ? c : c & (0x7F >> l);
    if (*at + l > n) {
      *at = n;
      break;
    }
    for (u32 i = 1; i < l; i += 1) {
      u = u << 6 | ((u8)s[*at + i] & 0x3F);
    }
    if (u >= 0x20 && (u < 0x7F || u >= 0xA0) && (u < 0xF700 || u >= 0xF900)) {
      if (k + l > sizeof b) {
        break;
      }
      memcpy(b + k, s + *at, l);
      k += l;
    }
    *at += l;
  }
  ev[0] = CID(Text);
  memcpy(ev + 1, b, sizeof b);
  return k > 0;
}

// The id of the pointer the system names name: the one it holds, else (if
// make) the least free, else 16 (none). The mouse's is 0, by its lane.
static inline u32 window_id(WinQueue* q, u64 name, bool make) {
  u32 free = 16;
  for (u32 i = 15; i > 0; i -= 1) {
    if (!(q->live >> i & 1)) {
      free = i;
    } else if (q->name[i] == name) {
      return i;
    }
  }
  if (!make || free == 16) {
    return 16;
  }
  q->name[free] = name;
  q->live |= 1u << free;
  return free;
}

// Whether ev goes out, as it updates q: a Key or Press up of nothing down,
// an event of an id not live (or none) and a Focus that changes nothing do
// not. A Press or Move makes its id live, a finger's last Press up or a
// Lost frees it.
static inline bool window_keep(WinQueue* q, const u32* ev) {
  u32 c = ev[0];
  u32 a = ev[1];
  if (c == CID(Key)) {
    u32 i = 0;
    while (i < q->nk && q->keys[i] != a) {
      i += 1;
    }
    if (ev[2] && i == q->nk && i < 32) {
      q->keys[q->nk++] = a;
    } else if (!ev[2] && i == q->nk) {
      return false;
    } else if (!ev[2]) {
      q->keys[i] = q->keys[--q->nk];
    }
    return true;
  }
  if (c == CID(Focus)) {
    bool was = q->focus;
    q->focus = a;
    return was != a;
  }
  if (c != CID(Press) && c != CID(Move) && c != CID(Lost)) {
    return true;
  }
  if (a >= 16 || (c == CID(Lost) && !(q->live >> a & 1))) {
    return false;
  }
  u32 m = 1u << a;
  u32 b = c == CID(Press) ? 1u << (ev[WIN_BUTTON] & 31) : 0;
  if (c == CID(Lost)) {
    q->live &= ~m;
    q->down[a] = 0;
    return true;
  }
  if (c == CID(Press) && !ev[WIN_DOWN]) {
    if (!(q->down[a] & b)) {
      return false;
    }
    q->down[a] &= ~b;
    if (ev[WIN_TAG] == WIN_FINGER && q->down[a] == 0) {
      q->live &= ~m;
    }
    return true;
  }
  q->down[a] |= b;
  q->live |= m;
  return true;
}

static inline void window_put(WinQueue* q, const u32* ev) {
  if (!window_keep(q, ev)) {
    return;
  }
  if (q->n == q->cap) {
    q->cap = q->cap == 0 ? 64 : q->cap * 2;
    q->evs = io_mem(realloc(q->evs, q->cap * WIN_EV * sizeof *ev));
  }
  memcpy(q->evs + q->n * WIN_EV, ev, WIN_EV * sizeof *ev);
  q->n += 1;
}

static inline void window_push(WinQueue* q, u32 cid, u32 a, u32 b, u32 c,
  u32 d) {
  u32 ev[WIN_EV] = { cid, a, b, c, d };
  window_put(q, ev);
}

// A Press, or a Move (which ends before b).
static inline void window_point(WinQueue* q, u32 cid, u32 id, WinTool t,
  f32 x, f32 y, u32 b, bool down) {
  u32 ev[WIN_EV] = { cid, id, t.tag, f32_rewrap(t.v[0]), f32_rewrap(t.v[1]),
    f32_rewrap(t.v[2]), f32_rewrap(t.v[3]), f32_rewrap(t.v[4]),
    f32_rewrap(x), f32_rewrap(y), b, down };
  window_put(q, ev);
}

// A Scroll, Zoom or Swipe at (x, y), by a and b, of n fingers.
static inline void window_delta(WinQueue* q, u32 cid, f32 x, f32 y, f32 a,
  f32 b, u32 n) {
  u32 ev[WIN_EV] = { cid, f32_rewrap(x), f32_rewrap(y), f32_rewrap(a),
    f32_rewrap(b), n };
  window_put(q, ev);
}

// The focus come, or gone: then it first loses the pointers pressed and
// lets go of the keys held.
static inline void window_focus(WinQueue* q, bool on) {
  for (u32 i = 0; !on && i < 16; i += 1) {
    if (q->down[i] != 0) {
      window_push(q, CID(Lost), i, 0, 0, 0);
    }
  }
  while (!on && q->nk > 0) {
    window_push(q, CID(Key), q->keys[q->nk - 1], false, 0, 0);
  }
  window_push(q, CID(Focus), on, 0, 0, 0);
}

#endif

#ifdef __OBJC__

// The view takes typed text as the Mac's text input client: keys go
// through the input method, and its commits come to insertText as Text.
// It draws no composition: marked holds it only so the method can work.
@interface BendView : NSView <NSWindowDelegate, NSTextInputClient> {
  @public
  NSMutableData* evs;
  u64            flags;
  BOOL           grab;
  NSString*      marked;
  NSMutableArray* held;
  BOOL           other;
}
@end

@implementation BendView

- (CALayer*)makeBackingLayer {
  return [CAMetalLayer layer];
}

- (BOOL)acceptsFirstResponder {
  return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent*)ev {
  return YES;
}

- (BOOL)isFlipped {
  return YES;
}

- (void)push:(u32)cid a:(u32)a b:(u32)b c:(u32)c d:(u32)d {
  u32 ev[5] = { cid, a, b, c, d };
  [evs appendBytes:ev length:sizeof ev];
}

- (void)key:(NSEvent*)ev down:(BOOL)down {
  NSString* s = [ev.charactersIgnoringModifiers lowercaseString];
  u32 code = s.length > 0 ? [s characterAtIndex:0] : 65536 + ev.keyCode;
  [self push:CID(Key) a:code b:down c:0 d:0];
}

- (void)keyDown:(NSEvent*)ev {
  [self key:ev down:YES];
  if (ev.modifierFlags & NSEventModifierFlagCommand) {
    return;
  }
  BOOL fresh = marked.length == 0;
  held  = [NSMutableArray new];
  other = NO;
  [self interpretKeyEvents:@[ev]];
  // An input method (Korean, Vietnamese) can commit the first key a view
  // gets bare, where it should start composing; asked again, it composes.
  NSString* t = held.count == 1 ? held[0] : nil;
  if (fresh && !other && !ev.ARepeat && t.length == 1
    && ![self.inputContext.selectedKeyboardInputSource
      hasPrefix:@"com.apple.keylayout."]) {
    [held removeAllObjects];
    [self interpretKeyEvents:@[ev]];
  }
  NSArray* ts = held;
  held = nil;
  for (NSString* h in ts) {
    [self insertText:h replacementRange:NSMakeRange(NSNotFound, 0)];
  }
}

- (void)insertText:(id)s replacementRange:(NSRange)r {
  marked = nil;
  if (held != nil) {
    [held addObject:[s isKindOfClass:NSAttributedString.class] ? [s string]
      : [s copy]];
    return;
  }
  const char* t = [([s isKindOfClass:NSAttributedString.class] ? [s string]
    : s) UTF8String];
  u64 n  = strlen(t);
  u64 at = 0;
  u32 ev[5];
  while (window_chunk(t, n, &at, ev)) {
    [evs appendBytes:ev length:sizeof ev];
  }
}

- (void)doCommandBySelector:(SEL)sel {
  other = YES;
}

- (void)setMarkedText:(id)s selectedRange:(NSRange)sel
  replacementRange:(NSRange)r {
  other  = YES;
  marked = [[s isKindOfClass:NSAttributedString.class] ? [s string] : s
    copy];
}

- (void)unmarkText {
  other  = YES;
  marked = nil;
}

- (BOOL)hasMarkedText {
  return marked.length > 0;
}

- (NSRange)markedRange {
  return marked.length > 0 ? NSMakeRange(0, marked.length)
    : NSMakeRange(NSNotFound, 0);
}

- (NSRange)selectedRange {
  return NSMakeRange(NSNotFound, 0);
}

- (NSArray<NSAttributedStringKey>*)validAttributesForMarkedText {
  return @[];
}

- (NSAttributedString*)attributedSubstringForProposedRange:(NSRange)r
  actualRange:(NSRangePointer)actual {
  return nil;
}

- (NSUInteger)characterIndexForPoint:(NSPoint)p {
  return NSNotFound;
}

// With no caret, the candidate list goes at the view's bottom left.
- (NSRect)firstRectForCharacterRange:(NSRange)r
  actualRange:(NSRangePointer)actual {
  NSRect v = [self convertRect:self.bounds toView:nil];
  return [self.window convertRectToScreen:NSMakeRect(NSMinX(v), NSMinY(v), 0,
    0)];
}

- (void)keyUp:(NSEvent*)ev {
  [self key:ev down:NO];
}

- (void)flagsChanged:(NSEvent*)ev {
  u64 now = ev.modifierFlags;
  [self push:CID(Key) a:65536 + ev.keyCode b:(now & ~flags) != 0 c:0
    d:0];
  flags = now;
}

- (NSPoint)at:(NSEvent*)ev {
  CGSize  size = ((CAMetalLayer*)self.layer).drawableSize;
  NSPoint p    = [self convertPoint:ev.locationInWindow fromView:nil];
  return NSMakePoint(fmax(0, fmin(floor(p.x), size.width - 1)),
    fmax(0, fmin(floor(p.y), size.height - 1)));
}

- (void)mouse:(NSEvent*)ev down:(BOOL)down {
  NSPoint p = [self at:ev];
  [self push:CID(Mouse) a:p.x b:p.y c:(u32)ev.buttonNumber d:down];
}

- (void)move:(NSEvent*)ev {
  NSPoint p = [self at:ev];
  if (grab) {
    [self push:CID(Look) a:f32_rewrap(ev.deltaX) b:f32_rewrap(ev.deltaY)
      c:0 d:0];
  } else {
    [self push:CID(Move) a:p.x b:p.y c:0 d:0];
  }
}

- (void)scrollWheel:(NSEvent*)ev {
  NSPoint p = [self at:ev];
  [self push:CID(Scroll) a:p.x b:p.y c:f32_rewrap(ev.scrollingDeltaX)
    d:f32_rewrap(ev.scrollingDeltaY)];
}

// Window.grab sets this by key: the cursor is hidden and held at the
// window's centre, and only a focused window takes it.
- (void)setGrab:(BOOL)on {
  if (on == grab || (on && !self.window.isKeyWindow)) {
    return;
  }
  grab = on;
  if (on) {
    NSRect r = [self.window convertRectToScreen:self.frame];
    CGWarpMouseCursorPosition(CGPointMake(NSMidX(r),
      NSMaxY(NSScreen.screens[0].frame) - NSMidY(r)));
    [NSCursor hide];
  } else {
    [NSCursor unhide];
  }
  CGAssociateMouseAndMouseCursorPosition(!on);
}

- (void)windowDidResignKey:(NSNotification*)note {
  [self setGrab:NO];
}

- (void)mouseDown:(NSEvent*)ev {
  [self mouse:ev down:YES];
}

- (void)mouseUp:(NSEvent*)ev {
  [self mouse:ev down:NO];
}

- (void)rightMouseDown:(NSEvent*)ev {
  [self mouse:ev down:YES];
}

- (void)rightMouseUp:(NSEvent*)ev {
  [self mouse:ev down:NO];
}

- (void)otherMouseDown:(NSEvent*)ev {
  [self mouse:ev down:YES];
}

- (void)otherMouseUp:(NSEvent*)ev {
  [self mouse:ev down:NO];
}

- (void)mouseMoved:(NSEvent*)ev {
  [self move:ev];
}

- (void)mouseDragged:(NSEvent*)ev {
  [self move:ev];
}

- (void)rightMouseDragged:(NSEvent*)ev {
  [self move:ev];
}

- (void)otherMouseDragged:(NSEvent*)ev {
  [self move:ev];
}

- (BOOL)windowShouldClose:(NSWindow*)sender {
  [self push:CID(Close) a:0 b:0 c:0 d:0];
  return NO;
}

@end

static id<MTLDevice> window_dev;

static u32 window_make(const char* title, u32 w, u32 h, intptr_t* out,
  const char** why) {
  if (w < 1 || h < 1 || w > 16384 || h > 16384) {
    return EINVAL;
  }
  if (NSScreen.screens.count == 0) {
    *why = "Window.open: no display (build a native binary with bend <file> -o <out> and run it from a desktop session)";
    return ENOTSUP;
  }
  if (window_dev == nil) {
    window_dev = gpu_buf != nil ? gpu_dev : MTLCreateSystemDefaultDevice();
  }
  if (window_dev == nil) {
    *why = "Window.open: no Metal device";
    return ENXIO;
  }
  if (NSApp == nil) {
    [NSApplication sharedApplication];
    NSApp.activationPolicy = NSApplicationActivationPolicyRegular;
    [NSApp finishLaunching];
  }
  @autoreleasepool {
    NSWindow* win = [[NSWindow alloc]
      initWithContentRect:NSMakeRect(0, 0, 1, 1)
      styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable
        | NSWindowStyleMaskMiniaturizable
      backing:NSBackingStoreBuffered defer:NO];
    win.releasedWhenClosed = NO;
    win.acceptsMouseMovedEvents = YES;
    win.title = [NSString stringWithUTF8String:title];
    [win setContentSize:NSMakeSize(w, h)];
    BendView* view = [[BendView alloc] initWithFrame:win.contentLayoutRect];
    view->evs   = [NSMutableData new];
    view->flags = NSEvent.modifierFlags;
    view.wantsLayer = YES;
    CAMetalLayer* layer = (CAMetalLayer*)view.layer;
    layer.device = window_dev;
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    layer.framebufferOnly = NO;
    layer.drawableSize = CGSizeMake(w, h);
    layer.displaySyncEnabled = YES;
    layer.maximumDrawableCount = 2;
    win.contentView = view;
    win.delegate = view;
    [win makeFirstResponder:view];
    [win center];
    [win makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    *out = (intptr_t)CFBridgingRetain(win);
  }
  return 0;
}

#elif defined(__linux__)

// The display's refresh period in ns: the rate RandR reports, through a
// libXrandr loaded at run time (a build needs no libxrandr-dev), else
// 60 Hz, as under a display that reports none or has no RandR (asked
// first: libXrandr faults on a server without it). The library stays
// loaded: it hooks the connection's close.
static u64 window_period(Display* dpy) {
  int op, ev, er;
  void* xrr = XQueryExtension(dpy, "RANDR", &op, &ev, &er)
    ? dlopen("libXrandr.so.2", RTLD_LAZY | RTLD_LOCAL) : NULL;
  if (xrr == NULL) {
    return 16666667;
  }
  void* (*info)(Display*, Window) =
    (void* (*)(Display*, Window))dlsym(xrr, "XRRGetScreenInfo");
  short (*rate)(void*) = (short (*)(void*))dlsym(xrr, "XRRConfigCurrentRate");
  void (*done)(void*) = (void (*)(void*))dlsym(xrr, "XRRFreeScreenConfigInfo");
  void* cfg = info && rate && done ? info(dpy, DefaultRootWindow(dpy)) : NULL;
  short hz  = cfg != NULL ? rate(cfg) : 0;
  if (cfg != NULL) {
    done(cfg);
  }
  return hz >= 24 && hz <= 1000 ? 1000000000 / (u64)hz : 16666667;
}

// The input method XMODIFIERS names (as ibus or fcitx), else Xlib's own
// (dead keys and Compose), under the user's locale, or C.UTF-8 if its
// characters are not UTF-8 (Xlib mangles composed text there). Xlib
// takes the locale here; the program's stays as it was. With no method,
// Text comes from the key's symbol.
static void window_ime(BendWin* win) {
  char* was = io_mem(strdup(setlocale(LC_CTYPE, NULL)));
  setlocale(LC_CTYPE, "");
  if (strcmp(nl_langinfo(CODESET), "UTF-8") != 0) {
    setlocale(LC_CTYPE, "C.UTF-8");
  }
  if (XSupportsLocale()) {
    XSetLocaleModifiers("");
    win->im = XOpenIM(win->dpy, NULL, NULL, NULL);
    if (win->im == NULL) {
      XSetLocaleModifiers("@im=none");
      win->im = XOpenIM(win->dpy, NULL, NULL, NULL);
    }
  }
  setlocale(LC_CTYPE, was);
  free(was);
  win->ic = win->im == NULL ? NULL : XCreateIC(win->im, XNInputStyle,
    XIMPreeditNothing | XIMStatusNothing, XNClientWindow, win->win,
    XNFocusWindow, win->win, NULL);
  if (win->ic == NULL && win->im != NULL) {
    XCloseIM(win->im);
    win->im = NULL;
  }
}

static u32 window_make(const char* title, u32 w, u32 h, intptr_t* out,
  const char** why) {
  if (w < 1 || h < 1 || w > 16384 || h > 16384) {
    return EINVAL;
  }
  Display* dpy = XOpenDisplay(NULL);
  if (dpy == NULL) {
    *why = "Window.open: no display (build a native binary with bend <file> -o <out> and run it from a desktop session)";
    return ENOTSUP;
  }
  int scr = DefaultScreen(dpy);
  if (DefaultDepth(dpy, scr) < 24) {
    XCloseDisplay(dpy);
    *why = "Window.open: the display has no 24-bit visual";
    return ENOTSUP;
  }
  BendWin* win = io_mem(calloc(1, sizeof *win));
  win->dpy = dpy;
  win->period = window_period(dpy);
  win->win = XCreateSimpleWindow(dpy, RootWindow(dpy, scr), 0, 0, w, h, 0, 0,
    BlackPixel(dpy, scr));
  window_ime(win);
  long im_evs = 0;
  if (win->ic != NULL) {
    XGetICValues(win->ic, XNFilterEvents, &im_evs, NULL);
  }
  win->del = XInternAtom(dpy, "WM_DELETE_WINDOW", False);
  win->img = XCreateImage(dpy, DefaultVisual(dpy, scr), DefaultDepth(dpy, scr),
    ZPixmap, 0, io_mem(calloc(w * h, 4)), w, h, 32, w * 4);
  win->img->byte_order = LSBFirst;
  XSizeHints hints = { .flags = PMinSize | PMaxSize, .min_width = w,
    .min_height = h, .max_width = w, .max_height = h };
  XSetWMNormalHints(dpy, win->win, &hints);
  XSetWMProtocols(dpy, win->win, &win->del, 1);
  window_x_title(dpy, win->win, title, strlen(title));
  XSelectInput(dpy, win->win, KeyPressMask | KeyReleaseMask | ButtonPressMask
    | ButtonReleaseMask | PointerMotionMask | LeaveWindowMask | FocusChangeMask
    | im_evs);
  XMapRaised(dpy, win->win);
  XFlush(dpy);
  *out = (intptr_t)win;
  return 0;
}

#else

static u32 window_make(const char* title, u32 w, u32 h, intptr_t* out,
  const char** why) {
  *why = "Window.open: no display (build a native binary with bend <file> -o <out> and run it from a desktop session)";
  return ENOTSUP;
}

#endif

Term window_open_run(Env e, Term* f, IoWork* w) {
  uint64_t n = 0;
  char* title = io_cstr(e, f[0], &n);
  intptr_t out;
  const char* why = NULL;
  u32 q = io_nul(title, n) ? EILSEQ
    : window_make(title, (u32)f[1], (u32)f[2], &out, &why);
  free(title);
  if (q != 0) {
    return io_fail(e, q, why);
  }
  return io_done(e, io_hand(out));
}

static void __attribute__((constructor)) window_open_use(void) {
  io_eff(CID(Window.open), window_open_run);
}

#endif

#ifdef CID(Window.frame)

// A frame answers the events pumped since the last one; a constructor of
// one word packs it in its term, as the compiler builds it.
#if defined(__OBJC__) || defined(__linux__)

static Term window_node(Env e, const u32* ev) {
  if (ev[0] == CID(Text)) {
    const char* s = (const char*)(ev + 1);
    return io_box(e, CID(Text), io_str(e, s, strnlen(s, 16)));
  }
  u32 n = cid_arity(ev[0]);
  if (n <= 1) {
    return term_pak(ev[0], n == 0 ? 0 : ev[1]);
  }
  u64 l = heap_alloc(e, cls_fit(n));
  for (u32 j = 0; j < n; j += 1) {
    e.mem[l + j] = ev[1 + j];
  }
  return term_ctr(ev[0], l);
}

static u32 window_depth(u32 n) {
  return n > 1 ? 32 - CLZ(n - 1) : 0;
}

static Term window_list(Env e, const u32* p, u64 n) {
  Term list = term_pak(CID(Nil), 0);
  for (u64 i = n; i > 0; i -= 1) {
    list = io_node(e, CID(Con), window_node(e, p + WIN_EV * (i - 1)), list);
  }
  return list;
}

#endif

#ifdef __OBJC__

#define WIN_STR_(x) #x
#define WIN_STR(x)  WIN_STR_(x)
#define WIN_DEF(m)  "#define " #m " " WIN_STR(m) "\n"

typedef struct {
  u64 root;
  u32 w;
  u32 h;
  u32 k;
} WinArgs;

static id<MTLCommandQueue>         window_que;
static id<MTLBuffer>               window_buf;
static id<MTLComputePipelineState> window_pso;
static u64                         window_len;

static const char* window_msl =
  "#include <metal_stdlib>\n"
  "using namespace metal;\n"
  WIN_DEF(TAG_CTR)
  WIN_DEF(RFC_BIT)
  WIN_DEF(LOC_MASK)
  "struct Args { ulong root; uint w; uint h; uint k; };\n"
  "ulong node(device const ulong* mem, ulong t) {\n"
  "  return t & RFC_BIT ? mem[t & LOC_MASK] >> 24 : t & LOC_MASK;\n"
  "}\n"
  "kernel void window_dev(device const ulong* mem [[buffer(0)]],\n"
  "  constant Args& a [[buffer(1)]],\n"
  "  texture2d<float, access::write> out [[texture(0)]],\n"
  "  uint2 p [[thread_position_in_grid]]) {\n"
  "  ulong t = a.root;\n"
  "  for (uint i = a.k; ((t >> 56) & 0x7f) == TAG_CTR;) {\n"
  "    uint j = 0;\n"
  "    if (i > 0) {\n"
  "      i -= 1;\n"
  "      j = ((p.y >> i) & 1) * 2 + ((p.x >> i) & 1);\n"
  "    }\n"
  "    t = mem[node(mem, t) + j];\n"
  "  }\n"
  "  float4 c = unpack_unorm4x8_to_float(uint(t & LOC_MASK));\n"
  "  out.write(float4(c.zyx, 1.0), p);\n"
  "}\n";

static void window_pipe(id<MTLDevice> dev) {
  if (window_pso != nil) {
    return;
  }
  window_que = gpu_buf != nil ? gpu_que : [dev newCommandQueue];
  NSError* err = nil;
  id<MTLLibrary> lib = [dev
    newLibraryWithSource:[NSString stringWithUTF8String:window_msl]
    options:nil error:&err];
  if (lib == nil) {
    err_fail(err.localizedDescription.UTF8String);
  }
  window_pso = [dev newComputePipelineStateWithFunction:
    [lib newFunctionWithName:@"window_dev"] error:&err];
  if (window_pso == nil) {
    err_fail(err.localizedDescription.UTF8String);
  }
}

// Waits for done inside the run loop, dispatching the events as they
// come: the window server's work on this thread (a title-bar drag) runs
// while the frame waits, not a frame later.
static void window_wait(bool* done) {
  for (;;) {
    @autoreleasepool {
      NSEvent* ev = [NSApp nextEventMatchingMask:NSEventMaskAny
        untilDate:NSDate.distantPast inMode:NSDefaultRunLoopMode dequeue:YES];
      if (ev != nil) {
        [NSApp sendEvent:ev];
      } else if (*done) {
        return;
      } else {
        [NSRunLoop.currentRunLoop runMode:NSDefaultRunLoopMode
          beforeDate:NSDate.distantFuture];
      }
    }
  }
}

static id<MTLBuffer> window_corpus(Env e, id<MTLDevice> dev) {
  if (gpu_buf != nil) {
    return gpu_buf;
  }
  u64 bump = a32_load(a32_at(e.mem, H_BUMP));
  u64 need = ((HEAP_OFF + (bump << PAGE_BITS)) * 8 + 16383) & ~16383ull;
  if (need > window_len) {
    u64 most = [dev maxBufferLength] & ~16383ull;
    if (need > most) {
      err_fail("the frame's memory is past the Metal buffer limit");
    }
    u64 len = window_len * 2 > need ? window_len * 2 : need;
    len = len < most ? len : most;
    window_buf = [dev newBufferWithBytesNoCopy:e.mem length:len
      options:MTLResourceStorageModeShared
        | MTLResourceHazardTrackingModeUntracked deallocator:nil];
    if (window_buf == nil) {
      err_fail("the corpus prefix does not map as a Metal buffer");
    }
    window_len = len;
  }
  return window_buf;
}

static void window_show(Env e, CAMetalLayer* layer, Term image) {
  id<MTLDevice> dev = layer.device;
  window_pipe(dev);
  id<MTLBuffer> buf = window_corpus(e, dev);
  WinArgs args = { image, layer.drawableSize.width, layer.drawableSize.height,
    0 };
  args.k = window_depth(args.w > args.h ? args.w : args.h);
  __block bool done = false;
  id<MTLCommandBuffer> cb = [window_que commandBuffer];
  // nextDrawable blocks until the display frees one: on a helper thread
  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), ^{
    @autoreleasepool {
      id<CAMetalDrawable> d = [layer nextDrawable];
      if (d != nil) {
        id<MTLComputeCommandEncoder> enc = [cb computeCommandEncoder];
        NSUInteger tw = window_pso.threadExecutionWidth;
        [enc setComputePipelineState:window_pso];
        [enc setBuffer:buf offset:0 atIndex:0];
        [enc setBytes:&args length:sizeof(args) atIndex:1];
        [enc setTexture:d.texture atIndex:0];
        [enc dispatchThreads:MTLSizeMake(args.w, args.h, 1)
          threadsPerThreadgroup:MTLSizeMake(tw,
            window_pso.maxTotalThreadsPerThreadgroup / tw, 1)];
        [enc endEncoding];
        [cb presentDrawable:d];
        [cb commit];
        [cb waitUntilCompleted];
      }
      dispatch_async(dispatch_get_main_queue(), ^{
        done = true;
        CFRunLoopStop(CFRunLoopGetMain());
      });
    }
  });
  window_wait(&done);
  if (cb.error != nil) {
    err_fail(cb.error.localizedDescription.UTF8String);
  }
}

static Term window_frame(Env e, intptr_t at, Term image) {
  NSView*        view = ((__bridge NSWindow*)(void*)at).contentView;
  NSMutableData* evs  = [view valueForKey:@"evs"];
  io_sync();
  window_show(e, (CAMetalLayer*)view.layer, image);
  Term list = window_list(e, evs.bytes, evs.length / 20);
  evs.length = 0;
  return list;
}

#elif defined(__linux__)

// The Mac's key codes: a key's character in lower case (Escape, Return
// and Tab are theirs), the function keys' private-use characters (the
// arrows at 63232), a modifier's 65536 + its key code.
static const u32 window_keys[][2] = {
  { XK_BackSpace, 127 },   { XK_Up,        63232 }, { XK_Down,      63233 },
  { XK_Left,      63234 }, { XK_Right,     63235 }, { XK_Insert,    63271 },
  { XK_Delete,    63272 }, { XK_Home,      63273 }, { XK_End,       63275 },
  { XK_Page_Up,   63276 }, { XK_Page_Down, 63277 }, { XK_Super_R,   65590 },
  { XK_Super_L,   65591 }, { XK_Shift_L,   65592 }, { XK_Caps_Lock, 65593 },
  { XK_Alt_L,     65594 }, { XK_Control_L, 65595 }, { XK_Shift_R,   65596 },
  { XK_Alt_R,     65597 }, { XK_Control_R, 65598 }, { XK_ISO_Left_Tab, 25 },
};

static u32 window_key(XKeyEvent* ev) {
  char   c[8];
  KeySym ks = 0;
  ev->state &= ShiftMask | LockMask;
  int n = XLookupString(ev, c, sizeof c, &ks, NULL);
  for (u32 i = 0; i < sizeof window_keys / sizeof *window_keys; i += 1) {
    if (window_keys[i][0] == ks) {
      return window_keys[i][1];
    }
  }
  if (ks >= XK_F1 && ks <= XK_F12) {
    return 63236 + (u32)(ks - XK_F1);
  }
  if (n == 1) {
    return (u8)c[0] >= 'A' && (u8)c[0] <= 'Z' ? (u8)c[0] + 32 : (u8)c[0];
  }
  return 65536 + ev->keycode;
}

// A key press's text: what the input method commits, else (no method)
// the character of the key's symbol, unless Control is held.
static void window_text(BendWin* win, XKeyEvent* key) {
  char   buf[64];
  char*  s  = buf;
  int    n  = 0;
  KeySym ks = 0;
  Status st = XLookupNone;
  if (win->ic != NULL) {
    n = Xutf8LookupString(win->ic, key, s, sizeof buf, &ks, &st);
    if (st == XBufferOverflow) {
      s = io_mem(malloc(n));
      n = Xutf8LookupString(win->ic, key, s, n, &ks, &st);
    }
    if (st != XLookupChars && st != XLookupBoth) {
      n = 0;
    }
  } else if (!(key->state & ControlMask)) {
    XLookupString(key, buf, sizeof buf, &ks, NULL);
    u32 u = ks <= 0xFF ? (u32)ks
      : (ks & 0xFF000000) == 0x01000000 ? (u32)(ks & 0xFFFFFF) : 0;
    u32 l = u < 0x80 ? 1 : u < 0x800 ? 2 : u < 0x10000 ? 3 : 4;
    buf[0] = l == 1 ? u : (0xF00 >> l) | u >> 6 * (l - 1);
    for (u32 i = 1; i < l; i += 1) {
      buf[i] = 0x80 | (u >> 6 * (l - 1 - i) & 0x3F);
    }
    n = l;
  }
  u64 at = 0;
  u32 ev[WIN_EV];
  while (window_chunk(s, n, &at, ev)) {
    window_put(&win->q, ev);
  }
  if (s != buf) {
    free(s);
  }
}

// X buttons: 1 to 3 left, middle, right; 4 to 7 the wheel (up, down, left,
// right; a notch is 1, up and left positive); 8 and 9 back, forward.
static void window_button(BendWin* win, u32 id, WinTool t, f32 x, f32 y,
  u32 b, bool down) {
  f32 s = b % 2 ? -1 : 1;
  if (b >= 4 && b <= 7 && down) {
    window_delta(&win->q, CID(Scroll), x, y, b > 5 ? s : 0, b > 5 ? 0 : s,
      0);
  } else if (b <= 3 || b == 8 || b == 9) {
    window_point(&win->q, CID(Press), id, t, x, y,
      b <= 3 ? b - 1 : b - 5, down);
  }
}

// Off the window, a pointer is lost unless a button holds it; a grab
// elsewhere takes only a held one (its release then goes there).
static void window_leave(BendWin* win, u32 id, int mode) {
  bool held = id < 16 && win->q.down[id] != 0;
  if (held == (mode == NotifyGrab)) {
    window_push(&win->q, CID(Lost), id, 0, 0, 0);
  }
}

static void window_pump(BendWin* win) {
  int cx = win->img->width / 2;
  int cy = win->img->height / 2;
  int x  = cx;
  int y  = cy;
  while (XPending(win->dpy) > 0) {
    XEvent ev;
    XNextEvent(win->dpy, &ev);
    XKeyEvent key  = ev.xkey;
    bool      took = XFilterEvent(&ev, None);
    if (ev.type == KeyPress || ev.type == KeyRelease) {
      // Each key is a Key, even one the input method took (the event as
      // it came: Xlib's own method rewrites it). A method may hand a key
      // back at its time, the same Key, or bring text on key code 0.
      u32 code = key.keycode << 1 | (ev.type == KeyPress);
      if (key.keycode != 0
        && (took || key.time != win->kt || code != win->kc)) {
        window_push(&win->q, CID(Key), window_key(&key), ev.type == KeyPress,
          0, 0);
      }
      if (took) {
        win->kt = key.time;
        win->kc = code;
      } else if (ev.type == KeyPress) {
        window_text(win, &ev.xkey);
      }
    } else if (ev.type == ButtonPress || ev.type == ButtonRelease) {
      window_button(win, 0, (WinTool){ WIN_MOUSE }, ev.xbutton.x,
        ev.xbutton.y, ev.xbutton.button, ev.type == ButtonPress);
    } else if (ev.type == MotionNotify) {
      x = ev.xmotion.x;
      y = ev.xmotion.y;
      if (!win->grab) {
        window_point(&win->q, CID(Move), 0, (WinTool){ WIN_MOUSE }, x, y, 0,
          false);
      }
    } else if (ev.type == LeaveNotify) {
      window_leave(win, 0, ev.xcrossing.mode);
    } else if (ev.type == FocusIn || ev.type == FocusOut) {
      bool on = ev.type == FocusIn;
      if (win->ic != NULL && on) {
        XSetICFocus(win->ic);
      } else if (win->ic != NULL) {
        XUnsetICFocus(win->ic);
      }
      if (!on) {
        XUngrabPointer(win->dpy, CurrentTime);
        win->grab = 0;
      }
      bool follows = ev.xfocus.detail == NotifyPointer
        || ev.xfocus.detail == NotifyInferior;
      if (!follows) {
        window_focus(&win->q, on);
      }
    } else if (ev.type == ClientMessage
      && (Atom)ev.xclient.data.l[0] == win->del) {
      window_push(&win->q, CID(Close), 0, 0, 0, 0);
    }
  }
  // grabbed, the frame's motion is one look from the centre
  if (win->grab && (x != cx || y != cy)) {
    window_push(&win->q, CID(Look), f32_rewrap(x - cx), f32_rewrap(y - cy),
      0, 0);
    XWarpPointer(win->dpy, None, win->win, 0, 0, 0, 0, cx, cy);
  }
}

#if BEND_CUDA
static CUfunction  window_pso;
static CUdeviceptr window_buf;
static u64         window_len;
#endif

// The s x s square of t at (x, y) of the frame: a Qua by quarters,
// else the color window_pix reads at its corner.
static void window_sq(u64* H, u32* pix, u32 w, u32 h, Term t, u32 s, u32 x,
  u32 y) {
  if (x >= w || y >= h) {
    return;
  }
  if (s > 1 && term_tag(t) == TAG_CTR) {
    u64 l = term_peek(H, t);
    s /= 2;
    for (u32 j = 0; j < 4; j += 1) {
      window_sq(H, pix, w, h, H[l + j], s, x + j % 2 * s, y + j / 2 * s);
    }
    return;
  }
  u32 c = window_pix(H, t, 0, 0, 0);
  for (u32 i = y; i < h && i < y + s; i += 1) {
    for (u32 j = x; j < w && j < x + s; j += 1) {
      pix[i * w + j] = c;
    }
  }
}

// The frame's pixels: window_dev on the device while the corpus is
// there (the tree's pages never leave it), else window_sq from the root.
static void window_fill(Env e, u32* pix, u32 w, u32 h, Term image, u32 k) {
#if BEND_CUDA
  if (io_gpu) {
    u64*   H    = e.mem;
    u64    len  = (u64)w * h * 4;
    void*  args[] = { &H, &image, &w, &h, &k, &window_buf };
    if (window_pso == NULL && cuModuleGetFunction(&window_pso, gpu_lib,
      "window_dev") != CUDA_SUCCESS) {
      err_fail("cannot load the window kernel");
    }
    if (len > window_len) {
      if (window_buf != 0) {
        cuMemFree(window_buf);
      }
      if (cuMemAlloc(&window_buf, len) != CUDA_SUCCESS) {
        err_fail("the frame's device buffer failed");
      }
      window_len = len;
    }
    if (cuLaunchKernel(window_pso, (w + 31) / 32, (h + 7) / 8, 1, 32, 8, 1, 0,
      NULL, args, NULL) != CUDA_SUCCESS
      || cuMemcpyDtoH(pix, window_buf, len) != CUDA_SUCCESS) {
      err_fail("the frame's device fill failed");
    }
    return;
  }
#endif
  window_sq(e.mem, pix, w, h, image, 1u << k, 0, 0);
}

// A frame waits for the display's next tick, as the Mac's display sync.
static void window_pace(u64 period) {
  static u64 due;
  u64 now = io_tick();
  if (due > now) {
    struct timespec ts = { 0, (long)(due - now) };
    nanosleep(&ts, NULL);
  }
  due = (due > now ? due : now) + period;
}

static void window_show(Env e, BendWin* win, Term image) {
  u32 w = win->img->width;
  u32 h = win->img->height;
  u32 k = window_depth(w > h ? w : h);
  window_fill(e, (u32*)win->img->data, w, h, image, k);
  window_pace(win->period);
  XPutImage(win->dpy, win->win, DefaultGC(win->dpy, DefaultScreen(win->dpy)),
    win->img, 0, 0, 0, 0, w, h);
  XFlush(win->dpy);
}

static Term window_frame(Env e, intptr_t at, Term image) {
  BendWin* win = (BendWin*)at;
  io_sync();
  window_pump(win);
  window_show(e, win, image);
  Term list = window_list(e, win->q.evs, win->q.n);
  win->q.n = 0;
  return list;
}

#else

static Term window_frame(Env e, intptr_t at, Term image) {
  return term_pak(CID(Nil), 0);
}

#endif

Term window_frame_run(Env e, Term* f, IoWork* w) {
  Term events = window_frame(e, (intptr_t)io_hand_v(f[0]), f[1]);
  return io_tup(e, f[0], io_tup(e, f[1], events));
}

static void __attribute__((constructor)) window_frame_use(void) {
  io_eff(CID(Window.frame), window_frame_run);
}

#endif

#ifdef CID(Window.set_title)

#ifdef __OBJC__

static void window_set_title(intptr_t at, const char* text, u64 n) {
  NSWindow* win = (__bridge NSWindow*)(void*)at;
  win.title = [[NSString alloc] initWithBytes:text length:n
    encoding:NSUTF8StringEncoding];
}

#elif defined(__linux__)

static void window_set_title(intptr_t at, const char* text, u64 n) {
  BendWin* win = (BendWin*)at;
  window_x_title(win->dpy, win->win, text, n);
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
  io_eff(CID(Window.set_title), window_set_title_run);
}

#endif

#ifdef CID(Window.grab)

#ifdef __OBJC__

static void window_grab(intptr_t at, bool on) {
  NSWindow* win = (__bridge NSWindow*)(void*)at;
  [win.contentView setValue:@(on) forKey:@"grab"];
}

#elif defined(__linux__)

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
      XWarpPointer(win->dpy, None, win->win, 0, 0, 0, 0,
        win->img->width / 2, win->img->height / 2);
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
  io_eff(CID(Window.grab), window_grab_run);
}

#endif

#ifdef CID(Window.close)

#ifdef __OBJC__

static void window_close(intptr_t at) {
  NSWindow* win = CFBridgingRelease((void*)at);
  [win.contentView setValue:@NO forKey:@"grab"];
  [win close];
}

#elif defined(__linux__)

static void window_close(intptr_t at) {
  BendWin* win = (BendWin*)at;
  if (win->ic != NULL) {
    XDestroyIC(win->ic);
    XCloseIM(win->im);
  }
  XDestroyImage(win->img);
  XCloseDisplay(win->dpy);
  free(win->q.evs);
  free(win);
}

#else

static void window_close(intptr_t at) {
}

#endif

Term window_close_run(Env e, Term* f, IoWork* w) {
  window_close((intptr_t)io_hand_v(f[0]));
  return term_pak(CID(Unit), 0);
}

static void __attribute__((constructor)) window_close_use(void) {
  io_eff(CID(Window.close), window_close_run);
}

#endif
