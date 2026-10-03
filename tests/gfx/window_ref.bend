import Base

def WindowRefTest.probe(display: String, id: U32, title: String,
  close: Bool) -> IO(Bool):
  import "./window_ref.c"
  import "./window_ref.js"

def report(ok: Bool) -> IO(Unit):
  match ok:
    case True{}:
      IO.print("window reference: OK")
    case False{}:
      IO.print("window reference: FAIL")

def same(a: WindowRef, b: WindowRef) -> Bool:
  X11WindowRef{ad, ai} = a
  X11WindowRef{bd, bi} = b
  String.eq(ad, bd) && U32.is_eq(ai, bi)

def probe(ref: WindowRef, title: String, close: Bool) -> IO(Bool):
  X11WindowRef{display, id} = ref
  WindowRefTest.probe(display, id, title, close)

def has_close(events: List<Event>) -> Bool:
  match events:
    case Nil{}:
      False{}
    case Close{} <> rest:
      True{}
    case event <> rest:
      has_close(rest)

def framed(ok: Bool, q: Window & Image & List<Event>) -> IO(Unit):
  (window, image, events) = q
  do IO<Unit>:
    Window.close(window)
    report(ok && has_close(events))

def refused(ok: Bool, window: Window) -> IO(Unit):
  do IO<Unit>:
    Window.close(window)
    report(ok)

def pending(ref: WindowRef, ok: Bool,
  q: Window & Result<&1, &1, U32 & String, WindowRef>) -> IO(Unit):
  (window, result) = q
  match result:
    case Done{after}:
      IO.bind(Window & Image & List<Event>, Unit,
        Window.frame(window, Pix{4278190335}), framed(ok && same(ref, after)))
    case Fail{error}:
      refused(False{}, window)

def repeated(before: WindowRef, first_ok: Bool,
  q: Window & Result<&1, &1, U32 & String, WindowRef>) -> IO(Unit):
  (window, result) = q
  match result:
    case Done{+ref}:
      ok = first_ok && same(before, ref)
      do IO<Unit>:
        checked : Bool <- probe(ref, "Bend reference renamed", True{})
        IO.bind(Window & Result<&1, &1, U32 & String, WindowRef>, Unit,
          Window.export_ref(window), pending(ref, ok && checked))
    case Fail{error}:
      refused(False{}, window)

def first(q: Window & Result<&1, &1, U32 & String, WindowRef>) -> IO(Unit):
  (window, result) = q
  match result:
    case Done{+ref}:
      do IO<Unit>:
        ok : Bool <- probe(ref, "Bend reference test", False{})
        renamed : Window <- Window.set_title(window, "Bend reference renamed")
        IO.bind(Window & Result<&1, &1, U32 & String, WindowRef>, Unit,
          Window.export_ref(renamed), repeated(ref, ok))
    case Fail{(+code, text)}:
      refused((U32.is_eq(code, 45) || U32.is_eq(code, 95)) && String.eq(text,
        "Window.export_ref: external reference is unavailable on this backend"), window)

def opened(result: Result<&1, &1, U32 & String, Window>) -> IO(Unit):
  match result:
    case Done{window}:
      IO.bind(Window & Result<&1, &1, U32 & String, WindowRef>, Unit,
        Window.export_ref(window), first)
    case Fail{(+code, text)}:
      report((U32.is_eq(code, 45) || U32.is_eq(code, 95)) && String.eq(text,
        "Window.open: no display (build a native binary with bend <file> -o <out> and run it from a desktop session)"))

def main() -> IO(Unit):
  IO.bind(Result<&1, &1, U32 & String, Window>, Unit,
    Window.open("Bend reference test", 320, 200), opened)

#|window reference: OK
