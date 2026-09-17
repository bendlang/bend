# bend3 checked Data structurally on demand and saw through aliases
# (wnf), so a Type-valued def classified where Data was demanded. the
# grade kernel keeps the alias transparency -- a bare def ref types a
# binder -- but reads the license off the alias's KIND: d is declared
# Data (U32 fits it), so +x: d is licensed and the over-use rides it.
# ported from bend3: x + x spends x twice, so x binds +
import Base

law d:
  Data

def d(): U32

law two:
  for +x: d
  U32

def two(x):
  (x + x : U32)

law main.out:
  U32

def main.out(): two(5)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|10
