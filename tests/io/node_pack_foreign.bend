# Foreign C lays out a type it names: P's Pn{c, l, k, b, r} would pack (5
# words to 3), but pmake's C writes its five words itself, so P keeps them.
import Base

type P is Data:
  Pe{}
  Pn{c: Bool, l: P, k: U32, b: Bool, r: P}

def pmake(n: U32) -> IO(P):
  import "./node_pack_foreign.c"
  import "./node_pack_foreign.js"

def bi(b: Bool) -> U32:
  match b:
    case False{}:
      3
    case True{}:
      5

def psum(p: P) -> U32:
  match p:
    case Pe{}:
      1
    case Pn{c, l, k, b, r}:
      (((psum(l) + psum(r) : U32) * 31 + k : U32) + (bi(c) * 7 + bi(b) : U32) : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    p : P <- pmake(4)
    IO.print(U32.show(psum(Pn{True{}, p, 4294967295, False{}, Pe{}})))

#|3702415158
