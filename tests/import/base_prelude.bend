# no prelude gating: syntax is core grammar with or without Base --
# without the import only the NAMES are missing, so a book touching no
# base name parses, checks and evaluates (bend3 gated literal sugar on
# `import Base`; interp-only: every showable RESULT type lives in Base)
type Nx is Data:
  Zx{}
  Sx{p: Nx}

law depth:
  for n: Nx
  Nx

def depth(n):
  match n:
    case Sx{p}:
      Sx{depth(p)}
    case Zx{}:
      Zx{}

law main:
  Nx

def main():
  depth(Sx{Zx{}})

#|Sx{Zx{}}
