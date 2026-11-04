# compile (closure_record_shared): a closure's result is a flat record
# bound with + and used twice. The closure returns it boxed; the binding
# stays boxed: the first use reads its words in place and the last takes
# the node (a share of the node that did not heat its type freed it twice:
# memory fault).
import Base

type P is Data:
  P{a: U32, b: U32}

def sum(p: P) -> U32:
  match p:
    case P{a, b}:
      U32.add(a, b)

def dif(p: P) -> U32:
  match p:
    case P{a, b}:
      U32.sub(a, b)

def both(+p: P) -> U32:
  U32.mul(sum(p), dif(p))

def viaclo(f: U32 -> P, x: U32) -> U32:
  +p = f(x)
  U32.mul(sum(p), dif(p))

def mk(+x: U32) -> P:
  P{U32.add(x, 3), x}

def main() -> IO(Unit):
  IO.print(U32.show(viaclo(y => mk(y), 4)))

#|33
