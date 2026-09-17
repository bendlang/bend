# regression witness: the interpreter memoized a cell's lambda-match
# but handed its arms out as bare terms, so every application of a
# shared match re-evaluated the arm it selected: call-by-need for the
# match, call-by-name for its arms. Here each step's match holds two
# arms whose values are the lazy sum of the previous match applied to
# both constructors, and the next step applies it to both -- constant
# work per step with shared arms, 2^n without (n=14 took three seconds,
# n=18 forty-four, n=20 does not finish). A value stored into a cell now
# cells its raw subterms too (term_cells): a match's arms among them.
# Everything lives at the type level, where an erased function may be
# applied any number of times: main answers the Type {2^21 == 0 : U32},
# so the run is the interpreter's, and the answer shows as Word chains.
import Base

def sum(-f: Bool -> U32) -> Type:
  {(f(True{}) + f(False{}) : U32) == 0 : U32}

def go(+n: Nat, -f: Bool -> U32) -> Type:
  match n:
    case 0n:
      sum(f)
    case 1n+p:
      go(p, \{True: (f(True{}) + f(False{}) : U32); False: (f(True{}) + f(False{}) : U32)})

def main() -> Type:
  go(U32.to_nat(20), \{True: 1; False: 1})

#|{2097152 == 0 : U32}
