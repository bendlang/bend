# EX: erased fields among a node's boxed ones (-e1: Nat, l: EX, -e2: Nat, k: U32, r: EX)
import Base


type EX is Data:
  EXL{}
  EXN{-e1: Nat, l: EX, -e2: Nat, k: U32, r: EX}

def dig(t: EX, +acc: U32) -> U32:
  match t:
    case EXL{}:
      U32.add(U32.mul(acc, 29), 5)
    case EXN{e1, l, e2, k, r}:
      dig(r, U32.add(U32.mul(dig(l, U32.add(U32.mul(acc, 29), 0)), 137), k))

def gen(+d: Nat, +i: U32) -> EX:
  match d:
    case 0n:
      EXL{}
    case 1n+e:
      EXN{3n, gen(e, U32.mul(i, 2)), e, i, gen(e, U32.add(U32.mul(i, 2), 1))}

def same(t: EX) -> EX:
  match t:
    case EXL{}:
      EXL{}
    case EXN{e1, l, e2, k, r}:
      EXN{e1, l, e2, k, r}

def renum(t: EX) -> EX:
  match t:
    case EXL{}:
      EXL{}
    case EXN{e1, l, e2, k, r}:
      EXN{7n, l, 7n, k, r}

def swap(t: EX) -> EX:
  match t:
    case EXL{}:
      EXL{}
    case EXN{e1, l, e2, k, r}:
      EXN{e1, r, e2, k, l}

def peek(t: EX) -> EX & U32:
  match t:
    case EXL{}:
      (EXL{}, 0)
    case EXN{e1, l, e2, +k, r}:
      (EXN{e1, l, e2, k, r}, k)

def look(t: EX) -> EX:
  match t:
    case EXN{e1, EXN{e12, l2, e22, +k2, r2}, e2, k, r}:
      EXN{e1, EXN{e12, l2, e22, k2, r2}, e2, U32.add(k, k2), r}
    case t0:
      t0

def ins(t: EX, o: Cmp, +x: U32) -> EX:
  match t o:
    case EXL{} _:
      EXN{3n, EXL{}, 0n, x, EXL{}}
    case EXN{e1, EXN{e12, l2, e22, +k2, r2}, e2, k, r} LT{}:
      EXN{e1, ins(EXN{e12, l2, e22, k2, r2}, U32.cmp(x, k2), x), e2, k, r}
    case EXN{e1, EXL{}, e2, k, r} LT{}:
      EXN{e1, EXN{3n, EXL{}, 0n, x, EXL{}}, e2, k, r}
    case EXN{e1, l, e2, k, EXN{e12, l2, e22, +k2, r2}} GT{}:
      EXN{e1, l, e2, k, ins(EXN{e12, l2, e22, k2, r2}, U32.cmp(x, k2), x)}
    case EXN{e1, l, e2, k, EXL{}} GT{}:
      EXN{e1, l, e2, k, EXN{3n, EXL{}, 0n, x, EXL{}}}
    case EXN{e1, l, e2, k, r} EQ{}:
      EXN{e1, l, e2, U32.add(k, 1), r}

def build(+n: Nat, t: EX) -> EX:
  match n:
    case 0n:
      t
    case 1n+m:
      +x = U32.mod(U32.mul(U32.from_nat(n), 2654435761), 1000)
      build(m, ins(t, U32.cmp(x, 500), x))

def push(-n: Nat, z: Bool, t: EX, acc: List<&2, EX>) -> List<&2, EX>:
  match z:
    case True{}:
      t <> acc
    case False{}:
      acc

def sum(xs: List<&2, EX>, +acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case t <> r:
      sum(r, dig(t, acc))

def pdig(p: EX & U32) -> U32:
  (t, k) = p
  dig(t, k)

def uniq(+d: Nat, +i: U32) -> U32:
  U32.add(dig(same(gen(d, i)), 1), U32.add(dig(renum(gen(d, i)), 2), U32.add(dig(swap(gen(d, i)), 3), U32.add(pdig(peek(gen(d, i))), U32.add(dig(look(gen(d, i)), 4), dig(build(9n, gen(d, i)), 5))))))

def shar(+d: Nat, +i: U32) -> U32:
  +t = gen(d, i)
  z = sum(push(0n, U32.is_eq(U32.mod(i, 2), 0), t, push(1n, U32.is_eq(U32.mod(i, 3), 0), t, push(2n, U32.is_ne(U32.mod(i, 2), 0), t, []))), 0)
  U32.add(z, U32.add(dig(same(t), 1), U32.add(dig(renum(t), 2), U32.add(dig(swap(t), 3), U32.add(pdig(peek(t)), U32.add(dig(look(t), 4), U32.add(dig(build(9n, t), 5), dig(t, 0))))))))

def par(+n: Nat, +t: EX) -> U32:
  match n:
    case 0n:
      dig(t, 1)
    case 1n+p:
      a b = dig(build(7n, t), 0) par(p, t)
      c e = dig(look(t), 2) dig(same(t), 3)
      U32.add(U32.add(a, b), U32.add(c, e))

def loop(+n: Nat, acc: U32) -> U32:
  match n:
    case 0n:
      acc
    case 1n+p:
      +i = U32.from_nat(n)
      loop(p, U32.add(acc, U32.add(uniq(3n, i), shar(3n, i))))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(uniq(5n, 1)))
    Unit <- IO.print(U32.show(shar(5n, 1)))
    Unit <- IO.print(U32.show(uniq(0n, 2)))
    Unit <- IO.print(U32.show(shar(1n, 3)))
    Unit <- IO.print(U32.show(dig(build(3000n, EXL{}), 7)))
    Unit <- IO.print(U32.show(par(60n, gen(6n, 1))))
    IO.print(U32.show(loop(100n, 0)))

#|45381032
#|725660880
#|1532107163
#|1407112325
#|812511188
#|1800473465
#|3666819872
