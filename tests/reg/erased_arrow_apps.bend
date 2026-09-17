# regression witness: an erased-domain function value (@-zq: A -> B)
# compiles to its body, so applying it must compile to the value; the
# carbonizer kept such an application in place and left its argument
# for the emitters, whose inliner readback then lost the head's
# annotation and read the application as a live closure call. rd9 fed
# Fail{455n}, a constructor of a parametrized datatype, into that call
# ("a constructor outside a datatype" in C); rd8 applied the closure a
# def returns to an erased 3, an application nothing annotates, which
# only worked because applying a raw word yields the word. term_spine
# now reads a function value's quantities off its own type, and apps
# drops the erased applications of a function value at carbonize.
import Base

def cu12(c: Cmp) -> U32:
  match c:
    case LT{}:
      3
    case EQ{}:
      78
    case GT{}:
      158

def rd10(f: (@-zq: Nat -> Cmp)) -> U32:
  cu12(f(7n))

def rd9(f: (@-zq: Result<Nat, U32> -> @-zq: Nat -> Cmp)) -> U32:
  rd10(f(Fail{455n}))

def fn4(p0: Bool, p1: List<Nat>) -> Unit -> @-zq: U32 -> U32:
  y5 => y6 => 7

def tf7(x: List<Nat>) -> List<Nat>:
  match x:
    case Nil{}:
      Nil{}
    case x0 <> x1:
      Nat.add(x0, 2n) <> tf7(x1)

def rd8(f: Unit -> @-zq: U32 -> U32) -> U32:
  f(Unit{})(3)

def main() -> IO(Unit):
  v2 = {fn4(True{}, tf7(Nil{})) : Unit -> @-zq: U32 -> U32}
  IO.print(U32.show(rd9(y16 => y17 => GT{})) ++ " " ++ U32.show(rd8(v2)))

#|158 7
