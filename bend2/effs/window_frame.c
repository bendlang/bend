// Window
// ======

// An event is five words: kind (0 key, 1 mouse, 2 move, 3 close) and
// its fields; a frame answers the events pumped since the last one.
#if defined(__OBJC__) || defined(__linux__)

static Term window_node(Env e, const u32* ev) {
  static const u32 cids[3] = { CID_KEY, CID_MOUSE, CID_MOVE };
  if (ev[0] == 3) {
    return term_pak(CID_CLOSE, 0);
  }
  u32 n = ev[0] == 1 ? 4 : 2;
  Loc l = heap_alloc(e, cls_fit(n));
  for (u32 j = 0; j < n; j += 1) {
    e.mem[l + j] = ev[1 + j];
  }
  return term_ctr(cids[ev[0]], l);
}

static Term window_list(Env e, const u32* p, u64 n) {
  Term list = term_pak(CID_NIL, 0);
  for (u64 i = n; i > 0;) {
    i -= 1;
    Loc l = heap_alloc(e, 1);
    e.mem[l]     = io_seal(e, window_node(e, p + 5 * i), CID_CON);
    e.mem[l + 1] = io_seal(e, list, CID_CON);
    list = term_ctr(CID_CON, l);
  }
  return list;
}

#endif

#ifdef __OBJC__

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>

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

static void window_pump(void) {
  @autoreleasepool {
    for (;;) {
      NSEvent* ev = [NSApp nextEventMatchingMask:NSEventMaskAny
        untilDate:NSDate.distantPast inMode:NSDefaultRunLoopMode dequeue:YES];
      if (ev == nil) {
        break;
      }
      [NSApp sendEvent:ev];
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
  while ((1u << args.k) < args.w || (1u << args.k) < args.h) {
    args.k += 1;
  }
  window_pump();
  @autoreleasepool {
    id<CAMetalDrawable> d = [layer nextDrawable];
    if (d == nil) {
      return;
    }
    id<MTLCommandBuffer> cb = [window_que commandBuffer];
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
    if (cb.error != nil) {
      err_fail(cb.error.localizedDescription.UTF8String);
    }
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

// The Mac's key codes: a key's character in lower case, the function
// keys' private-use characters (the arrows at 63232), a modifier's
// 65536 + its key code.
static const u32 window_keys[][2] = {
  { XK_Escape,    27 },    { XK_Return,    13 },    { XK_KP_Enter,  13 },
  { XK_Tab,       9 },     { XK_BackSpace, 127 },   { XK_Up,        63232 },
  { XK_Down,      63233 }, { XK_Left,      63234 }, { XK_Right,     63235 },
  { XK_Insert,    63271 }, { XK_Delete,    63272 }, { XK_Home,      63273 },
  { XK_End,       63275 }, { XK_Page_Up,   63276 }, { XK_Page_Down, 63277 },
  { XK_Super_R,   65590 }, { XK_Super_L,   65591 }, { XK_Shift_L,   65592 },
  { XK_Caps_Lock, 65593 }, { XK_Alt_L,     65594 }, { XK_Control_L, 65595 },
  { XK_Shift_R,   65596 }, { XK_Alt_R,     65597 }, { XK_Control_R, 65598 },
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
  if (n == 1 && (u8)c[0] >= 32) {
    return (u8)c[0] >= 'A' && (u8)c[0] <= 'Z' ? (u8)c[0] + 32 : (u8)c[0];
  }
  return 65536 + ev->keycode;
}

static void window_push(BendWin* win, u32 kind, u32 a, u32 b, u32 c, u32 d) {
  if (win->n == win->cap) {
    win->cap = win->cap == 0 ? 64 : win->cap * 2;
    win->evs = io_mem(realloc(win->evs, win->cap * 20));
  }
  u32 ev[5] = { kind, a, b, c, d };
  memcpy(win->evs + win->n * 5, ev, sizeof ev);
  win->n += 1;
}

static u32 window_clip(int v, u32 most) {
  return v < 0 ? 0 : (u32)v < most ? (u32)v : most - 1;
}

static void window_pump(BendWin* win) {
  u32 w = win->img->width;
  u32 h = win->img->height;
  while (XPending(win->dpy) > 0) {
    XEvent ev;
    XNextEvent(win->dpy, &ev);
    if (ev.type == KeyPress || ev.type == KeyRelease) {
      window_push(win, 0, window_key(&ev.xkey), ev.type == KeyPress, 0, 0);
    } else if (ev.type == ButtonPress || ev.type == ButtonRelease) {
      u32 b = ev.xbutton.button;
      if (b >= 1 && b <= 3) {
        window_push(win, 1, window_clip(ev.xbutton.x, w),
          window_clip(ev.xbutton.y, h), b == 1 ? 0 : 4 - b,
          ev.type == ButtonPress);
      }
    } else if (ev.type == MotionNotify) {
      window_push(win, 2, window_clip(ev.xmotion.x, w),
        window_clip(ev.xmotion.y, h), 0, 0);
    } else if (ev.type == ClientMessage
      && (Atom)ev.xclient.data.l[0] == win->del) {
      window_push(win, 3, 0, 0, 0, 0);
    }
  }
}

#if BEND_CUDA
static CUfunction  window_pso;
static CUdeviceptr window_buf;
static u64         window_len;
#endif

// The frame's pixels: window_dev on the device while the corpus is
// there (the tree's pages never leave it), else window_pix a pixel at
// a time.
static void window_fill(Env e, u32* pix, u32 w, u32 h, Term image, u32 k) {
#if BEND_CUDA
  if (io_gpu) {
    Corpus H    = e.mem;
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
  for (u32 y = 0; y < h; y += 1) {
    for (u32 x = 0; x < w; x += 1) {
      pix[y * w + x] = window_pix(e.mem, image, k, x, y);
    }
  }
}

// A frame waits for the next 60 Hz tick, as the Mac's display sync.
static void window_pace(void) {
  static u64 due;
  u64 now = io_tick();
  if (due > now) {
    struct timespec ts = { 0, (long)(due - now) };
    nanosleep(&ts, NULL);
  }
  due = (due > now ? due : now) + 16666667;
}

static void window_show(Env e, BendWin* win, Term image) {
  u32 w = win->img->width;
  u32 h = win->img->height;
  u32 k = 0;
  while ((1u << k) < w || (1u << k) < h) {
    k += 1;
  }
  window_fill(e, (u32*)win->img->data, w, h, image, k);
  window_pace();
  XPutImage(win->dpy, win->win, DefaultGC(win->dpy, DefaultScreen(win->dpy)),
    win->img, 0, 0, 0, 0, w, h);
  XFlush(win->dpy);
}

static Term window_frame(Env e, intptr_t at, Term image) {
  BendWin* win = (BendWin*)at;
  io_sync();
  window_pump(win);
  window_show(e, win, image);
  Term list = window_list(e, win->evs, win->n);
  win->n = 0;
  return list;
}

#else

static Term window_frame(Env e, intptr_t at, Term image) {
  return term_pak(CID_NIL, 0);
}

#endif

Term window_frame_run(Env e, Term* f, IoWork* w) {
  Term events = window_frame(e, (intptr_t)io_hand_v(f[0]), f[1]);
  return io_tup(e, f[0], io_tup(e, f[1], events));
}

static void __attribute__((constructor)) window_frame_use(void) {
  io_eff(CID_WINDOW_FRAME, window_frame_run, 0);
}
