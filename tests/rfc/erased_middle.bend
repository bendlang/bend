# EM: erased fields among a node's boxed ones (l: EM, -e1: Nat, k: U32, r: EM)
import Base


type EM is Data:
  EML{}
  EMN{l: EM, -e1: Nat, k: U32, r: EM}

def dig(t: EM, +acc: U32) -> U32:
  match t:
    case EML{}:
      U32.add(U32.mul(acc, 29), 5)
    case EMN{l, e1, k, r}:
      dig(r, U32.add(U32.mul(dig(l, U32.add(U32.mul(acc, 29), 0)), 137), k))

def gen(+d: Nat, +i: U32) -> EM:
  match d:
    case 0n:
      EML{}
    case 1n+e:
      EMN{gen(e, U32.mul(i, 2)), 3n, i, gen(e, U32.add(U32.mul(i, 2), 1))}

def same(t: EM) -> EM:
  match t:
    case EML{}:
      EML{}
    case EMN{l, e1, k, r}:
      EMN{l, e1, k, r}

def renum(t: EM) -> EM:
  match t:
    case EML{}:
      EML{}
    case EMN{l, e1, k, r}:
      EMN{l, 7n, k, r}

def swap(t: EM) -> EM:
  match t:
    case EML{}:
      EML{}
    case EMN{l, e1, k, r}:
      EMN{r, e1, k, l}

def peek(t: EM) -> EM & U32:
  match t:
    case EML{}:
      (EML{}, 0)
    case EMN{l, e1, +k, r}:
      (EMN{l, e1, k, r}, k)

def look(t: EM) -> EM:
  match t:
    case EMN{EMN{l2, e12, +k2, r2}, e1, k, r}:
      EMN{EMN{l2, e12, k2, r2}, e1, U32.add(k, k2), r}
    case t0:
      t0

def ins(t: EM, o: Cmp, +x: U32) -> EM:
  match t o:
    case EML{} _:
      EMN{EML{}, 3n, x, EML{}}
    case EMN{EMN{l2, e12, +k2, r2}, e1, k, r} LT{}:
      EMN{ins(EMN{l2, e12, k2, r2}, U32.cmp(x, k2), x), e1, k, r}
    case EMN{EML{}, e1, k, r} LT{}:
      EMN{EMN{EML{}, 3n, x, EML{}}, e1, k, r}
    case EMN{l, e1, k, EMN{l2, e12, +k2, r2}} GT{}:
      EMN{l, e1, k, ins(EMN{l2, e12, k2, r2}, U32.cmp(x, k2), x)}
    case EMN{l, e1, k, EML{}} GT{}:
      EMN{l, e1, k, EMN{EML{}, 3n, x, EML{}}}
    case EMN{l, e1, k, r} EQ{}:
      EMN{l, e1, U32.add(k, 1), r}

def build(+n: Nat, t: EM) -> EM:
  match n:
    case 0n:
      t
    case 1n+m:
      +x = U32.mod(U32.mul(U32.from_nat(n), 2654435761), 1000)
      build(m, ins(t, U32.cmp(x, 500), x))

def push(-n: Nat, z: Bool, t: EM, acc: List<&2, EM>) -> List<&2, EM>:
  match z:
    case True{}:
      t <> acc
    case False{}:
      acc

def sum(xs: List<&2, EM>, +acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case t <> r:
      sum(r, dig(t, acc))

def pdig(p: EM & U32) -> U32:
  (t, k) = p
  dig(t, k)

def uniq(+d: Nat, +i: U32) -> U32:
  U32.add(dig(same(gen(d, i)), 1), U32.add(dig(renum(gen(d, i)), 2), U32.add(dig(swap(gen(d, i)), 3), U32.add(pdig(peek(gen(d, i))), U32.add(dig(look(gen(d, i)), 4), dig(build(9n, gen(d, i)), 5))))))

def shar(+d: Nat, +i: U32) -> U32:
  +t = gen(d, i)
  z = sum(push(0n, U32.is_eq(U32.mod(i, 2), 0), t, push(1n, U32.is_eq(U32.mod(i, 3), 0), t, push(2n, U32.is_ne(U32.mod(i, 2), 0), t, []))), 0)
  U32.add(z, U32.add(dig(same(t), 1), U32.add(dig(renum(t), 2), U32.add(dig(swap(t), 3), U32.add(pdig(peek(t)), U32.add(dig(look(t), 4), U32.add(dig(build(9n, t), 5), dig(t, 0))))))))

def par(+n: Nat, +t: EM) -> U32:
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
    Unit <- IO.print(U32.show(dig(build(3000n, EML{}), 7)))
    Unit <- IO.print(U32.show(par(60n, gen(6n, 1))))
    IO.print(U32.show(loop(100n, 0)))

#|45381032
#|725660880
#|1532107163
#|1407112325
#|812511188
#|1800473465
#|3666819872
