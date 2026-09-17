# {==} proves reflexivity, never {a != a}: bend's inequality desugars
# at parse to the arrow {a == b : T} -> Empty (bend3's Empty.Not law,
# structurally), so Rfl rejects it on shape
import Base

law neg:
  Type

def neg():
  {0 != 0 : U32}

law prf:
  neg()

def prf():
  {==}

law main:
  U32

def main():
  0

#|Error:
#|- expected : @_:{0 == 0 : U32} -> Empty
#|- observed : non-inferrable term '{==}'
#|Location: prf
#|15 | def prf():
#|16>|   {==}
#|17 |
#|exit 1
