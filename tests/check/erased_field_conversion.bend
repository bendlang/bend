# soundness pin: conversion COMPARES erased constructor fields -- two
# ctors differing only in an erased Type argument never convert (a
# skip there would transport a false type equality through a
# projection).
# ported from bend3: U32/F32 become two local types
type Unit10 is Data:
  Ua{}

type Empty10 is Data:

type Bxa is Data:
  Mka{-A: Type, v: Unit10}

law q:
  {Mka{Unit10, Ua{}} == Mka{Empty10, Ua{}} : Bxa}

def q(): {==}

law main:
  Unit10

def main(): Ua{}

#|Error:
#|- expected : Mka{Unit10, Ua{}}
#|- observed : Mka{Empty10, Ua{}}
#|Location: q
#|16 | 
#|17>| def q(): {==}
#|18 |
#|exit 1
