# CE: erased fields among a node's boxed ones (-e1: Nat, c: ColCE, l: CE, k: U32, r: CE)
import Base

type ColCE is Data:
  RedCE{}
  BlackCE{}

type CE is Data:
  CEL{}
  CEN{-e1: Nat, c: ColCE, l: CE, k: U32, r: CE}

def colCE(c: ColCE) -> U32:
  match c:
    case RedCE{}:
      1
    case BlackCE{}:
      2

def dig(t: CE, +acc: U32) -> U32:
  match t:
    case CEL{}:
      U32.add(U32.mul(acc, 29), 5)
    case CEN{e1, c, l, k, r}:
      dig(r, U32.add(U32.mul(dig(l, U32.add(U32.mul(acc, 29), colCE(c))), 137), k))

def pick(m: U32) -> ColCE:
  match m:
    case 0:
      RedCE{}
    case _:
      BlackCE{}

def gen(+d: Nat, +i: U32) -> CE:
  match d:
    case 0n:
      CEL{}
    case 1n+e:
      CEN{3n, pick(U32.mod(i, 2)), gen(e, U32.mul(i, 2)), i, gen(e, U32.add(U32.mul(i, 2), 1))}

def same(t: CE) -> CE:
  match t:
    case CEL{}:
      CEL{}
    case CEN{e1, c, l, k, r}:
      CEN{e1, c, l, k, r}

def renum(t: CE) -> CE:
  match t:
    case CEL{}:
      CEL{}
    case CEN{e1, c, l, k, r}:
      CEN{7n, c, l, k, r}

def swap(t: CE) -> CE:
  match t:
    case CEL{}:
      CEL{}
    case CEN{e1, c, l, k, r}:
      CEN{e1, c, r, k, l}

def peek(t: CE) -> CE & U32:
  match t:
    case CEL{}:
      (CEL{}, 0)
    case CEN{e1, c, l, +k, r}:
      (CEN{e1, c, l, k, r}, k)

def is_red(t: CE) -> CE & Bool:
  match t:
    case CEN{e1, RedCE{}, l, k, r}:
      (CEN{e1, RedCE{}, l, k, r}, True{})
    case t0:
      (t0, False{})

def paint(t: CE) -> CE:
  match t:
    case CEN{e1, RedCE{}, l, k, r}:
      CEN{e1, BlackCE{}, l, k, r}
    case t0:
      t0

def look(t: CE) -> CE:
  match t:
    case CEN{e1, c, CEN{e12, c2, l2, +k2, r2}, k, r}:
      CEN{e1, c, CEN{e12, c2, l2, k2, r2}, U32.add(k, k2), r}
    case t0:
      t0

def ins(t: CE, o: Cmp, +x: U32) -> CE:
  match t o:
    case CEL{} _:
      CEN{3n, RedCE{}, CEL{}, x, CEL{}}
    case CEN{e1, c, CEN{e12, c2, l2, +k2, r2}, k, r} LT{}:
      CEN{e1, c, ins(CEN{e12, c2, l2, k2, r2}, U32.cmp(x, k2), x), k, r}
    case CEN{e1, c, CEL{}, k, r} LT{}:
      CEN{e1, c, CEN{3n, BlackCE{}, CEL{}, x, CEL{}}, k, r}
    case CEN{e1, c, l, k, CEN{e12, c2, l2, +k2, r2}} GT{}:
      CEN{e1, c, l, k, ins(CEN{e12, c2, l2, k2, r2}, U32.cmp(x, k2), x)}
    case CEN{e1, c, l, k, CEL{}} GT{}:
      CEN{e1, c, l, k, CEN{3n, RedCE{}, CEL{}, x, CEL{}}}
    case CEN{e1, c, l, k, r} EQ{}:
      CEN{e1, c, l, U32.add(k, 1), r}

def build(+n: Nat, t: CE) -> CE:
  match n:
    case 0n:
      t
    case 1n+m:
      +x = U32.mod(U32.mul(U32.from_nat(n), 2654435761), 1000)
      build(m, ins(t, U32.cmp(x, 500), x))

def push(-n: Nat, z: Bool, t: CE, acc: List<&2, CE>) -> List<&2, CE>:
  match z:
    case True{}:
      t <> acc
    case False{}:
      acc

def sum(xs: List<&2, CE>, +acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case t <> r:
      sum(r, dig(t, acc))

def pdig(p: CE & U32) -> U32:
  (t, k) = p
  dig(t, k)

def rdig(p: CE & Bool) -> U32:
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

def par(+n: Nat, +t: CE) -> U32:
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
    Unit <- IO.print(U32.show(dig(build(3000n, CEL{}), 7)))
    Unit <- IO.print(U32.show(par(60n, gen(6n, 1))))
    IO.print(U32.show(loop(100n, 0)))

#|3438971835
#|3300457713
#|3556102993
#|359125393
#|1356182520
#|2400983544
#|3281278533
