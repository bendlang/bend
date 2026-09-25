# the != sugar needs a `sugar Not: Empty` declaration, which Base makes:
# without Base the sugar role is unbound and the parse fails at it --
# bend's whole gating story (bend3 gated the parse on `import Empty`)
type Nx is Data:
  Zx{}

law T0:
  Type

def T0():
  {Zx{} != Zx{} : Nx}

law main:
  Nx

def main():
  Zx{}

#|Error:
#|- expected : a defined name
#|- observed : Empty
#|Context:
#|- _ : {Zx{} == Zx{} : Nx}
#|Location: T0
#|10 | def T0():
#|11>|   {Zx{} != Zx{} : Nx}
#|   |         ^^
#|12 |
#|exit 1
