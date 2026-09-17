# compile (compile_nofk_closure): SPEC 2.4's NOFK law -- a segment is
# no-fork only when its body holds no fork and every definition it
# calls is no-fork too, read off the BOOK and closed under references;
# the scheduler skips no-fork tasks during growth. The closure half
# rode on nothing: gutting the reference fixpoint in gen_defs kept the
# whole suite green while every fork hidden behind a wrapper call was
# marked no-fork, so growth would skip the very tasks that must split.
# Here main holds no fork of its own and reaches one only through
# main.out (wrap and fork_pair, each called once, are fused into it):
# main's 0 mark is the closure's work, main.out's 0 is the direct
# half, and leap -- recursive, fork-free -- keeps the honest 1 beside
# them, as do U32.show's own segments, the fork's joiner and its
# sequential chain steps (each holds one call).
import Base

law leap:
  for +n: Nat
  U32

def leap(n):
  match n:
    case 0n:
      1
    case 1n+p:
      U32.add(1, leap(p))

law fork_pair:
  for +n: Nat
  U32

def fork_pair(n):
  a b = leap(n) leap(n)
  U32.add(a, b)

law wrap:
  for +n: Nat
  U32

def wrap(n):
  fork_pair(n)

law main.out:
  U32

def main.out():
  wrap(10n)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|22
