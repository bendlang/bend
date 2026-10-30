# with Base, a module's constructors named like Base's types (Empty, Pair,
# Or, Exists) and its def named like Base's constructor Con leave the
# sugar on Base's: !=, &, |, &x: A -> B and <> name a type or a constructor,
# never a name of the other kind
import Base

type K is Data:
  Empty{}
  Pair{}
  Or{}
  Exists{}
  Z{}

def Con(x: K) -> K:
  x

def t(k: K) -> List<K>:
  Con(k) <> [Z{}]

def u(a: Nat, b: Nat) -> Type:
  {a != b : Nat} & Nat | Nat

def v(n: Nat) -> Type:
  &m: Nat -> {m == n : Nat}

def main() -> List<K>:
  t(Z{})

#|[Z{}, Z{}]
