# proof_numerics: add, mul and divmod on Base's Nat, each by structural
# recursion. LAWS.bend states their algebra and Euclid's division;
# PROOF.bend proves it. main prints 1024 divided by 7: (146n, 2n).
#
#   bend demos/proof_numerics/main.bend

import Base

def add(a: Nat, b: Nat) -> Nat:
  match a:
    case 0n:
      b
    case 1n+p:
      1n+add(p, b)

def mul(a: Nat, +b: Nat) -> Nat:
  match a:
    case 0n:
      0n
    case 1n+p:
      add(b, mul(p, b))

# a step of the division by 1n+m: bump the remainder r while it is
# below m; when it reaches m, wrap it to 0n and bump the quotient q
def divmod.wrap(b: Bool, q: Nat, r: Nat) -> Nat & Nat:
  match b:
    case True{}:
      (q, 1n+r)
    case False{}:
      (1n+q, 0n)

def divmod.step(m: Nat, qr: Nat & Nat) -> Nat & Nat:
  (q, r0) = qr
  +r = r0
  divmod.wrap((r < m), q, r)

# divides n by 1n+m in n steps
def divmod.go(n: Nat, +m: Nat) -> Nat & Nat:
  match n:
    case 0n:
      (0n, 0n)
    case 1n+p:
      divmod.step(m, divmod.go(p, m))

# the quotient and remainder of n by d; by 0n, (0n, n)
def divmod(n: Nat, d: Nat) -> Nat & Nat:
  match d:
    case 0n:
      (0n, n)
    case 1n+m:
      divmod.go(n, m)

def main() -> Nat & Nat:
  divmod(mul(32n, 32n), 7n)
