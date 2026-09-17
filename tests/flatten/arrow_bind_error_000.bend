# the ctor-pattern bind `P{..} <- e` is dead syntax: `<-` lives only in
# do-blocks; an upper-head statement is `P{..} = e`.
# ported from bend3
import Base

type Pw is Data:
  Pp{a: U32, b: U32}

law go:
  for k: Pw
  U32

def go(k):
  Pp{a, b} <- k
  a

law main:
  U32

def main(): go(Pp{1, 2})

#|Error:
#|- expected : 'def', 'type' or 'law'
#|- observed : '<'
#|Location:
#|13 | def go(k):
#|14>|   Pp{a, b} <- k
#|15 |   a
#|exit 1
