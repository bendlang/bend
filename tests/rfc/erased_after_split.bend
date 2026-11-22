# EC: erased fields among a node's boxed ones (c: ColEC, -e1: Nat, l: EC, k: U32, r: EC)
import Base

type ColEC is Data:
  RedEC{}
  BlackEC{}

type EC is Data:
  ECL{}
  ECN{c: ColEC, -e1: Nat, l: EC, k: U32, r: EC}

def colEC(c: ColEC) -> U32:
  match c:
    case RedEC{}:
      1
    case BlackEC{}:
      2

def dig(t: EC, +acc: U32) -> U32:
  match t:
    case ECL{}:
      U32.add(U32.mul(acc, 29), 5)
    case ECN{c, e1, l, k, r}:
      dig(r, U32.add(U32.mul(dig(l, U32.add(U32.mul(acc, 29), colEC(c))), 137), k))

def pick(m: U32) -> ColEC:
  match m:
    case 0:
      RedEC{}
    case _:
      BlackEC{}

def gen(+d: Nat, +i: U32) -> EC:
  match d:
    case 0n:
      ECL{}
    case 1n+e:
      ECN{pick(U32.mod(i, 2)), 3n, gen(e, U32.mul(i, 2)), i, gen(e, U32.add(U32.mul(i, 2), 1))}

def same(t: EC) -> EC:
  match t:
    case ECL{}:
      ECL{}
    case ECN{c, e1, l, k, r}:
      ECN{c, e1, l, k, r}

def renum(t: EC) -> EC:
  match t:
    case ECL{}:
      ECL{}
    case ECN{c, e1, l, k, r}:
      ECN{c, 7n, l, k, r}

def swap(t: EC) -> EC:
  match t:
    case ECL{}:
      ECL{}
    case ECN{c, e1, l, k, r}:
      ECN{c, e1, r, k, l}

def peek(t: EC) -> EC & U32:
  match t:
    case ECL{}:
      (ECL{}, 0)
    case ECN{c, e1, l, +k, r}:
      (ECN{c, e1, l, k, r}, k)

def is_red(t: EC) -> EC & Bool:
  match t:
    case ECN{RedEC{}, e1, l, k, r}:
      (ECN{RedEC{}, e1, l, k, r}, True{})
    case t0:
      (t0, False{})

def paint(t: EC) -> EC:
  match t:
    case ECN{RedEC{}, e1, l, k, r}:
      ECN{BlackEC{}, e1, l, k, r}
    case t0:
      t0

def look(t: EC) -> EC:
  match t:
    case ECN{c, e1, ECN{c2, e12, l2, +k2, r2}, k, r}:
      ECN{c, e1, ECN{c2, e12, l2, k2, r2}, U32.add(k, k2), r}
    case t0:
      t0

def ins(t: EC, o: Cmp, +x: U32) -> EC:
  match t o:
    case ECL{} _:
      ECN{RedEC{}, 3n, ECL{}, x, ECL{}}
    case ECN{c, e1, ECN{c2, e12, l2, +k2, r2}, k, r} LT{}:
      ECN{c, e1, ins(ECN{c2, e12, l2, k2, r2}, U32.cmp(x, k2), x), k, r}
    case ECN{c, e1, ECL{}, k, r} LT{}:
      ECN{c, e1, ECN{BlackEC{}, 3n, ECL{}, x, ECL{}}, k, r}
    case ECN{c, e1, l, k, ECN{c2, e12, l2, +k2, r2}} GT{}:
      ECN{c, e1, l, k, ins(ECN{c2, e12, l2, k2, r2}, U32.cmp(x, k2), x)}
    case ECN{c, e1, l, k, ECL{}} GT{}:
      ECN{c, e1, l, k, ECN{RedEC{}, 3n, ECL{}, x, ECL{}}}
    case ECN{c, e1, l, k, r} EQ{}:
      ECN{c, e1, l, U32.add(k, 1), r}

def build(+n: Nat, t: EC) -> EC:
  match n:
    case 0n:
      t
    case 1n+m:
      +x = U32.mod(U32.mul(U32.from_nat(n), 2654435761), 1000)
      build(m, ins(t, U32.cmp(x, 500), x))

def push(-n: Nat, z: Bool, t: EC, acc: List<&2, EC>) -> List<&2, EC>:
  match z:
    case True{}:
      t <> acc
    case False{}:
      acc

def sum(xs: List<&2, EC>, +acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case t <> r:
      sum(r, dig(t, acc))

def pdig(p: EC & U32) -> U32:
  (t, k) = p
  dig(t, k)

def rdig(p: EC & Bool) -> U32:
  match p:
    case (t, True{}):
      dig(t, 1)
    case (t, False{}):
      dig(t, 2)

def uniq(+d: Nat, +i: U32) -> U32:
  U32.add(dig(same(gen(d, i)), 1), U32.add(dig(renum(gen(d, i)), 2), U32.add(dig(swap(gen(d, i)), 3), U32.add(pdig(peek(gen(d, i))), U32.add(dig(look(gen(d, i)), 4), U32.add(dig(build(9n, gen(d, i)), 5), U32.add(rdig(is_red(gen(d, i))), dig(paint(gen(d, i)), 6))))))))

def shar(+d: Nat, +i: U32) -> U32:
  +t = gen(d, i)
  z = sum(push(0n, U32.is_eq(U32.mod(i, 2), 0), t, push(1n, U32.is_eq(U32.mod(i, 3), 0), t, push(2n, U32.is_ne(U32.mod(i, 2), 0), t, []))), 0)
  U32.add(z, U32.add(dig(same(t), 1), U32.add(dig(renum(t), 2), U32.add(dig(swap(t), 3), U32.add(pdig(peek(t)), U32.add(dig(look(t), 4), U32.add(dig(build(9n, t), 5), U32.add(rdig(is_red(t)), U32.add(dig(paint(t), 6), dig(t, 0))))))))))

def par(+n: Nat, +t: EC) -> U32:
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
    Unit <- IO.print(U32.show(dig(build(3000n, ECL{}), 7)))
    Unit <- IO.print(U32.show(par(60n, gen(6n, 1))))
    IO.print(U32.show(loop(100n, 0)))

#|3438971835
#|3300457713
#|3556102993
#|359125393
#|1356182520
#|2400983544
#|3281278533
