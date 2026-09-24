// Window
// ======

#ifdef __OBJC__

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

@interface BendView : NSView <NSWindowDelegate> {
  @public
  NSMutableData* evs;
  u64            flags;
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

- (void)push:(u32)kind a:(u32)a b:(u32)b c:(u32)c d:(u32)d {
  u32 ev[5] = { kind, a, b, c, d };
  [evs appendBytes:ev length:sizeof ev];
}

- (void)key:(NSEvent*)ev down:(BOOL)down {
  NSString* s = [ev.charactersIgnoringModifiers lowercaseString];
  u32 code = s.length > 0 ? [s characterAtIndex:0] : 65536 + ev.keyCode;
  [self push:0 a:code b:down c:0 d:0];
}

- (void)keyDown:(NSEvent*)ev {
  [self key:ev down:YES];
}

- (void)keyUp:(NSEvent*)ev {
  [self key:ev down:NO];
}

- (void)flagsChanged:(NSEvent*)ev {
  u64 now = ev.modifierFlags;
  [self push:0 a:65536 + ev.keyCode b:(now & ~flags) != 0 c:0 d:0];
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
  [self push:1 a:p.x b:p.y c:(u32)ev.buttonNumber d:down];
}

- (void)move:(NSEvent*)ev {
  NSPoint p = [self at:ev];
  [self push:2 a:p.x b:p.y c:0 d:0];
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
  [self push:3 a:0 b:0 c:0 d:0];
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
    win.title = [NSString stringWithCString:title
      encoding:NSISOLatin1StringEncoding];
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

// The X11 window: its own connection (so its queue holds only its
// events), the frame's image and the events pumped since the last
// frame, five words each (kind, a, b, c, d) as on the Mac. The same
// block sits in window_frame.c and window_close.c under this guard.
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
  win->win = XCreateSimpleWindow(dpy, RootWindow(dpy, scr), 0, 0, w, h, 0, 0,
    BlackPixel(dpy, scr));
  win->del = XInternAtom(dpy, "WM_DELETE_WINDOW", False);
  win->img = XCreateImage(dpy, DefaultVisual(dpy, scr), DefaultDepth(dpy, scr),
    ZPixmap, 0, io_mem(calloc(w * h, 4)), w, h, 32, w * 4);
  win->img->byte_order = LSBFirst;
  XSizeHints hints = { .flags = PMinSize | PMaxSize, .min_width = w,
    .min_height = h, .max_width = w, .max_height = h };
  XSetWMNormalHints(dpy, win->win, &hints);
  XSetWMProtocols(dpy, win->win, &win->del, 1);
  XStoreName(dpy, win->win, title);
  XSelectInput(dpy, win->win, KeyPressMask | KeyReleaseMask | ButtonPressMask
    | ButtonReleaseMask | PointerMotionMask);
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
  io_eff(CID(Window.open), window_open_run, 0);
}
