# F32.show and F32.read print and parse through libc, which the device
# lacks: a bang that may reach one runs on the host, directly (sh, rd)
# or through a closure its parameter holds (ap), while a bang that
# reaches neither (sq) still goes to the device; every lane prints the
# same line
import Base

def sq(+x: U32) -> U32:
  (x * x : U32)

def sh(x: F32) -> String:
  F32.show(x)

def rd(s: String) -> F32:
  Maybe.default(&2, F32, F32.read(s), 0.0)

def ap(f: F32 -> String, x: F32) -> String:
  f(x)

def main() -> IO(Unit):
  IO.print(String.append(U32.show(sq!(7)), String.append(" ",
    String.append(sh!(1.5), String.append(" ", String.append(
    F32.show(rd!("2.25")), String.append(" ",
    ap!(x => String.append("v=", F32.show(x)), 2.5))))))))

#|49 1.5 2.25 v=2.5
