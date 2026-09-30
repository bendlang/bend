# Dead references neither add group members nor select a group's leader.
# h names unrelated L2 first; L names it after its real cycle through h.
import Base

def keep(-p: Nat, x: Nat) -> Nat:
  x

law L:
  for n: Nat
  Nat

law L2:
  for n: Nat
  Nat

def h(n: Nat) -> Nat:
  keep(L2(n), keep(L(n), n))

def d(n: Nat) -> Nat:
  keep(L(n), 1n+n)

def L(n):
  match n:
    case Zero{}:
      keep(L2(0n), 0n)
    case Succ{m}:
      h(m)

def L2(n):
  0n

law member:
  {L(4n) == 3n : Nat}

def member():
  {==}

law non_member:
  {d(4n) == 5n : Nat}

def non_member():
  {==}

def main() -> Nat:
  d(4n)

#|5n
