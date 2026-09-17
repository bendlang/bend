# float text: F32.show is printf's %g (a JS emulation past exact
# ties), F32.read strtof's grammar behind a whole-string gate, so a
# spelling reads back to its value and a non-number answers None
import Base

law seen:
  for m: Maybe<&2, F32>
  String

def seen(m):
  match m:
    case None{}:
      "none"
    case Some{v}:
      F32.show(v)

law main.out:
  String

def main.out():
  a = seen(F32.read("2.5"))
  b = seen(F32.read("0.1"))
  c = seen(F32.read("hi"))
  d = seen(F32.read(""))
  e = seen(F32.read(F32.show(1.25)))
  a ++ " " ++ b ++ " " ++ c ++ " " ++ d ++ " " ++ e

law main:
  IO(Unit)

def main():
  IO.print(main.out())

#|2.5 0.1 none none 1.25
