# fork values are free terms: annotated literals, operator chains and
# calls all fork -- ported from bend3 (its fork values were similarly
# free; a bare literal cannot infer, and a parenthesized value would
# glue onto the call before it, so the first two ride in braces)
import Base

law main.out:
  U32

def main.out():
  a b c = {5 : U32} {(2 + 3 * 4 : U32) : U32} U32.add(1, 1)
  (a * 100 + b * 10 + c : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|642
