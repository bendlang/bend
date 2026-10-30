# copies whose head is a redex, not a def, still convert before either
# unfolds: both sides reduce with no def unfolded (a beta, a match) to
# slow on one argument. slow(26n) takes 2^26 steps on each side
import Base

def slow(+n: Nat) -> Nat:
  match n:
    case 0n: 0n
    case 1n+p: Nat.add(slow(p), slow(p))

# a local lambda, applied on both sides
def lam() -> Nat:
  f = {x => slow(x) : Nat -> Nat}
  e = {{==} : {f(26n) == f(26n) : Nat}}
  0n

# a lambda-match, applied on both sides
def mat() -> {{\{Zero: slow(26n); Succ: p => 0n} : Nat -> Nat}(0n) == {\{Zero: slow(26n); Succ: p => 0n} : Nat -> Nat}(0n) : Nat}:
  {==}

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
