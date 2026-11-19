# EE: erased fields among a node's boxed ones (l: EE, k: U32, r: EE, -e1: Nat)
import Base


type EE is Data:
  EEL{}
  EEN{l: EE, k: U32, r: EE, -e1: Nat}

def dig(t: EE, +acc: U32) -> U32:
  match t:
    case EEL{}:
      U32.add(U32.mul(acc, 29), 5)
    case EEN{l, k, r, e1}:
      dig(r, U32.add(U32.mul(dig(l, U32.add(U32.mul(acc, 29), 0)), 137), k))

def gen(+d: Nat, +i: U32) -> EE:
  match d:
    case 0n:
      EEL{}
    case 1n+e:
      EEN{gen(e, U32.mul(i, 2)), i, gen(e, U32.add(U32.mul(i, 2), 1)), 3n}

def same(t: EE) -> EE:
  match t:
    case EEL{}:
      EEL{}
    case EEN{l, k, r, e1}:
      EEN{l, k, r, e1}

def renum(t: EE) -> EE:
  match t:
    case EEL{}:
      EEL{}
    case EEN{l, k, r, e1}:
      EEN{l, k, r, 7n}

def swap(t: EE) -> EE:
  match t:
    case EEL{}:
      EEL{}
    case EEN{l, k, r, e1}:
      EEN{r, k, l, e1}

def peek(t: EE) -> EE & U32:
  match t:
    case EEL{}:
      (EEL{}, 0)
    case EEN{l, +k, r, e1}:
      (EEN{l, k, r, e1}, k)

def look(t: EE) -> EE:
  match t:
    case EEN{EEN{l2, +k2, r2, e12}, k, r, e1}:
      EEN{EEN{l2, k2, r2, e12}, U32.add(k, k2), r, e1}
    case t0:
      t0

def ins(t: EE, o: Cmp, +x: U32) -> EE:
  match t o:
    case EEL{} _:
      EEN{EEL{}, x, EEL{}, 3n}
    case EEN{EEN{l2, +k2, r2, e12}, k, r, e1} LT{}:
      EEN{ins(EEN{l2, k2, r2, e12}, U32.cmp(x, k2), x), k, r, e1}
    case EEN{EEL{}, k, r, e1} LT{}:
      EEN{EEN{EEL{}, x, EEL{}, 3n}, k, r, e1}
    case EEN{l, k, EEN{l2, +k2, r2, e12}, e1} GT{}:
      EEN{l, k, ins(EEN{l2, k2, r2, e12}, U32.cmp(x, k2), x), e1}
    case EEN{l, k, EEL{}, e1} GT{}:
      EEN{l, k, EEN{EEL{}, x, EEL{}, 3n}, e1}
    case EEN{l, k, r, e1} EQ{}:
      EEN{l, U32.add(k, 1), r, e1}

def build(+n: Nat, t: EE) -> EE:
  match n:
    case 0n:
      t
    case 1n+m:
      +x = U32.mod(U32.mul(U32.from_nat(n), 2654435761), 1000)
      build(m, ins(t, U32.cmp(x, 500), x))

def push(-n: Nat, z: Bool, t: EE, acc: List<&2, EE>) -> List<&2, EE>:
  match z:
    case True{}:
      t <> acc
    case False{}:
      acc

def sum(xs: List<&2, EE>, +acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case t <> r:
      sum(r, dig(t, acc))

def pdig(p: EE & U32) -> U32:
  (t, k) = p
  dig(t, k)

def uniq(+d: Nat, +i: U32) -> U32:
  U32.add(dig(same(gen(d, i)), 1), U32.add(dig(renum(gen(d, i)), 2), U32.add(dig(swap(gen(d, i)), 3), U32.add(pdig(peek(gen(d, i))), U32.add(dig(look(gen(d, i)), 4), dig(build(9n, gen(d, i)), 5))))))

def shar(+d: Nat, +i: U32) -> U32:
  +t = gen(d, i)
  z = sum(push(0n, U32.is_eq(U32.mod(i, 2), 0), t, push(1n, U32.is_eq(U32.mod(i, 3), 0), t, push(2n, U32.is_ne(U32.mod(i, 2), 0), t, []))), 0)
  U32.add(z, U32.add(dig(same(t), 1), U32.add(dig(renum(t), 2), U32.add(dig(swap(t), 3), U32.add(pdig(peek(t)), U32.add(dig(look(t), 4), U32.add(dig(build(9n, t), 5), dig(t, 0))))))))

def par(+n: Nat, +t: EE) -> U32:
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
    Unit <- IO.print(U32.show(dig(build(3000n, EEL{}), 7)))
    Unit <- IO.print(U32.show(par(60n, gen(6n, 1))))
    IO.print(U32.show(loop(100n, 0)))

#|45381032
#|725660880
#|1532107163
#|1407112325
#|812511188
#|1800473465
#|3666819872
