import Base

def WindowRefTest.make() -> IO(Window):
  import "./window_export_js.js"

def WindowRefTest.same(window: Window) -> IO(Window & Bool):
  import "./window_export_js.js"

def report(ok: Bool) -> IO(Unit):
  match ok:
    case True{}:
      IO.print("ENOTSUP and same owner")
    case False{}:
      IO.print("bad export")

def checked(ok: Bool, q: Window & Bool) -> IO(Unit):
  (window, same) = q
  do IO<Unit>:
    Window.close(window)
    report(ok && same)

def exported(q: Window & Result<&1, &1, U32 & String, WindowRef>) -> IO(Unit):
  (window, result) = q
  match result:
    case Fail{(+code, text)}:
      ok = (U32.is_eq(code, 45) || U32.is_eq(code, 95))
        && String.eq(text,
          "Window.export_ref: external reference is unavailable on this backend")
      IO.bind(Window & Bool, Unit, WindowRefTest.same(window), checked(ok))
    case Done{ref}:
      do IO<Unit>:
        Window.close(window)
        IO.print("unexpected native reference")

def main() -> IO(Unit):
  do IO<Unit>:
    window : Window <- WindowRefTest.make()
    IO.bind(Window & Result<&1, &1, U32 & String, WindowRef>, Unit,
      Window.export_ref(window), exported)

#|ENOTSUP and same owner
