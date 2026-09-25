# a constructor builds with braces: A(x) is a plain call head, and no
# def A exists.
# ported from bend3
type Nw4 is Data:
  Zw4{}

type Rw4 is Data:
  Aw4{x: Nw4}

law f:
  for x: Nw4
  Rw4

def f(x):
  Aw4(x)

law main:
  Rw4

def main(): f(Zw4{})

#|Error:
#|- expected : a defined name
#|- observed : Aw4
#|Context:
#|- x : Nw4
#|Location: f
#|14 | def f(x):
#|15>|   Aw4(x)
#|   |   ^^^
#|16 |
#|exit 1
