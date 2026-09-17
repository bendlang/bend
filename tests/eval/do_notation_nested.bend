# do-notation composes: a do inside a lambda body, a nested do as a
# bind's rhs, a discard line, and rebinding a name across bind lines
# (the new binder eclipses the old). A constructor action takes the
# uniform annotation {MkId{..} : Id<U32>}.
# ported from bend3: Id(A) becomes Id<A>, binds carry their per-line
# type (bend infers none), the bare discard line spells its yield type,
# (e : T) becomes {e : T}, result 2809 = two*100 + one shown as a Nat
import Base

type Id<-A: Type> is Type:
  MkId{v: A}

law Id.pure:
  for -A: Type
  for  v: A
  Id<A>

def Id.pure(A, v):
  MkId{v}

law Id.bind:
  for -A: Type
  for -B: Type
  for  m: Id<A>
  for  f: @x:A -> Id<B>
  Id<B>

def Id.bind(A, B, m, f):
  match m:
    case MkId{v}:
      f(v)

law run:
  for m: Id<U32>
  U32

def run(m):
  match m:
    case MkId{v}:
      v

law f:
  for k: @x:U32 -> Id<U32>
  U32

def f(k):
  run(k(3))

law one:
  U32

def one():
  run(do Id<U32>:
        MkId{9})

law two:
  U32

def two():
  f(n => do Id<U32>:
          x : U32 <- {MkId{n} : Id<U32>}
          U32 <- {MkId{0} : Id<U32>}
          x : U32 <- {MkId{U32.add(x, 1)} : Id<U32>}
          y : U32 <- do Id<U32>:
                       return U32.add(x, 10)
          return U32.mul(y, 2))

law main.out:
  Nat

def main.out():
  U32.to_nat(U32.add(U32.mul(two, 100), one))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|2809n
