# a lazy accumulator deeper than the host stack must still evaluate:
# each go step binds acc to a thunk over Nat.add(acc, 1n), so the head
# demand at the end collapses a 262144-long thunk chain -- the head
# Succ can only surface after every link resolves. Before the LAZ-frame
# law, each forced thunk nested one host term_wnf frame and the
# interpreter died at ~65536 with a raw RangeError -- not a numbered
# refusal, a host crash -- while the compiled JS, strict in its
# arguments, ran the same checked program to its answer. This pin adds
# the Nat shape (Succ-node field thunks driven through the match walk)
# and the IO main to reg_wnf_deep_chain's Bool/U32 coverage, and holds
# the --js lane to the same answer.
import Base

law Nat.pow2:
  for n: Nat
  Nat

def Nat.pow2(n):
  match n:
    case 0n:
      1n
    case 1n+p:
      Nat.double(Nat.pow2(p))

law go:
  for n   : Nat
  for acc : Nat
  Nat

def go(n, acc):
  match n:
    case 0n:
      acc
    case 1n+p:
      go(p, Nat.add(acc, 1n))

law main.go:
  for n: Nat
  IO(Unit)

def main.go(n):
  match n:
    case 0n:
      IO.print("zero")
    case 1n+p:
      IO.print("big")

law main:
  IO(Unit)

def main():
  main.go(go(Nat.pow2(18n), 0n))

#|big
