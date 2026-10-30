# gfx (gfx_clicks): the reporter's program of #857. On a display it opens a
# window and prints a line per Press event; click another app, then click the
# window once: that click prints "press down=True" then "press down=False"
# (a view that refuses the first mouse would drop both). Without a display
# Window.open Fails with one line.
import Base

def tick(events: List<Event>, n: U32) -> IO(Maybe<U32>):
  match events:
    case Nil{}:
      IO.pure(Maybe<U32>, Some{n})
    case Con{Close{}, rest}:
      IO.pure(Maybe<U32>, None{})
    case Con{Press{i, t, x, y, ms, b, d}, rest}:
      do IO<Maybe<U32>>:
        IO.print("press down=" ++ Bool.show(d))
        tick(rest, n)
    case Con{e, rest}:
      tick(rest, n)

def opened(r: Result<&1, &1, U32 & String, Window>) -> IO(Unit):
  match r:
    case Fail{(code, text)}:
      IO.print(text)
    case Done{w}:
      App.loop(~U32, ~App{+s => (s, Pix{s}), tick}, U32.to_nat(4294967295),
        w, 0)

def main() -> IO(Unit):
  do IO<Unit>:
    r : Result<&1, &1, U32 & String, Window> <- Window.open("Clicks", 256, 256)
    opened(r)

#|Window.open: no display (build a native binary with bend <file> -o <out> and run it from a desktop session)
