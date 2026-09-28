# An annotated lambda or lambda-match applied where it stands is a function
# value applied: the checker keeps the application, so the annotation is
# checked where it is written, and the compiler applies the value as a
# closure, as it applies a let-bound one. Both emitters refused the head
# (a Mat- or Lam-headed spine; a live call into the law LT). Expect 10.
import Base

def main() -> U32:
  a = {(\{LT: 10; EQ: 20; GT: 30}) : (Cmp) -> (U32)}(U32.cmp(1, 2))
  {(x => -e = {1n : Nat}; x) : (U32) -> (U32)}(a)

#|10
