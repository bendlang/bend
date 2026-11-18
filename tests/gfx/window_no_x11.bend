# gfx (gfx_window_no_x11): a Window program must start without libX11.
# Before the fix, -lX11 made the loader require it even when the program
# never opened a window. x11.absent asks dl_iterate_phdr before any display
# work; the width-0 open is the nearby control, failing before a display.
import Base

def x11.absent() -> IO(Bool):
  import "./window_no_x11.c"
  import "./window_no_x11.js"

def opened(result: Result<&1, &1, U32 & String, Window>) -> IO(Unit):
  match result:
    case Done{window}:
      do IO<Unit>:
        Window.close(window)
        IO.print("opened")
    case Fail{error}:
      IO.print("failed")

def main() -> IO(Unit):
  do IO<Unit>:
    absent : Bool <- x11.absent()
    IO.print(Bool.show(absent))
    result : Result<&1, &1, U32 & String, Window> <- Window.open("Bend", 0, 48)
    opened(result)

#|True
#|failed
