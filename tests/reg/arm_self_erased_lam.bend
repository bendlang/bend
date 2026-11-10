# regression witness: arm_self rewrites an arm's rebuild of its scrutinee
# to self, and drops the fields when nothing else uses them. A Lam or Let it
# rebuilt is pre-opened with the rewritten body, but the C emitter opens an
# erased lambda by applying its HOAS function to its own variable. That
# function returned the original body, which still named the dropped field
# p, and the build died in bind_pop ("undefined is not an object"). Each
# def below has an erased lambda in front of such a rebuild: f's directly,
# g's under a let (anf), h's under a let of an annotated Ctr.
import Base

law f:
  for n: Nat
  @-a: Type -> @x: a -> Nat

def f(n):
  match n:
    case Zero{}:
      a => x => Zero{}
    case Succ{p}:
      a => x => Succ{p}

law g:
  for n: Nat
  @-a: Type -> Nat

def g(n):
  match n:
    case Zero{}:
      a => Zero{}
    case Succ{p}:
      a =>
        y = {Succ{p} : Nat}
        y

law h:
  for n: Nat
  @-a: Type -> @-b: Type -> @x: a -> Nat

def h(n):
  match n:
    case Zero{}:
      a => b => x => Zero{}
    case Succ{p}:
      a => b => x =>
        y = {Succ{p} : Nat}
        Succ{y}

law main.out:
  Nat

def main.out():
  Nat.add(Nat.add(f(3n, U32, 7), g(4n, U32)), h(5n, U32, U32, 1))

law main:
  IO(Unit)

def main():
  IO.print(Nat.show(main.out()))

#|13
