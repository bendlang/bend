# drop: a datatype whose nullary constructor acts as its other one at zero
# fields at every match (Acc0{} as Acc{0, 0}) is built as that and keeps
# one constructor; Cnt below fails that at one match (cnt.show answers 9
# for Cnt0{}, not 0), so it keeps both, and Opt's default is matched by a
# catch-all arm, so it keeps both too; Wrap and Vv agree only under a wrong
# fold or a wrong unit.
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

type Vv is Data:
  V0{}
  V{n: U32}

type Pt is Data:
  P0{}
  Pt{x: U32}

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

# V0{} answers k, V{0} answers k + 1: not the same
def v.show(w: Vv, +k: U32) -> U32:
  match w:
    case V0{}:
      k
    case V{n}:
      U32.add(k, U32.add(n, 1))

# pt.show treats P0{} as Pt{0}; pt.bad, called only from a let's value,
# does not (it answers 7), so Pt keeps both
def pt.show(p: Pt) -> U32:
  match p:
    case P0{}:
      0
    case Pt{x}:
      x

def pt.bad(p: Pt) -> U32:
  match p:
    case P0{}:
      7
    case Pt{x}:
      x

def opt.get(o: Opt) -> U32:
  match o:
    case Opt{v}:
      v
    case _:
      0

# every argument is read at run time (one is 1 with no arguments), so no
# call is evaluated by the compiler
def main() -> IO(Unit):
  do IO<Unit>:
    args : List<String> <- IO.args()
    +one : Nat = List.length(&1, String, args)
    +u : U32 = U32.from_nat(one)
    +pb : U32 = pt.bad(P0{})
    +a0 : Acc = walk(Nat.mul(0n, one), U32.mul(5, u), Acc0{})
    IO.print(U32.show(acc.show(merge(walk(Nat.mul(100n, one), U32.sub(u, 1), Acc0{}), a0))))
    IO.print(U32.show(acc.show(merge(walk(Nat.sub(one, 1n), u, Acc0{}), Acc0{}))))
    IO.print(U32.show(cnt.show(cnt(Nat.sub(one, 1n), Cnt0{}))))
    IO.print(U32.show(cnt.show(cnt(Nat.mul(5n, one), Cnt0{}))))
    IO.print(U32.show(U32.add(opt.get(Opt0{}), opt.get(Opt{U32.mul(4, u)}))))
    IO.print(U32.show(U32.add(wrap.show(W0{}), wrap.show(W{u}))))
    IO.print(U32.show(U32.add(v.show(V0{}, U32.mul(7, u)), v.show(V{u}, u))))
    IO.print(U32.show(U32.add(pb, U32.add(pt.show(P0{}), pt.show(Pt{u})))))

#|100004218
#|0
#|9
#|5
#|4
#|4294967295
#|10
#|8
