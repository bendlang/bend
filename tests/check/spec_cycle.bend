# A's kind names n, so n is specialized, and so is each parameter an
# argument of which reaches it: B's m through A1's field, A's p and B's r
# around the two-way cycle, S's m through its own field. Each is read
# before its answer is known (A before B, S inside S), which a one-pass
# cache took as nothing specialized: --verdict saw a kind depending on a
# run-time value, and failed in every order for S and C/D (#1179)
import Base

def qof(n: Type) -> Quant:
  &1

type A<n: Type> is Kind(qof(n)):
  A1{b: B<n>}

type B<m: Type> is Type:
  B1{a: A<m>}

type S<n: Type, m: Type> is Kind(qof(n)):
  S1{s: S<m, n>}

type C<n: Type, p: Type> is Kind(qof(n)):
  C1{d: D<p, n>}

type D<m: Type, r: Type> is Kind(qof(m)):
  D1{c: C<r, m>}

def main() -> Nat:
  7n

#|7n
