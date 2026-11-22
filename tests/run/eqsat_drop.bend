# eqsat: a datatype whose nullary constructor acts as its other one at zero
# fields at every match (Acc0{} as Acc{0, 0}) is built as that and keeps
# one constructor; Cnt below fails that at one match (cnt.show answers 9
# for Cnt0{}, not 0), so it keeps both, and Opt's default is matched by a
# catch-all arm, so it keeps both too.
import Base

type Acc is Data:
  Acc0{}
  Acc{n: U32, s: U32}

type Cnt is Data:
  Cnt0{}
  Cnt{n: U32}

type Wrap is Data:
  W0{}
  W{n: U32}

type Opt is Data:
  Opt0{}
  Opt{v: U32}

def walk(+k: Nat, +i: U32, a: Acc) -> Acc:
  match k a:
    case 0n Acc0{}:
      Acc{0, 0}
    case 0n Acc{n, s}:
      Acc{n, s}
    case 1n+p Acc0{}:
      walk(p, U32.inc(i), Acc{1, i})
    case 1n+p Acc{n, s}:
      walk(p, U32.inc(i), Acc{U32.inc(n), U32.add(s, i)})

def merge(a: Acc, b: Acc) -> Acc:
  match a b:
    case Acc{n1, s1} Acc{n2, s2}:
      Acc{U32.add(n1, n2), U32.add(s1, s2)}
    case Acc{n1, s1} Acc0{}:
      Acc{n1, s1}
    case Acc0{} Acc{n2, s2}:
      Acc{n2, s2}
    case Acc0{} Acc0{}:
      Acc0{}

def acc.show(a: Acc) -> U32:
  match a:
    case Acc0{}:
      0
    case Acc{n, s}:
      U32.xor(U32.mul(n, 1000003), s)

def cnt(+k: Nat, c: Cnt) -> Cnt:
  match k c:
    case 0n c0:
      c0
    case 1n+p Cnt0{}:
      cnt(p, Cnt{1})
    case 1n+p Cnt{n}:
      cnt(p, Cnt{U32.inc(n)})

def cnt.show(c: Cnt) -> U32:
  match c:
    case Cnt0{}:
      9
    case Cnt{n}:
      n

# W0{} answers 1 - 3 (wrapped), W{0} answers 3 - 1: not the same
def wrap.show(w: Wrap) -> U32:
  match w:
    case W0{}:
      4294967294
    case W{n}:
      U32.sub(3, U32.add(n, 1))

def opt.get(o: Opt) -> U32:
  match o:
    case Opt{v}:
      v
    case _:
      0

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(acc.show(merge(walk(100n, 0, Acc0{}), walk(0n, 5, Acc0{})))))
    IO.print(U32.show(acc.show(merge(Acc0{}, Acc0{}))))
    IO.print(U32.show(cnt.show(cnt(0n, Cnt0{}))))
    IO.print(U32.show(cnt.show(cnt(5n, Cnt0{}))))
    IO.print(U32.show(U32.add(opt.get(Opt0{}), opt.get(Opt{4}))))
    IO.print(U32.show(U32.add(wrap.show(W0{}), wrap.show(W{1}))))

#|100004218
#|0
#|9
#|5
#|4
#|4294967295
