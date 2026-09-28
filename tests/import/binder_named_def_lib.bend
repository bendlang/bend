# a module binds locals named like its own defs: a binder is a name, so
# the let, +let, pattern, +pattern and lambda shapes parse as they do in
# a main file. once the module's namespace resolved each binder to the
# def, and the module failed to parse at it
import Base

type P is Data:
  P{a: Bool, b: Nat}

def bare(+e: Nat) -> Bool:
  Nat.is_eq(e, 1n)

def lt(x: Bool) -> Bool:
  bare = x
  bare

def plus(+e: Nat) -> Bool:
  +bare = Bool.and(bare(e), bare(e))
  Bool.and(bare, bare)

def pat(p: P) -> Bool:
  match p:
    case P{bare, n}: bare

def ppat(p: P) -> Bool:
  match p:
    case P{+bare, n}: Bool.and(bare, bare)

def lam(x: Bool) -> Bool:
  (bare => bare)(x)

def main() -> List<Bool>:
  [lt(False{}), plus(1n), pat(P{True{}, 0n}), ppat(P{False{}, 0n}), lam(True{})]

#|[False{}, True{}, True{}, False{}, True{}]
