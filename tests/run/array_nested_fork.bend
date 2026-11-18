# Match both handles from Array.fork when a record contains nested arrays.
import Base

type Holder is Type:
  End{numbers: Array<U32>, texts: Array<String>}
  Link{tail: Holder}

def number(p: Array<U32> & U32) -> Nat:
  (a, x) = p
  U32.to_nat(x)

def text(p: Array<String> & String) -> Nat:
  (a, s) = p
  String.length(s)

def score(h: Holder) -> Nat:
  match h:
    case End{a, b}:
      Nat.add(number(Array.get(U32, a, 0)), text(Array.get(String, b, 0)))
    case Link{tail}:
      score(tail)

def read(a: Array<Holder>) -> Nat:
  match a:
    case ALeaf{h}: score(h)
    case ANode{l, r}: Nat.add(read(l), read(r))

def twice(p: Array<Holder> & Array<Holder>) -> Nat:
  (a, b) = p
  Nat.add(read(a), read(b))

def make(+n: Nat) -> Holder:
  End{Array.new(U32, 1n, U32.from_nat(n)),
    Array.new(String, 1n, String.repeat("x", n))}

def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    +n : Nat = List.length(&1, String, args)
    IO.print(Nat.show(twice(Array.fork(Holder, ALeaf{make(n)}))))
    IO.print(Nat.show(twice(Array.fork(Holder, ALeaf{Link{make(n)}}))))
    IO.print(Nat.show(twice(Array.fork(Holder,
      Array.set(Holder, ALeaf{make(n)}, 0, Link{make(Nat.add(n, 1n))})))))

#|4
#|4
#|8
