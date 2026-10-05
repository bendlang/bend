# A specialized parameter passed a bigger argument each time it recurs
# names a new instance at each step: T at List<n>, then List<List<n>>, S
# at n's and m's lists in turn, U at 1n+n, and f, whose body calls f at
# List<n>. --verdict made instances until it ran out of time or stack;
# now an instance whose arguments hold those of an instance of the same
# item above it is out of scope (a homeomorphic embedding, so every such
# chain ends there), and V<3n>'s shrinking index still goes out
import Base

def qof(n: Type) -> Quant:
  &1

def qn(n: Nat) -> Quant:
  &1

type T<n: Type> is Kind(qof(n)):
  T1{t: T<List<n>>}

type S<n: Type, m: Type> is Kind(qof(n)):
  S1{s: S<List<m>, n>}

type U<n: Nat> is Kind(qn(n)):
  U1{u: U<1n+n>}

type V<n: Nat> is Kind(qn(n)):
  V1{v: V<Nat.sub(n, 1n)>}

def f(c: Nat, n: Type, -A: Kind(qof(n))) -> Nat:
  match c:
    case 0n: 0n
    case 1n+p: f(p, List<n>, Unit)

def use_v(v: V<3n>) -> V<3n>:
  v

def main() -> Nat:
  Nat.add(f(2n, Nat, Unit), 7n)

#|7n
