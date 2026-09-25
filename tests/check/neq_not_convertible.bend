# conversion must not equate {a != b} with {a == b}: bend's
# inequality is the arrow into Empty from parse time, never
# convertible with the equation itself
import Base

law neg:
  Type

def neg():
  {0 != 0 : U32}

law coerce:
  for p: neg()
  {0 == 0 : U32}

def coerce(p):
  p

law main:
  U32

def main():
  0

#|Error:
#|- expected : {0 == 0 : U32}
#|- observed : @_:{0 == 0 : U32} -> Empty
#|Context:
#|- p : @_:{0 == 0 : U32} -> Empty
#|Location: coerce
#|16 | def coerce(p):
#|17>|   p
#|   |   ^
#|18 |
#|exit 1
