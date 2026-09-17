# bend3's pin: a goal reduced through a checked def must meet the
# rewrite motive in ONE stuck spelling (parsed-vs-elaborated bodies
# once stranded two); bend stores one elaborated body by design and
# refolds a stuck computed match to its ref, so both sides speak
# hgo(n) and the motive lands (the lemma states the eliminated term
# on the right)
import Base

law hgo.go:
  for z: Bool
  Nat

def hgo.go(z):
  match z:
    case True{}:
      0n
    case False{}:
      1n

law hgo:
  for n: Nat
  Nat

def hgo(n):
  hgo.go(Nat.is_eq(n, 0n))

law thv:
  for n: Nat
  for e: {0n == hgo(n) : Nat}
  {Succ{hgo(n)} == 1n : Nat}

def thv(n, e):
  %e : {Succ{_} == 1n : Nat}
  {==}

law main.out:
  Nat

def main.out():
  0n

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|0n
