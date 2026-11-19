# EZ: erased fields among a node's boxed ones (l: EZ, -e1: Nat, -e2: Nat, r: EZ, k: U32)
import Base


type EZ is Data:
  EZL{}
  EZN{l: EZ, -e1: Nat, -e2: Nat, r: EZ, k: U32}

def dig(t: EZ, +acc: U32) -> U32:
  match t:
    case EZL{}:
      U32.add(U32.mul(acc, 29), 5)
    case EZN{l, e1, e2, r, k}:
      dig(r, U32.add(U32.mul(dig(l, U32.add(U32.mul(acc, 29), 0)), 137), k))

def gen(+d: Nat, +i: U32) -> EZ:
  match d:
    case 0n:
      EZL{}
    case 1n+e:
      EZN{gen(e, U32.mul(i, 2)), 3n, e, gen(e, U32.add(U32.mul(i, 2), 1)), i}

def same(t: EZ) -> EZ:
  match t:
    case EZL{}:
      EZL{}
    case EZN{l, e1, e2, r, k}:
      EZN{l, e1, e2, r, k}

def renum(t: EZ) -> EZ:
  match t:
    case EZL{}:
      EZL{}
    case EZN{l, e1, e2, r, k}:
      EZN{l, 7n, 7n, r, k}

def swap(t: EZ) -> EZ:
  match t:
    case EZL{}:
      EZL{}
    case EZN{l, e1, e2, r, k}:
      EZN{r, e1, e2, l, k}

def peek(t: EZ) -> EZ & U32:
  match t:
    case EZL{}:
      (EZL{}, 0)
    case EZN{l, e1, e2, r, +k}:
      (EZN{l, e1, e2, r, k}, k)

def look(t: EZ) -> EZ:
  match t:
    case EZN{EZN{l2, e12, e22, r2, +k2}, e1, e2, r, k}:
      EZN{EZN{l2, e12, e22, r2, k2}, e1, e2, r, U32.add(k, k2)}
    case t0:
      t0

def ins(t: EZ, o: Cmp, +x: U32) -> EZ:
  match t o:
    case EZL{} _:
      EZN{EZL{}, 3n, 0n, EZL{}, x}
    case EZN{EZN{l2, e12, e22, r2, +k2}, e1, e2, r, k} LT{}:
      EZN{ins(EZN{l2, e12, e22, r2, k2}, U32.cmp(x, k2), x), e1, e2, r, k}
    case EZN{EZL{}, e1, e2, r, k} LT{}:
      EZN{EZN{EZL{}, 3n, 0n, EZL{}, x}, e1, e2, r, k}
    case EZN{l, e1, e2, EZN{l2, e12, e22, r2, +k2}, k} GT{}:
      EZN{l, e1, e2, ins(EZN{l2, e12, e22, r2, k2}, U32.cmp(x, k2), x), k}
    case EZN{l, e1, e2, EZL{}, k} GT{}:
      EZN{l, e1, e2, EZN{EZL{}, 3n, 0n, EZL{}, x}, k}
    case EZN{l, e1, e2, r, k} EQ{}:
      EZN{l, e1, e2, r, U32.add(k, 1)}

def build(+n: Nat, t: EZ) -> EZ:
  match n:
    case 0n:
      t
    case 1n+m:
      +x = U32.mod(U32.mul(U32.from_nat(n), 2654435761), 1000)
      build(m, ins(t, U32.cmp(x, 500), x))

def push(-n: Nat, z: Bool, t: EZ, acc: List<&2, EZ>) -> List<&2, EZ>:
  match z:
    case True{}:
      t <> acc
    case False{}:
      acc

def sum(xs: List<&2, EZ>, +acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case t <> r:
      sum(r, dig(t, acc))

def pdig(p: EZ & U32) -> U32:
  (t, k) = p
  dig(t, k)

def uniq(+d: Nat, +i: U32) -> U32:
  U32.add(dig(same(gen(d, i)), 1), U32.add(dig(renum(gen(d, i)), 2), U32.add(dig(swap(gen(d, i)), 3), U32.add(pdig(peek(gen(d, i))), U32.add(dig(look(gen(d, i)), 4), dig(build(9n, gen(d, i)), 5))))))

def shar(+d: Nat, +i: U32) -> U32:
  +t = gen(d, i)
  z = sum(push(0n, U32.is_eq(U32.mod(i, 2), 0), t, push(1n, U32.is_eq(U32.mod(i, 3), 0), t, push(2n, U32.is_ne(U32.mod(i, 2), 0), t, []))), 0)
  U32.add(z, U32.add(dig(same(t), 1), U32.add(dig(renum(t), 2), U32.add(dig(swap(t), 3), U32.add(pdig(peek(t)), U32.add(dig(look(t), 4), U32.add(dig(build(9n, t), 5), dig(t, 0))))))))

def par(+n: Nat, +t: EZ) -> U32:
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
    Unit <- IO.print(U32.show(dig(build(3000n, EZL{}), 7)))
    Unit <- IO.print(U32.show(par(60n, gen(6n, 1))))
    IO.print(U32.show(loop(100n, 0)))

#|45381032
#|725660880
#|1532107163
#|1407112325
#|812511188
#|1800473465
#|3666819872
