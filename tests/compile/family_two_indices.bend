# compile (facts_hot): a family over two indices is a match per index. A
# node shared through the stuck family type (a : Mat(p, q)) heats every
# arm of every index, else the C lane opens the shared MatQ with term_loc
# and faults. The depth comes from the command line so the fold cannot
# see it: 2 plus the argument count, 2 in the harness.
import Base

type Mat.Leaf is Data:
  MatB{x: U32}

type Mat.Quad<-p: Nat, -q: Nat> is Data:
  MatQ{tl: Mat(p, q), tr: Mat(p, q), bl: Mat(p, q), br: Mat(p, q)}

def Mat(r: Nat, c: Nat) -> Data:
  match r c:
    case 0n 0n:
      Mat.Leaf
    case 1n+p 0n:
      Mat.Leaf
    case 0n 1n+q:
      Mat.Leaf
    case 1n+p 1n+q:
      Mat.Quad<p, q>

def Mat.full(+r: Nat, +c: Nat, +x: U32) -> Mat(r, c):
  match r c:
    case 0n 0n:
      MatB{x}
    case 1n+p 0n:
      MatB{x}
    case 0n 1n+q:
      MatB{x}
    case 1n+p 1n+q:
      a b c2 d = Mat.full(p, q, x) Mat.full(p, q, x) Mat.full(p, q, x) Mat.full(p, q, x)
      MatQ{a, b, c2, d}

# the sum with every quadrant counted twice: 8^d at 2^d x 2^d
def Mat.sq(+r: Nat, +c: Nat, +m: Mat(r, c)) -> U32:
  match r c:
    case 0n 0n:
      MatB{x} = m
      x
    case 1n+p 0n:
      MatB{x} = m
      x
    case 0n 1n+q:
      MatB{x} = m
      x
    case 1n+p 1n+q:
      MatQ{a, b, c2, d} = m
      s t u v w x y z = Mat.sq(p, q, a) Mat.sq(p, q, a) Mat.sq(p, q, b) Mat.sq(p, q, b) Mat.sq(p, q, c2) Mat.sq(p, q, c2) Mat.sq(p, q, d) Mat.sq(p, q, d)
      (((s + t) + (u + v)) + ((w + x) + (y + z)) : U32)

def run(+d: Nat) -> U32:
  Mat.sq(d, d, Mat.full(d, d, 1))

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(U32.show(run(Nat.add(2n, List.length(&1, String, xs)))))

#|64
