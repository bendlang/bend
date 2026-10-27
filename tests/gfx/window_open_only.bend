# A program may call Window.open without Window.frame, so only window.c
# names the Event constructors. Its C build once failed on their ids. A zero
# width fails before Window.open looks for a display.
import Base

def opened(result: Result<&1, &1, U32 & String, Window>) -> IO(Unit):
  match result:
    case Done{window}:
      IO.print("opened")
    case Fail{error}:
      IO.print("failed")

def main() -> IO(Unit):
  do IO<Unit>:
    result : Result<&1, &1, U32 & String, Window> <- Window.open("Bend", 0, 48)
    opened(result)

#|failed
