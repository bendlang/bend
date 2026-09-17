# regression: a lazy accumulator chain of ANY depth evaluates -- the
# wnf thunk carries its source term and term_wnf forces nested thunks
# on its own frame stack, memoizing at the pop, so forcing is as
# host-stack immune as the rest of the evaluator. Before this pin the
# thunk forced by host recursion (term_force -> producer -> term_wnf,
# one host frame set per link) and this checked, terminating loop of
# 65536 iterations killed the interpreter with a raw RangeError near
# 16k links, while the compiled lanes, which are strict, ran it.
import Base

law pow:
  for n: Nat
  Nat

def pow(n):
  match n:
    case Zero{}:
      Succ{Zero{}}
    case Succ{p}:
      Nat.double(pow(p))

law loop:
  for n: Nat
  for a: Bool
  Bool

def loop(n, a):
  match n:
    case Zero{}:
      a
    case Succ{p}:
      loop(p, Bool.not(a))

law main:
  Bool

def main():
  loop(pow(16n), False{})

#|False{}
