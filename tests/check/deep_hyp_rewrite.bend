# bend3's %e renormalized every ctx type at 3000 levels; bend's
# rewrite is goal-only by ruling (ctx renormalization is on the
# do-not-add list), so the class pins on the goal: a 3000-deep
# equation rides one rewrite and closes, no host recursion anywhere
# (the countdown spells Nat: no number switches)
import Base

law build:
  for n: Nat
  Nat

def build(n):
  match n:
    case Zero{}:
      0n
    case Succ{k}:
      Succ{Succ{build(k)}}

law shrink:
  for e: {build(1500n) == 3000n : Nat}
  {Succ{build(1500n)} == 3001n : Nat}

def shrink(e):
  %e : {Succ{_} == 3001n : Nat}
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
