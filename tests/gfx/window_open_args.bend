# Window.open checks its arguments before it looks for a display, on every
# lane: a NUL in the title is EILSEQ (92 on macOS, 84 on Linux), checked
# first, and a side outside 1..16384 is EINVAL. The JS lane once answered
# ENOTSUP (no display) for both.
import Base

def ilseq(yes: Bool, code: U32) -> String:
  match yes:
    case True{}:
      "EILSEQ"
    case False{}:
      U32.show(code)

def shown(+code: U32) -> String:
  ilseq(U32.is_eq(code, 92) || U32.is_eq(code, 84), code)

def opened(label: String, result: Result<&1, &1, U32 & String, Window>) ->
  IO(Unit):
  match result:
    case Done{window}:
      do IO<Unit>:
        frame : Window & Image & List<Event> <- Window.frame(window, Pix{0})
        Window.close(Pair.fst(Window, Image & List<Event>, frame))
        IO.print(label ++ ": opened")
    case Fail{(+code, message)}:
      IO.print(label ++ ": " ++ shown(code))

def check(label: String, title: String, width: U32, height: U32) -> IO(Unit):
  do IO<Unit>:
    result : Result<&1, &1, U32 & String, Window> <- Window.open(title, width,
      height)
    opened(label, result)

def main() -> IO(Unit):
  do IO<Unit>:
    check("zero width", "Bend", 0, 48)
    check("zero height", "Bend", 64, 0)
    check("too wide", "Bend", 16385, 48)
    check("too tall", "Bend", 64, 16385)
    check("nul title", SCon{Chr{66}, SCon{Chr{0}, SNil{}}}, 64, 48)
    check("nul title, zero size", SCon{Chr{0}, SNil{}}, 0, 0)

#|zero width: 22
#|zero height: 22
#|too wide: 22
#|too tall: 22
#|nul title: EILSEQ
#|nul title, zero size: EILSEQ
