# EF: erased fields among a node's boxed ones (-e1: Nat, l: EF, k: U32, r: EF)
import Base


type EF is Data:
  EFL{}
  EFN{-e1: Nat, l: EF, k: U32, r: EF}

def dig(t: EF, +acc: U32) -> U32:
  match t:
    case EFL{}:
      U32.add(U32.mul(acc, 29), 5)
    case EFN{e1, l, k, r}:
      dig(r, U32.add(U32.mul(dig(l, U32.add(U32.mul(acc, 29), 0)), 137), k))

def gen(+d: Nat, +i: U32) -> EF:
  match d:
    case 0n:
      EFL{}
    case 1n+e:
      EFN{3n, gen(e, U32.mul(i, 2)), i, gen(e, U32.add(U32.mul(i, 2), 1))}

def same(t: EF) -> EF:
  match t:
    case EFL{}:
      EFL{}
    case EFN{e1, l, k, r}:
      EFN{e1, l, k, r}

def renum(t: EF) -> EF:
  match t:
    case EFL{}:
      EFL{}
    case EFN{e1, l, k, r}:
      EFN{7n, l, k, r}

def swap(t: EF) -> EF:
  match t:
    case EFL{}:
      EFL{}
    case EFN{e1, l, k, r}:
      EFN{e1, r, k, l}

def peek(t: EF) -> EF & U32:
  match t:
    case EFL{}:
      (EFL{}, 0)
    case EFN{e1, l, +k, r}:
      (EFN{e1, l, k, r}, k)

def look(t: EF) -> EF:
  match t:
    case EFN{e1, EFN{e12, l2, +k2, r2}, k, r}:
      EFN{e1, EFN{e12, l2, k2, r2}, U32.add(k, k2), r}
    case t0:
      t0

def ins(t: EF, o: Cmp, +x: U32) -> EF:
  match t o:
    case EFL{} _:
      EFN{3n, EFL{}, x, EFL{}}
    case EFN{e1, EFN{e12, l2, +k2, r2}, k, r} LT{}:
      EFN{e1, ins(EFN{e12, l2, k2, r2}, U32.cmp(x, k2), x), k, r}
    case EFN{e1, EFL{}, k, r} LT{}:
      EFN{e1, EFN{3n, EFL{}, x, EFL{}}, k, r}
    case EFN{e1, l, k, EFN{e12, l2, +k2, r2}} GT{}:
      EFN{e1, l, k, ins(EFN{e12, l2, k2, r2}, U32.cmp(x, k2), x)}
    case EFN{e1, l, k, EFL{}} GT{}:
      EFN{e1, l, k, EFN{3n, EFL{}, x, EFL{}}}
    case EFN{e1, l, k, r} EQ{}:
      EFN{e1, l, U32.add(k, 1), r}

def build(+n: Nat, t: EF) -> EF:
  match n:
    case 0n:
      t
    case 1n+m:
      +x = U32.mod(U32.mul(U32.from_nat(n), 2654435761), 1000)
      build(m, ins(t, U32.cmp(x, 500), x))

def push(-n: Nat, z: Bool, t: EF, acc: List<&2, EF>) -> List<&2, EF>:
  match z:
    case True{}:
      t <> acc
    case False{}:
      acc

def sum(xs: List<&2, EF>, +acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case t <> r:
      sum(r, dig(t, acc))

def pdig(p: EF & U32) -> U32:
  (t, k) = p
  dig(t, k)

def uniq(+d: Nat, +i: U32) -> U32:
  U32.add(dig(same(gen(d, i)), 1), U32.add(dig(renum(gen(d, i)), 2), U32.add(dig(swap(gen(d, i)), 3), U32.add(pdig(peek(gen(d, i))), U32.add(dig(look(gen(d, i)), 4), dig(build(9n, gen(d, i)), 5))))))

def shar(+d: Nat, +i: U32) -> U32:
  +t = gen(d, i)
  z = sum(push(0n, U32.is_eq(U32.mod(i, 2), 0), t, push(1n, U32.is_eq(U32.mod(i, 3), 0), t, push(2n, U32.is_ne(U32.mod(i, 2), 0), t, []))), 0)
  U32.add(z, U32.add(dig(same(t), 1), U32.add(dig(renum(t), 2), U32.add(dig(swap(t), 3), U32.add(pdig(peek(t)), U32.add(dig(look(t), 4), U32.add(dig(build(9n, t), 5), dig(t, 0))))))))

def par(+n: Nat, +t: EF) -> U32:
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
    Unit <- IO.print(U32.show(dig(build(3000n, EFL{}), 7)))
    Unit <- IO.print(U32.show(par(60n, gen(6n, 1))))
    IO.print(U32.show(loop(100n, 0)))

#|45381032
#|725660880
#|1532107163
#|1407112325
#|812511188
#|1800473465
#|3666819872
