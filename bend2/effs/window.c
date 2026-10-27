// Window
// ======

// All window effects share this source; each entry is present only when
// its effect is reachable.

// An event: its constructor's id, then its fields as the compiler lays
// them out (a Tool inline, as its tag and five words).
#define WIN_EV 13

// a Press's words
enum { WIN_TAG = 2, WIN_BUTTON = 11, WIN_DOWN = 12 };

// A Tool's tag
enum { WIN_MOUSE, WIN_FINGER, WIN_PEN };

typedef struct {
  u32 tag;
  f32 v[5];
} WinTool;

// A window's events since its last frame, and what they leave held: per pointer id (the mouse 0, the
// others 1 to 15) its system name and buttons down, the ids live (the
// mouse while over the window), the keys down and the focus.
typedef struct {
  u32*  evs;
  u32   n;
  u32   cap;
  u64   name[16];
  u32   down[16];
  u32   live;
  u32   keys[32];
  u32   nk;
  bool  focus;
} WinQueue;

#ifdef __OBJC__

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

#elif defined(__linux__)

#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>
#include <dlfcn.h>
#include <limits.h>
#include <langinfo.h>
#include <locale.h>

#ifdef CID(Window.fullscreen)
// XRender is loaded at run time, like RandR below: only Xlib headers are needed.
typedef struct {
  XID id;
  int type, depth;
  struct {
    short red, redMask, green, greenMask, blue, blueMask, alpha, alphaMask;
  } direct;
  Colormap colormap;
} BendRenderFormat;

typedef struct {
  int repeat;
  XID alpha_map;
  int alpha_x_origin, alpha_y_origin, clip_x_origin, clip_y_origin;
  Pixmap clip_mask;
  Bool graphics_exposures;
  int subwindow_mode, poly_edge, poly_mode;
  Atom dither;
  Bool component_alpha;
} BendRenderAttrs;

typedef struct {
  int matrix[3][3];
} BendRenderTransform;

enum {
  BEND_RENDER_SRC = 1,
  BEND_RENDER_REPEAT = 1,
  BEND_RENDER_PAD = 2
};
#endif

// XInput2's names and types, as XI2.h and XInput2.h have them (a build
// needs no libxi-dev). Device and leave (its mode at flags) events share
// the head.
#define XIAllDevices          0
#define XIAllMasterDevices    1
#define XI_ButtonPress        4
#define XI_ButtonRelease      5
#define XI_Motion             6
#define XI_Leave              8
#define XI_HierarchyChanged   11
#define XI_TouchBegin         18
#define XI_TouchUpdate        19
#define XI_TouchEnd           20
#define XIValuatorClass       2
#define XITouchClass          8
#define XIDirectTouch         1
#define XINotifyPassiveGrab   4
#define XISetMask(ptr, event) \
  (((unsigned char*)(ptr))[(event) >> 3] |= (1 << ((event) & 7)))

typedef struct {
  int            deviceid;
  int            mask_len;
  unsigned char* mask;
} WinXIMask;

typedef struct {
  int            type;
  unsigned long  serial;
  Bool           send_event;
  Display*       display;
  int            extension;
  int            evtype;
  Time           time;
  int            deviceid;
  int            sourceid;
  int            detail;
  Window         root;
  Window         event;
  Window         child;
  double         root_x;
  double         root_y;
  double         event_x;
  double         event_y;
} WinXIHead;

typedef struct {
  int            len;
  unsigned char* mask;
} WinXIBits;

typedef struct {
  int            len;
  unsigned char* mask;
  double*        values;
} WinXIVals;

typedef struct {
  WinXIHead      h;
  int            flags;
  WinXIBits      buttons;
  WinXIVals      vals;
} WinXIEvent;

// A device's class: a valuator's, whose number stands at a touch class's
// mode.
typedef struct {
  int            type;
  int            sourceid;
  int            number;
  Atom           label;
  double         min, max, value;
} WinXIClass;

typedef struct {
  int            deviceid;
  char*          name;
  int            use, attachment;
  Bool           enabled;
  int            num_classes;
  WinXIClass**   classes;
} WinXIDevice;

// A device met: its tool (a pen's contact is button 5 at its eraser),
// each axis's valuator (-1: none), range and last value (events carry only
// changes), and a touch screen's pixels per unit of position.
enum { WIN_FORCE, WIN_TILT_X, WIN_TILT_Y, WIN_MAJOR, WIN_MINOR, WIN_AXES };

typedef struct {
  int    id;
  u32    tool;
  bool   eraser;
  int    ax[WIN_AXES];
  double lo[WIN_AXES], hi[WIN_AXES], at[WIN_AXES];
  double px;
} WinDev;

// The X11 window: its own connection (so its queue holds only its
// events), its input method and context (NULL if none opened), the
// time and code of the last key the method took, the frame's image and
// the window's size, its events, its pointer grab and warp baseline, the
// display's refresh period in ns, XInput2's opcode (0 if none) and the
// devices met.
typedef struct {
  Display* dpy;
  Window   win;
  XIM      im;
  XIC      ic;
  Time     kt;
  u32      kc;
  Atom     del;
#ifdef CID(Window.fullscreen)
  Atom     state;
  Atom     full;
  bool     full_supported;
  bool     mapped;
  bool     full_sent;
  u64      full_due;
  Pixmap   pix;
  XID      source;
  XID      target;
  u32      vx, vy, vw, vh;
  f32      sx, sy;
  bool     full_now;
  bool     full_want;
  bool     full_wait;
#endif
  XImage*  img;
  u32      width;
  u32      height;
  WinQueue q;
  u32      grab;
  unsigned long warp_serial, warp_floor;
  int      mouse_x, mouse_y;
  u64      period;
  int      xi;
  u32      nd;
  WinDev   devs[8];
} BendWin;

// A grab or resize changes the basis; an ordinary recenter preserves queued input.
static void window_warp(BendWin* win, int x, int y, bool reset) {
  if (!reset && win->warp_serial) {
    return;
  }
  win->warp_serial = NextRequest(win->dpy);
  if (reset) {
    win->warp_floor = win->warp_serial;
    win->mouse_x = x;
    win->mouse_y = y;
  }
  XWarpPointer(win->dpy, None, win->win, 0, 0, 0, 0, x, y);
}

static void window_limits(BendWin* win, bool on) {
  u32 w = win->img->width, h = win->img->height;
  XSizeHints hints = { .flags = PMinSize | PMaxSize, .min_width = w,
    .min_height = h, .max_width = w, .max_height = h };
  if (on) {
    hints.flags = PMinSize;
    hints.min_width = hints.min_height = 1;
  }
  XSetWMNormalHints(win->dpy, win->win, &hints);
}

#ifdef CID(Window.fullscreen)
static struct {
  bool tried;
  BendRenderFormat* (*format)(Display*, Visual*);
  XID (*create)(Display*, Drawable, BendRenderFormat*, unsigned long,
    const BendRenderAttrs*);
  void (*destroy)(Display*, XID);
  void (*transform)(Display*, XID, BendRenderTransform*);
  void (*filter)(Display*, XID, const char*, int*, int);
  void (*composite)(Display*, int, XID, XID, XID,
    int, int, int, int, int, int, unsigned int, unsigned int);
} window_render;

static bool window_renderer(Display* dpy) {
  if (!window_render.tried) {
    window_render.tried = true;
    void* lib = dlopen("libXrender.so.1", RTLD_LAZY | RTLD_LOCAL);
    if (lib != NULL) {
      window_render.format = (__typeof__(window_render.format))dlsym(lib, "XRenderFindVisualFormat");
      window_render.create = (__typeof__(window_render.create))dlsym(lib, "XRenderCreatePicture");
      window_render.destroy = (__typeof__(window_render.destroy))dlsym(lib, "XRenderFreePicture");
      window_render.transform = (__typeof__(window_render.transform))dlsym(lib, "XRenderSetPictureTransform");
      window_render.filter = (__typeof__(window_render.filter))dlsym(lib, "XRenderSetPictureFilter");
      window_render.composite = (__typeof__(window_render.composite))dlsym(lib, "XRenderComposite");
    }
  }
  int op, ev, er;
  return window_render.format && window_render.create && window_render.destroy
    && window_render.transform && window_render.filter && window_render.composite
    && XQueryExtension(dpy, "RENDER", &op, &ev, &er);
}

static bool window_has_value(Display* dpy, Window at, Atom property, Atom kind,
  unsigned long value) {
  Atom type;
  int format;
  unsigned long n, rest;
  unsigned char* data = NULL;
  bool found = false;
  if (XGetWindowProperty(dpy, at, property, 0, INT_MAX, False, kind,
    &type, &format, &n, &rest, &data) == Success && type == kind && format == 32) {
    for (unsigned long i = 0; i < n; ++i) {
      found |= ((unsigned long*)data)[i] == value;
    }
  }
  XFree(data);
  return found;
}

static void window_viewport(BendWin* win) {
  u32 w = win->img->width, h = win->img->height;
  u32 vw = w, vh = h;
  bool full = win->full_now && win->source;
  if (full) {
    if ((u64)win->width * h <= (u64)win->height * w) {
      vw = win->width;
      vh = (u64)h * vw / w;
      vh = vh ? vh : 1;
    } else {
      vh = win->height;
      vw = (u64)w * vh / h;
      vw = vw ? vw : 1;
    }
  }
  win->vx = full ? (win->width - vw) / 2 : 0;
  win->vy = full ? (win->height - vh) / 2 : 0;
  win->vw = vw;
  win->vh = vh;
  win->sx = (f32)w / vw;
  win->sy = (f32)h / vh;
  if (full) {
    BendRenderTransform transform = {{{ (int)((double)w / vw * 65536), 0, 0 },
      { 0, (int)((double)h / vh * 65536), 0 }, { 0, 0, 65536 }}};
    window_render.transform(win->dpy, win->source, &transform);
    XClearWindow(win->dpy, win->win);
  }
}

static bool window_surface(BendWin* win) {
  if (win->source) {
    return true;
  }
  if (!win->full_supported) {
    return false;
  }
  Display* dpy = win->dpy;
  int scr = DefaultScreen(dpy);
  BendRenderFormat* format = window_render.format(dpy, DefaultVisual(dpy, scr));
  if (format == NULL) {
    win->full_supported = false;
    return false;
  }
  win->pix = XCreatePixmap(dpy, win->win, win->img->width, win->img->height,
    DefaultDepth(dpy, scr));
  BendRenderAttrs attrs = { .repeat = BEND_RENDER_PAD };
  win->source = window_render.create(dpy, win->pix, format, BEND_RENDER_REPEAT, &attrs);
  win->target = window_render.create(dpy, win->win, format, 0, NULL);
  window_render.filter(dpy, win->source, "nearest", NULL, 0);
  return true;
}

static void window_full_request(BendWin* win) {
  if (!win->full_wait || !win->mapped) {
    return;
  }
  XEvent ev = { 0 };
  ev.xclient.type = ClientMessage;
  ev.xclient.window = win->win;
  ev.xclient.message_type = win->state;
  ev.xclient.format = 32;
  ev.xclient.data.l[0] = win->full_want ? 1 : 0;
  ev.xclient.data.l[1] = win->full;
  ev.xclient.data.l[3] = 1;
  XSendEvent(win->dpy, DefaultRootWindow(win->dpy), False,
    SubstructureRedirectMask | SubstructureNotifyMask, &ev);
  win->full_sent = true;
  win->full_due = io_tick() + 5000000000ull;
  XFlush(win->dpy);
}
#endif

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
// not. A Press or Move makes its id live, a finger's last Press up, a
// Leave or a Lost frees it.
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
  bool gone = c == CID(Leave) || c == CID(Lost);
  if (c != CID(Press) && c != CID(Move) && !gone) {
    return true;
  }
  if (a >= 16 || (gone && !(q->live >> a & 1))) {
    return false;
  }
  u32 m = 1u << a;
  u32 b = c == CID(Press) ? 1u << (ev[WIN_BUTTON] & 31) : 0;
  if (gone) {
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

// A Press, or a Move (which ends before b), at ms.
static inline void window_point(WinQueue* q, u32 cid, u32 id, WinTool t,
  f32 x, f32 y, u32 ms, u32 b, bool down) {
  u32 ev[WIN_EV] = { cid, id, t.tag, f32_rewrap(t.v[0]), f32_rewrap(t.v[1]),
    f32_rewrap(t.v[2]), f32_rewrap(t.v[3]), f32_rewrap(t.v[4]),
    f32_rewrap(x), f32_rewrap(y), ms, b, down };
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
  WinQueue       q;
  u64            flags;
  BOOL           grab;
  BOOL           eraser;
  CGSize         draw_size;
#ifdef CID(Window.fullscreen)
  NSUInteger     full_style;
  NSUInteger     full_behavior;
  BOOL           full_want;
  BOOL           full_busy;
  BOOL           full_started;
  BOOL           full_dirty;
  u64            full_due;
#endif
  NSString*      marked;
  NSMutableArray* held;
  BOOL           other;
}
@end

@implementation BendView

- (CALayer*)makeBackingLayer {
  return [CAMetalLayer layer];
}

- (void)setFrameSize:(NSSize)size {
  [super setFrameSize:size];
  if (draw_size.width > 0) {
    ((CAMetalLayer*)self.layer).drawableSize = draw_size;
  }
}

- (void)viewDidChangeBackingProperties {
  [super viewDidChangeBackingProperties];
  ((CAMetalLayer*)self.layer).drawableSize = draw_size;
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

- (void)dealloc {
  free(q.evs);
}

- (void)key:(NSEvent*)ev down:(BOOL)down {
  NSString* s = [ev.charactersIgnoringModifiers lowercaseString];
  u32 code = s.length > 0 ? [s characterAtIndex:0] : 65536 + ev.keyCode;
  window_push(&q, CID(Key), code, down, 0, 0);
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
  u32 ev[WIN_EV];
  while (window_chunk(t, n, &at, ev)) {
    window_put(&q, ev);
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
  window_push(&q, CID(Key), 65536 + ev.keyCode, (now & ~flags) != 0, 0, 0);
  flags = now;
}

- (NSPoint)at:(NSEvent*)ev {
  return [self convertPoint:ev.locationInWindow fromView:nil];
}

// Where the image shows in the view: all of it, or fullscreen, letterboxed.
- (NSRect)imageRect {
  NSSize bounds = self.bounds.size;
  BOOL full = [self.layer.contentsGravity isEqualToString:kCAGravityResizeAspect];
  if (!full) {
    return self.bounds;
  }
  CGFloat scale = fmin(bounds.width / draw_size.width,
    bounds.height / draw_size.height);
  CGFloat w = draw_size.width * scale, h = draw_size.height * scale;
  return NSMakeRect((bounds.width - w) / 2, (bounds.height - h) / 2, w, h);
}

// A view point in the image's units.
- (NSPoint)px:(NSPoint)p {
  NSRect r = [self imageRect];
  return NSMakePoint((p.x - r.origin.x) * draw_size.width / r.size.width,
    (p.y - r.origin.y) * draw_size.height / r.size.height);
}

- (u32)ms:(NSEvent*)ev {
  return (u32)(u64)(ev.timestamp * 1000);
}

// A tablet's pen moves the cursor, but is its own pointer: one off the
// image takes no id (if make is NO) but the one it holds.
- (u32)pointer:(NSEvent*)ev tool:(WinTool*)t make:(BOOL)make {
  if (ev.subtype != NSEventSubtypeTabletPoint) {
    *t = (WinTool){ WIN_MOUSE };
    return 0;
  }
  *t = (WinTool){ WIN_PEN, { ev.pressure, ev.tangentialPressure,
    ev.tilt.x * 90, ev.tilt.y * 90, fmod(ev.rotation + 360, 360) } };
  return window_id(&q, ev.deviceID, make);
}

// The Mac's buttons 1 and 2 are W3C's 2 and 1; an eraser's contact is 5.
// Let go past the image, the pointer leaves; fullscreen, a press on the
// bars is off the window.
- (void)mouse:(NSEvent*)ev down:(BOOL)down {
  WinTool t;
  NSPoint p  = [self at:ev];
  NSPoint i  = [self px:p];
  BOOL    on = NSPointInRect(p, [self imageRect]);
  u32     id = [self pointer:ev tool:&t make:on || !down];
  u32     n  = (u32)ev.buttonNumber;
  if (down && !on && (id >= 16 || q.down[id] == 0)) {
    return;
  }
  window_point(&q, CID(Press), id, t, i.x, i.y, [self ms:ev],
    t.tag == WIN_PEN && eraser && n == 0 ? 5 : n == 1 ? 2 : n == 2 ? 1 : n,
    down);
  if (!down && id < 16 && q.down[id] == 0 && !on) {
    window_push(&q, CID(Leave), id, 0, 0, 0);
  }
}

// Past the image, only a held pointer moves; fullscreen, one with no button
// held leaves on the bars.
- (void)move:(NSEvent*)ev {
  if (grab) {
    NSSize s = [self imageRect].size;
    window_push(&q, CID(Look), f32_rewrap(ev.deltaX * draw_size.width / s.width),
      f32_rewrap(ev.deltaY * draw_size.height / s.height), 0, 0);
    return;
  }
  if (ev.subtype == NSEventSubtypeTabletProximity) {
    [self tabletProximity:ev];
    return;
  }
  WinTool t;
  NSPoint p  = [self at:ev];
  BOOL    on = NSPointInRect(p, [self imageRect]);
  u32     id = [self pointer:ev tool:&t make:on];
  if (id < 16 && (q.down[id] != 0 || on)) {
    NSPoint i = [self px:p];
    window_point(&q, CID(Move), id, t, i.x, i.y, [self ms:ev], 0, 0);
  } else if (id < 16 && NSPointInRect(p, self.bounds)) {
    window_push(&q, CID(Leave), id, 0, 0, 0);
  }
}

- (void)tabletProximity:(NSEvent*)ev {
  if (ev.enteringProximity) {
    eraser = ev.pointingDeviceType == NSPointingDeviceTypeEraser;
  } else {
    u32 id = window_id(&q, ev.deviceID, NO);
    window_push(&q, id < 16 && q.down[id] != 0 ? CID(Lost) : CID(Leave), id,
      0, 0, 0);
  }
}

- (void)mouseExited:(NSEvent*)ev {
  if (q.down[0] == 0) {
    window_push(&q, CID(Leave), 0, 0, 0, 0);
  }
}

- (void)scrollWheel:(NSEvent*)ev {
  NSPoint v = [self at:ev];
  if (!NSPointInRect(v, [self imageRect])) {
    return;
  }
  NSPoint p = [self px:v];
  window_push(&q, CID(Scroll), f32_rewrap(p.x), f32_rewrap(p.y),
    f32_rewrap(ev.scrollingDeltaX), f32_rewrap(ev.scrollingDeltaY));
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
  window_focus(&q, false);
}

- (void)windowDidBecomeKey:(NSNotification*)note {
  window_focus(&q, true);
}

#ifdef CID(Window.fullscreen)
// Queue the latest target during Cocoa's asynchronous transition. A
// user-initiated exit has no queued target, so it does not enter again.
- (void)setFullscreen:(BOOL)on {
  [self fullTick];
  full_want = on;
  full_dirty = YES;
  if (full_busy) {
    return;
  }
  full_dirty = NO;
  NSWindow* win = self.window;
  if (on != ((win.styleMask & NSWindowStyleMaskFullScreen) != 0)) {
    if (on) {
      self.layer.contentsGravity = kCAGravityResizeAspect;
      full_style = win.styleMask;
      full_behavior = win.collectionBehavior;
      win.styleMask |= NSWindowStyleMaskResizable;
      win.collectionBehavior |= NSWindowCollectionBehaviorFullScreenPrimary;
    }
    full_busy = YES;
    full_started = NO;
    full_due = io_tick() + 5000000000ull;
    [win toggleFullScreen:nil];
  }
}

- (void)fullDone {
  full_busy = NO;
  full_started = NO;
  if (!(self.window.styleMask & NSWindowStyleMaskFullScreen)) {
    self.window.styleMask = full_style;
    self.window.collectionBehavior = full_behavior;
    self.layer.contentsGravity = kCAGravityResize;
  }
}

// An ignored toggle sends no delegate notification. Frames and later requests
// retire it rather than leaving every future target queued forever. A target
// queued during a transition goes here, after it: AppKit ignores a toggle
// sent from its own did-enter or did-exit notification.
- (void)fullTick {
  if (full_busy && !full_started && io_tick() >= full_due) {
    [self fullDone];
  }
  if (!full_busy && full_dirty) {
    full_dirty = NO;
    [self setFullscreen:full_want];
  }
}

- (void)windowWillEnterFullScreen:(NSNotification*)note {
  full_busy = YES;
  full_started = YES;
  self.layer.contentsGravity = kCAGravityResizeAspect;
}

- (void)windowWillExitFullScreen:(NSNotification*)note {
  full_busy = YES;
  full_started = YES;
}

- (void)windowDidEnterFullScreen:(NSNotification*)note {
  [self fullDone];
}

- (void)windowDidExitFullScreen:(NSNotification*)note {
  [self fullDone];
}

- (void)windowDidFailToEnterFullScreen:(NSWindow*)win {
  [self fullDone];
}

- (void)windowDidFailToExitFullScreen:(NSWindow*)win {
  [self fullDone];
}
#endif

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
  window_push(&q, CID(Close), 0, 0, 0, 0);
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
    view->flags = NSEvent.modifierFlags;
    view->draw_size = CGSizeMake(w, h);
#ifdef CID(Window.fullscreen)
    view->full_style = win.styleMask;
    view->full_behavior = win.collectionBehavior;
#endif
    view.wantsLayer = YES;
    CAMetalLayer* layer = (CAMetalLayer*)view.layer;
    layer.device = window_dev;
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    layer.framebufferOnly = NO;
    layer.drawableSize = CGSizeMake(w, h);
    layer.contentsGravity = kCAGravityResize;
    layer.backgroundColor = NSColor.blackColor.CGColor;
#ifdef CID(Window.fullscreen)
    layer.magnificationFilter = kCAFilterNearest;
    layer.minificationFilter = kCAFilterNearest;
#endif
    layer.displaySyncEnabled = YES;
    layer.maximumDrawableCount = 2;
    win.contentView = view;
    win.delegate = view;
    [view addTrackingArea:[[NSTrackingArea alloc] initWithRect:NSZeroRect
      options:NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways
        | NSTrackingInVisibleRect owner:view userInfo:nil]];
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

// XInput2, through a libXi loaded at run time as libXrandr is: the
// pointers on the window, devices plugged or unplugged on the root. Its opcode, or 0 (no libXi or XInput
// 2.2: core events then stand for the mouse alone).
static WinXIDevice* (*window_xi_query)(Display*, int, int*);
static void         (*window_xi_free)(WinXIDevice*);

static int window_xi(Display* dpy, Window w) {
  int   op, ev, er;
  void* xi = XQueryExtension(dpy, "XInputExtension", &op, &ev, &er)
    ? dlopen("libXi.so.6", RTLD_LAZY | RTLD_LOCAL) : NULL;
  if (xi == NULL) {
    return 0;
  }
  Status (*version)(Display*, int*, int*) =
    (Status (*)(Display*, int*, int*))dlsym(xi, "XIQueryVersion");
  int (*select)(Display*, Window, WinXIMask*, int) =
    (int (*)(Display*, Window, WinXIMask*, int))dlsym(xi, "XISelectEvents");
  window_xi_query = (WinXIDevice* (*)(Display*, int, int*))dlsym(xi,
    "XIQueryDevice");
  window_xi_free = (void (*)(WinXIDevice*))dlsym(xi, "XIFreeDeviceInfo");
  int major = 2;
  int minor = 2;
  if (!version || !select || !window_xi_query || !window_xi_free
    || version(dpy, &major, &minor) != Success || major * 10 + minor < 22) {
    return 0;
  }
  int           evs[] = { XI_ButtonPress, XI_ButtonRelease, XI_Motion,
    XI_Leave, XI_TouchBegin, XI_TouchUpdate, XI_TouchEnd };
  unsigned char on[3]   = { 0 };
  unsigned char plug[2] = { 0 };
  for (u32 i = 0; i < sizeof evs / sizeof *evs; i += 1) {
    XISetMask(on, evs[i]);
  }
  XISetMask(plug, XI_HierarchyChanged);
  WinXIMask m[2] = { { XIAllMasterDevices, sizeof on, on },
    { XIAllDevices, sizeof plug, plug } };
  select(dpy, w, &m[0], 1);
  select(dpy, DefaultRootWindow(dpy), &m[1], 1);
  return op;
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
  win->width = w;
  win->height = h;
  win->win = XCreateSimpleWindow(dpy, RootWindow(dpy, scr), 0, 0, w, h, 0, 0,
    BlackPixel(dpy, scr));
  window_ime(win);
  long im_evs = 0;
  if (win->ic != NULL) {
    XGetICValues(win->ic, XNFilterEvents, &im_evs, NULL);
  }
  win->del = XInternAtom(dpy, "WM_DELETE_WINDOW", False);
#ifdef CID(Window.fullscreen)
  win->state = XInternAtom(dpy, "_NET_WM_STATE", False);
  win->full = XInternAtom(dpy, "_NET_WM_STATE_FULLSCREEN", False);
  Atom have = XInternAtom(dpy, "_NET_SUPPORTED", False);
  win->full_supported = window_has_value(dpy, DefaultRootWindow(dpy), have,
    XA_ATOM, win->full) && window_renderer(dpy);
#endif
  win->img = XCreateImage(dpy, DefaultVisual(dpy, scr), DefaultDepth(dpy, scr),
    ZPixmap, 0, io_mem(calloc(w * h, 4)), w, h, 32, w * 4);
  win->img->byte_order = LSBFirst;
  window_limits(win, false);
#ifdef CID(Window.fullscreen)
  window_viewport(win);
#endif
  XSetWMProtocols(dpy, win->win, &win->del, 1);
  window_x_title(dpy, win->win, title, strlen(title));
  win->xi = window_xi(dpy, win->win);
  XSelectInput(dpy, win->win, KeyPressMask | KeyReleaseMask | FocusChangeMask
    | im_evs | (win->xi ? 0 : ButtonPressMask | ButtonReleaseMask
      | PointerMotionMask | LeaveWindowMask)
#ifdef CID(Window.fullscreen)
    | PropertyChangeMask | StructureNotifyMask
#endif
    );
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

// The queue's events, which it then forgets.
static Term window_list(Env e, WinQueue* q) {
  Term list = term_pak(CID(Nil), 0);
  for (u64 i = q->n; i > 0; i -= 1) {
    list = io_node(e, CID(Con), window_node(e, q->evs + WIN_EV * (i - 1)),
      list);
  }
  q->n = 0;
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

static void window_show(Env e, CAMetalLayer* layer, Term image, CGSize size) {
  id<MTLDevice> dev = layer.device;
  window_pipe(dev);
  id<MTLBuffer> buf = window_corpus(e, dev);
  WinArgs args = { image, size.width, size.height, 0 };
  if (!CGSizeEqualToSize(layer.drawableSize, size)) {
    layer.drawableSize = size;
  }
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
  BendView* view = (BendView*)((__bridge NSWindow*)(void*)at).contentView;
  io_sync();
#ifdef CID(Window.fullscreen)
  [view fullTick];
#endif
  window_show(e, (CAMetalLayer*)view.layer, image, view->draw_size);
  return window_list(e, &view->q);
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

// A window position (at), or a size or motion, in the image's units:
// fullscreen scales it out of the letterbox.
static void window_px(BendWin* win, f32* x, f32* y, bool at) {
#ifdef CID(Window.fullscreen)
  if (win->full_now && win->source) {
    *x = (*x - (at ? (f32)win->vx : 0)) * win->sx;
    *y = (*y - (at ? (f32)win->vy : 0)) * win->sy;
  }
#endif
}

// Fullscreen, the bars are off the image: a pointer there with no button
// held is off the window, as one past its edge. A grab holds the mouse in
// the window, bars and all, between warps: nothing is off.
static bool window_off(BendWin* win, u32 id, f32 x, f32 y) {
#ifdef CID(Window.fullscreen)
  return win->full_now && win->source && !win->grab
    && (id >= 16 || win->q.down[id] == 0)
    && (x < 0 || y < 0 || x >= win->img->width || y >= win->img->height);
#else
  return false;
#endif
}

// The frame's grabbed motion, as one Look in the image's units.
static void window_look_push(BendWin* win, f32 dx, f32 dy) {
  window_px(win, &dx, &dy, false);
  window_push(&win->q, CID(Look), f32_rewrap(dx), f32_rewrap(dy), 0, 0);
}

// A grabbed motion to (x, y): its move from the last position, counted past
// the warp back to the centre, not the warp itself. Motion queued before a
// grab or resize reset the basis is dropped.
static void window_look(BendWin* win, unsigned long serial, int x, int y,
  f32* dx, f32* dy) {
  if (serial < win->warp_floor) {
    return;
  }
  if (win->warp_serial && serial >= win->warp_serial) {
    win->warp_serial = 0;
    win->mouse_x = win->width / 2;
    win->mouse_y = win->height / 2;
  }
  *dx += x - win->mouse_x;
  *dy += y - win->mouse_y;
  win->mouse_x = x;
  win->mouse_y = y;
}

// X buttons: 1 to 3 left, middle, right; 4 to 7 the wheel (up, down, left,
// right; a notch is 1, up and left positive); 8 and 9 back, forward.
static void window_button(BendWin* win, u32 id, WinTool t, f32 x, f32 y,
  u32 ms, u32 b, bool down, bool eraser) {
  f32 s = b % 2 ? -1 : 1;
  if (b >= 4 && b <= 7 && down) {
    window_push(&win->q, CID(Scroll), f32_rewrap(x), f32_rewrap(y),
      f32_rewrap(b > 5 ? s : 0), f32_rewrap(b > 5 ? 0 : s));
  } else if (b <= 3 || b == 8 || b == 9) {
    window_point(&win->q, CID(Press), id, t, x, y, ms,
      eraser && b == 1 ? 5 : b <= 3 ? b - 1 : b - 5, down);
  }
}

// Off the window, a pointer leaves unless a button holds it; a grab
// elsewhere takes only a held one, which is lost (its release then goes
// there).
static void window_leave(BendWin* win, u32 id, int mode) {
  bool held = id < 16 && win->q.down[id] != 0;
  bool took = mode == NotifyGrab || mode == XINotifyPassiveGrab;
  if (held == took) {
    window_push(&win->q, held ? CID(Lost) : CID(Leave), id, 0, 0, 0);
  }
}

static const struct {
  const char* label;
  int         ax;
} window_axes[] = {
  { "Abs Pressure", WIN_FORCE }, { "Abs MT Pressure", WIN_FORCE },
  { "Abs Tilt X", WIN_TILT_X }, { "Abs Tilt Y", WIN_TILT_Y },
  { "Abs MT Touch Major", WIN_MAJOR }, { "Abs MT Touch Minor", WIN_MINOR },
};

// A device as first met: a touch screen if it has a direct touch class, a
// mouse if another (a touchpad), a pen if a force (its eraser is its own
// device, by name), else a mouse. A finger's size is in the screen's width
// over its position's range. The table empties when full, or when devices
// come or go.
static WinDev* window_dev(BendWin* win, int id) {
  for (u32 i = 0; i < win->nd; i += 1) {
    if (win->devs[i].id == id) {
      return &win->devs[i];
    }
  }
  win->nd = win->nd == 8 ? 0 : win->nd;
  WinDev* d = &win->devs[win->nd++];
  *d = (WinDev){ .id = id, .ax = { -1, -1, -1, -1, -1 } };
  int          n     = 0;
  int          touch = 0;
  WinXIDevice* info  = window_xi_query(win->dpy, id, &n);
  for (int k = 0; info != NULL && k < info->num_classes; k += 1) {
    WinXIClass* c = info->classes[k];
    char*       s = c->type == XIValuatorClass && c->label != None
      ? XGetAtomName(win->dpy, c->label) : NULL;
    touch = c->type == XITouchClass ? c->number : touch;
    for (u32 j = 0; s != NULL && j < sizeof window_axes / sizeof *window_axes;
      j += 1) {
      if (strcmp(s, window_axes[j].label) == 0) {
        d->ax[window_axes[j].ax] = c->number;
        d->lo[window_axes[j].ax] = c->min;
        d->hi[window_axes[j].ax] = c->max;
      }
    }
    if (s != NULL && strcmp(s, "Abs MT Position X") == 0 && c->max > c->min) {
      d->px = DisplayWidth(win->dpy, DefaultScreen(win->dpy))
        / (c->max - c->min);
    }
    if (s != NULL) {
      XFree(s);
    }
  }
  d->tool   = touch == XIDirectTouch ? WIN_FINGER
    : touch || d->ax[WIN_FORCE] < 0 ? WIN_MOUSE : WIN_PEN;
  d->eraser = d->tool == WIN_PEN && info != NULL
    && (strstr(info->name, "eraser") || strstr(info->name, "Eraser"));
  if (info != NULL) {
    window_xi_free(info);
  }
  return d;
}

static void window_vals(WinDev* d, const WinXIVals* v) {
  const double* p = v->values;
  for (int k = 0; k < v->len * 8; k += 1) {
    if (v->mask[k >> 3] >> (k & 7) & 1) {
      for (u32 j = 0; j < WIN_AXES; j += 1) {
        d->at[j] = d->ax[j] == k ? *p : d->at[j];
      }
      p += 1;
    }
  }
}

// Axis a's value (from 0 to 1 if norm), else none if it has no valuator.
static f32 window_axis(const WinDev* d, int a, bool norm, f32 none) {
  return d->ax[a] < 0 || (norm && d->hi[a] <= d->lo[a]) ? none
    : (f32)(norm ? (d->at[a] - d->lo[a]) / (d->hi[a] - d->lo[a]) : d->at[a]);
}

static WinTool window_tool(const WinDev* d, bool down) {
  f32 force = down ? window_axis(d, WIN_FORCE, true, 0.5f) : 0;
  if (d->tool == WIN_FINGER) {
    f32 w = (f32)d->px * window_axis(d, WIN_MAJOR, false, 0);
    f32 h = (f32)d->px * window_axis(d, WIN_MINOR, false, 0);
    return (WinTool){ WIN_FINGER, { force, w > 0 ? w : 1,
      h > 0 ? h : w > 0 ? w : 1 } };
  }
  if (d->tool == WIN_PEN) {
    return (WinTool){ WIN_PEN, { force, 0,
      fmaxf(-90, fminf(90, window_axis(d, WIN_TILT_X, false, 0))),
      fmaxf(-90, fminf(90, window_axis(d, WIN_TILT_Y, false, 0))), 0 } };
  }
  return (WinTool){ WIN_MOUSE };
}

// Each finger of a touch screen is its own pointer (its pointer events,
// which repeat them, are dropped), a pen one per device. Under the window's
// grab a motion only adds to the look (dx, dy), as a core one does.
static void window_xi_event(BendWin* win, XGenericEventCookie* c, f32* dx,
  f32* dy) {
  const WinXIEvent* xe = c->data;
  int               t  = c->evtype;
  if (t == XI_HierarchyChanged) {
    win->nd = 0;
    return;
  }
  f32 x = (f32)xe->h.event_x;
  f32 y = (f32)xe->h.event_y;
  window_px(win, &x, &y, true);
  WinDev* d     = window_dev(win, xe->h.sourceid);
  u64     name  = (u64)(u32)d->id << 32;
  bool    touch = t >= XI_TouchBegin && t <= XI_TouchEnd;
  if (touch && d->tool == WIN_FINGER) {
    window_vals(d, &xe->vals);
    WinTool tool = window_tool(d, t != XI_TouchEnd);
    window_px(win, &tool.v[1], &tool.v[2], false);
    if (t != XI_TouchBegin || !window_off(win, 16, x, y)) {
      window_point(&win->q, t == XI_TouchUpdate ? CID(Move) : CID(Press),
        window_id(&win->q, name | (u32)xe->h.detail, t == XI_TouchBegin),
        tool, x, y, (u32)xe->h.time, 0, t == XI_TouchBegin);
    }
  }
  if (touch || d->tool == WIN_FINGER) {
    return;
  }
  // a pen takes an id on the image, not on the bars
  u32 id = d->tool == WIN_MOUSE ? 0 : window_id(&win->q, name | 0xFFFFFFFF,
    false);
  if (t == XI_Leave) {
    window_leave(win, id, xe->flags);
    return;
  }
  if (t == XI_Motion && win->grab) {
    window_look(win, xe->h.serial, (int)xe->h.event_x, (int)xe->h.event_y, dx,
      dy);
    return;
  }
  window_vals(d, &xe->vals);
  if (window_off(win, id, x, y)) {
    if (t == XI_Motion) {
      window_leave(win, id, NotifyNormal);
    }
    return;
  }
  id = id < 16 || d->tool == WIN_MOUSE ? id
    : window_id(&win->q, name | 0xFFFFFFFF, true);
  bool    pressed = t == XI_ButtonPress
    || (t != XI_ButtonRelease && id < 16 && win->q.down[id] != 0);
  WinTool tool    = window_tool(d, pressed);
  if (t == XI_Motion) {
    window_point(&win->q, CID(Move), id, tool, x, y, (u32)xe->h.time, 0,
      false);
  } else {
    window_button(win, id, tool, x, y, (u32)xe->h.time, xe->h.detail,
      t == XI_ButtonPress, d->eraser);
  }
}

static void window_pump(BendWin* win) {
  u32 pw = win->width;
  u32 ph = win->height;
  int cx = pw / 2;
  int cy = ph / 2;
  f32 dx = 0, dy = 0;
  while (XPending(win->dpy) > 0) {
    XEvent ev;
    XNextEvent(win->dpy, &ev);
    XKeyEvent key  = ev.xkey;
    bool      took = XFilterEvent(&ev, None);
    if (ev.type == ConfigureNotify) {
      if (pw != ev.xconfigure.width || ph != ev.xconfigure.height) {
        win->width = pw = ev.xconfigure.width;
        win->height = ph = ev.xconfigure.height;
        cx = pw / 2;
        cy = ph / 2;
        dx = dy = 0;
        if (win->grab) {
          window_warp(win, cx, cy, true);
        }
#ifdef CID(Window.fullscreen)
        window_viewport(win);
#endif
      }
#ifdef CID(Window.fullscreen)
    } else if (ev.type == PropertyNotify && ev.xproperty.atom == win->state) {
      bool full = window_has_value(win->dpy, win->win, win->state, XA_ATOM,
        win->full);
      if (full == win->full_want) {
        win->full_wait = win->full_sent = false;
      }
      if (!win->full_wait) {
        win->full_want = full;
      }
      if (win->full_now != full) {
        win->full_now = full;
        if (full) {
          window_surface(win);
        }
        window_limits(win, full || win->full_want);
        window_viewport(win);
      }
    } else if (ev.type == MapNotify || ev.type == UnmapNotify) {
      // a request waits for the window to show, and goes again (its clock
      // with it) if the window hid before the window manager answered
      win->mapped = ev.type == MapNotify;
      win->full_sent &= win->mapped;
      window_full_request(win);
#endif
    } else if (ev.type == KeyPress || ev.type == KeyRelease) {
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
      f32 x = ev.xbutton.x, y = ev.xbutton.y;
      window_px(win, &x, &y, true);
      if (!window_off(win, 0, x, y)) {
        window_button(win, 0, (WinTool){ WIN_MOUSE }, x, y,
          (u32)ev.xbutton.time, ev.xbutton.button, ev.type == ButtonPress,
          false);
      }
    } else if (ev.type == MotionNotify) {
      f32 x = ev.xmotion.x, y = ev.xmotion.y;
      window_px(win, &x, &y, true);
      if (win->grab) {
        window_look(win, ev.xmotion.serial, ev.xmotion.x, ev.xmotion.y, &dx,
          &dy);
      } else if (window_off(win, 0, x, y)) {
        window_leave(win, 0, NotifyNormal);
      } else {
        window_point(&win->q, CID(Move), 0, (WinTool){ WIN_MOUSE }, x, y,
          (u32)ev.xmotion.time, 0, false);
      }
    } else if (ev.type == LeaveNotify) {
      window_leave(win, 0, ev.xcrossing.mode);
    } else if (ev.type == GenericEvent && ev.xcookie.extension == win->xi
      && XGetEventData(win->dpy, &ev.xcookie)) {
      window_xi_event(win, &ev.xcookie, &dx, &dy);
      XFreeEventData(win->dpy, &ev.xcookie);
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
#ifdef CID(Window.fullscreen)
  if (win->full_wait && win->full_sent && io_tick() >= win->full_due) {
    win->full_now = window_has_value(win->dpy, win->win, win->state, XA_ATOM,
      win->full);
    win->full_wait = win->full_sent = false;
    win->full_want = win->full_now;
    window_limits(win, win->full_now);
    window_viewport(win);
  }
#endif
  // grabbed, the frame's motion is one look, in the image's units
  if (win->grab && (dx != 0 || dy != 0)) {
    window_look_push(win, dx, dy);
  }
  if (win->grab && (win->mouse_x != cx || win->mouse_y != cy)) {
    window_warp(win, cx, cy, false);
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
#ifdef CID(Window.fullscreen)
  if (win->full_now && win->source) {
    XPutImage(win->dpy, win->pix, DefaultGC(win->dpy, DefaultScreen(win->dpy)),
      win->img, 0, 0, 0, 0, w, h);
    window_render.composite(win->dpy, BEND_RENDER_SRC, win->source, None, win->target,
      0, 0, 0, 0, win->vx, win->vy, win->vw, win->vh);
  } else
#endif
  {
    XPutImage(win->dpy, win->win, DefaultGC(win->dpy, DefaultScreen(win->dpy)),
      win->img, 0, 0, 0, 0, w, h);
  }
  XFlush(win->dpy);
}

static Term window_frame(Env e, intptr_t at, Term image) {
  BendWin* win = (BendWin*)at;
  io_sync();
  window_pump(win);
  window_show(e, win, image);
  return window_list(e, &win->q);
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

#ifdef CID(Window.fullscreen)

#ifdef __OBJC__

static u32 window_fullscreen(intptr_t at, bool on, const char** why) {
  NSWindow* win = (__bridge NSWindow*)(void*)at;
  if (!win.isVisible || win.isMiniaturized || win.screen == nil) {
    *why = "Window.fullscreen: window is not on screen";
    return EAGAIN;
  }
  [win.contentView setValue:@(on) forKey:@"fullscreen"];
  return 0;
}

#elif defined(__linux__)

static u32 window_fullscreen(intptr_t at, bool on, const char** why) {
  BendWin* win = (BendWin*)at;
  if (!win->full_supported) {
    *why = "Window.fullscreen: desktop has no EWMH/XRender fullscreen support";
    return ENOTSUP;
  }
  if (on && !window_surface(win)) {
    *why = "Window.fullscreen: XRender has no format for this display";
    return ENOTSUP;
  }
  if (win->full_wait ? win->full_want == on : win->full_now == on) {
    return 0;
  }
  win->full_want = on;
  if (!win->full_sent && win->full_now == on) {
    win->full_wait = false;
    window_limits(win, on);
    return 0;
  }
  win->full_wait = true;
  window_limits(win, true);
  window_full_request(win);
  return 0;
}

#else

static u32 window_fullscreen(intptr_t at, bool on, const char** why) {
  *why = "Window.fullscreen: native window support is unavailable";
  return ENOTSUP;
}

#endif

Term window_fullscreen_run(Env e, Term* f, IoWork* w) {
  const char* why = NULL;
  u32 q = window_fullscreen((intptr_t)io_hand_v(f[0]),
    term_aux(f[1]) == CID(True), &why);
  Term result = q ? io_fail(e, q, why)
    : io_done(e, term_pak(CID(Unit), 0));
  return io_tup(e, f[0], result);
}

static void __attribute__((constructor)) window_fullscreen_use(void) {
  io_eff(CID(Window.fullscreen), window_fullscreen_run);
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
      window_warp(win, win->width / 2, win->height / 2, true);
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
#ifdef CID(Window.fullscreen)
  // it leaves fullscreen first, after any transition under way; one AppKit
  // never finishes (the display slept) waits 5 s at most
  BendView* view = (BendView*)win.contentView;
  u64       end  = io_tick() + 5000000000ull;
  [view setFullscreen:NO];
  while ((view->full_busy || view->full_dirty) && io_tick() < end) {
    @autoreleasepool {
      NSEvent* ev = [NSApp nextEventMatchingMask:NSEventMaskAny
        untilDate:NSDate.distantPast inMode:NSDefaultRunLoopMode dequeue:YES];
      if (ev != nil) {
        [NSApp sendEvent:ev];
      } else {
        CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.01, true);
      }
      [view fullTick];
    }
  }
#endif
  win.delegate = nil;
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
#ifdef CID(Window.fullscreen)
  if (win->source) {
    window_render.destroy(win->dpy, win->source);
    window_render.destroy(win->dpy, win->target);
    XFreePixmap(win->dpy, win->pix);
  }
#endif
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
