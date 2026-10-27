# Window.open checks its arguments before it looks for a display, on every
# lane: a NUL in the title is EILSEQ (92 on macOS, 84 on Linux), checked
# first, and a side outside 1..16384 is EINVAL. The JS lane once answered
# ENOTSUP (no display) for both. A side of 1 or 16384 passes the checks: it
# opens a window, or fails with ENOTSUP (45 on macOS, 95 on Linux) where no
# display is, and either reads "accepted".
import Base

def ilseq(yes: Bool, code: U32) -> String:
  match yes:
    case True{}:
      "EILSEQ"
    case False{}:
      U32.show(code)

def headless(yes: Bool, +code: U32) -> String:
  match yes:
    case True{}:
      "accepted"
    case False{}:
      ilseq(U32.is_eq(code, 92) || U32.is_eq(code, 84), code)

def shown(+code: U32) -> String:
  headless(U32.is_eq(code, 45) || U32.is_eq(code, 95), code)

def opened(label: String, result: Result<&1, &1, U32 & String, Window>) ->
  IO(Unit):
  match result:
    case Done{window}:
      do IO<Unit>:
        frame : Window & Image & List<Event> <- Window.frame(window, Pix{0})
        Window.close(Pair.fst(Window, Image & List<Event>, frame))
        IO.print(label ++ ": accepted")
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
    check("smallest", "Bend", 1, 1)
    check("widest", "Bend", 16384, 1)
    check("tallest", "Bend", 1, 16384)

#|zero width: 22
#|zero height: 22
#|too wide: 22
#|too tall: 22
#|nul title: EILSEQ
#|nul title, zero size: EILSEQ
#|smallest: accepted
#|widest: accepted
#|tallest: accepted
