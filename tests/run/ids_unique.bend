# every name gets its own C id, numbered when its spelling is taken: a
# constructor done beside Base's Done (#989), a def a.b beside a_b, and
# defs named like the runtime's own segments (io_emit, clo_apply) once
# met in one CID_ or FID_ macro, and the C build refused or merged them;
# each def walks the arguments, not in tail position, so it stays a
# segment of its own
import Base

type Lower is Data:
  done{}

def lower(l: Lower) -> U32:
  match l:
    case done{}:
      1

def a.b(xs: List<String>) -> U32:
  match xs:
    case Nil{}:
      10
    case h <> t:
      (a.b(t) + 1 : U32)

def a_b(xs: List<String>) -> U32:
  match xs:
    case Nil{}:
      100
    case h <> t:
      (a_b(t) + 1 : U32)

def io_emit(xs: List<String>) -> U32:
  match xs:
    case Nil{}:
      1000
    case h <> t:
      (io_emit(t) + 1 : U32)

def clo_apply(xs: List<String>) -> U32:
  match xs:
    case Nil{}:
      10000
    case h <> t:
      (clo_apply(t) + 1 : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    w : List<String> <- IO.args()
    x : List<String> <- IO.args()
    y : List<String> <- IO.args()
    z : List<String> <- IO.args()
    IO.print(U32.show((lower(done{}) + a.b(w) + a_b(x) + io_emit(y)
      + clo_apply(z) : U32)))

#|11111
