# a tiny expression interpreter: an AST of Lit/Add/Mul/Sub evaluates over
# wrapping words; (2+3)*(10-4) + 5*0xFFFFFFFF computed structurally
# ported from bend3: infix word ops become U32.add/mul/sub; the bend3
# `--eval eval` def-printing block is bend3-only and is dropped
import Base

type Expr is Data:
  Lit{n: U32}
  Add{a: Expr, b: Expr}
  Mul{a: Expr, b: Expr}
  Sub{a: Expr, b: Expr}

law eval:
  for e: Expr
  U32

def eval(e):
  match e:
    case Lit{n}:
      n
    case Add{a, b}:
      U32.add(eval(a), eval(b))
    case Mul{a, b}:
      U32.mul(eval(a), eval(b))
    case Sub{a, b}:
      U32.sub(eval(a), eval(b))

law main.out:
  U32

def main.out():
  e1 = {Mul{Add{Lit{2}, Lit{3}}, Sub{Lit{10}, Lit{4}}} : Expr}
  e2 = {Mul{Lit{5}, Lit{4294967295}} : Expr}
  U32.add(eval(e1), eval(e2))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|25
