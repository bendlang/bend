import Base

def quit(events: List<Event>) -> Bool:
  match events:
    case Nil{}:
      False{}
    case Close{} <> rest:
      True{}
    case event <> rest:
      quit(rest)

def continue_or_close(stop: Bool, window: Window,
  next: Window -> IO(Unit)) -> IO(Unit):
  match stop:
    case True{}:
      Window.close(window)
    case False{}:
      do IO<Unit>:
        IO.sleep(50)
        next(window)

def framed(q: Window & Image & List<Event>,
  next: Window -> IO(Unit)) -> IO(Unit):
  (window, image, events) = q
  continue_or_close(quit(events), window, next)

def pump(fuel: Nat, window: Window) -> IO(Unit):
  match fuel:
    case 0n:
      Window.close(window)
    case 1n+rest:
      do IO<Unit>:
        q : Window & Image & List<Event> <- Window.frame(window, Pix{4278190335})
        framed(q, w => pump(rest, w))

def exported(q: Window & Result<&1, &1, U32 & String, WindowRef>) -> IO(Unit):
  (window, result) = q
  match result:
    case Done{X11WindowRef{display, id}}:
      do IO<Unit>:
        IO.print("DISPLAY=" ++ display)
        IO.print("XID=" ++ U32.show(id))
        pump(600n, window)
    case Fail{(code, text)}:
      do IO<Unit>:
        IO.print("export failed " ++ U32.show(code) ++ ": " ++ text)
        Window.close(window)

def opened(result: Result<&1, &1, U32 & String, Window>) -> IO(Unit):
  match result:
    case Fail{(code, text)}:
      IO.print("open failed " ++ U32.show(code) ++ ": " ++ text)
    case Done{window}:
      IO.bind(Window & Result<&1, &1, U32 & String, WindowRef>, Unit,
        Window.export_ref(window), exported)

def main() -> IO(Unit):
  IO.bind(Result<&1, &1, U32 & String, Window>, Unit,
    Window.open("Bend external reference", 320, 200), opened)
