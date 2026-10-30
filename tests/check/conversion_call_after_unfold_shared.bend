# the rigid answer on a pair of shared cells is kept for the whole
# conversion: root_rec's side is a DAG whose tree is exponential (each sq
# is mix(h, h) on one cell), and a pair met again is not walked again
import Base

def mix(a: U32, b: U32) -> U32:
  (a * 31 + b * 2 + 1 : U32)

def root_loop(d: Nat, +h: U32) -> U32:
  match d:
    case 0n: h
    case 1n+p: root_loop(p, mix(h, h))

def sq(+h: U32) -> U32:
  mix(h, h)

def root_rec(d: Nat, +x: U32) -> U32:
  match d:
    case 0n: x
    case 1n+p: sq(root_rec(p, x))

def t() -> {root_loop(24n, 3) == root_rec(24n, 3) : U32}:
  {==}

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
