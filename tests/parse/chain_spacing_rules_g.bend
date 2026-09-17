# the spacing rules survive the suffix: a glued % heads a rewrite and
# a spaced % is mod; a >-headed operator needs a space before it, so
# nested closers stack (List<List<U32>>); a + glued to a name is a
# binder, and 1n+p is the literal, whose tail is a whole term
import Base

def f(a: U32, b: U32) -> U32:
  (a % b : U32)

def main(xs: List<List<U32>>, a: U32, b: U32) -> Bool:
  (a > b : U32)

def h(+n: Nat, p: Nat) -> Nat:
  1n+p + n

#|xs => a => b => Cmp.is_gt(U32.cmp(a, b))
