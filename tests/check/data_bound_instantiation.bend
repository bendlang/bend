# refusal pin: bend3 checked a Data-bound instantiation against the
# sort table at the CALL SITE (dup(Box) rejected because Box holds a
# closure). the grade kernel has the same wall as a kind: dup2 binds
# -a: Data and duplicates its +x: a, Bx2 declares Type (a closure
# field forces it), and Type never fits Data -- the instantiation
# dup2(Bx2) refuses at the call site (main's own type stays generic
# through fst2, so no ill-formed Pr2<Bx2> is ever spelled).
# ported from bend3: ctor names bare and unique, Pair -> Pr2/MkPr2
import Base

type Bx2 is Type:
  MkBx2{f: U32 -> U32}
type Pr2<-Elem: Data> is Data:
  MkPr2{x: Elem, y: Elem}

law mk2:
  Unit -> Bx2

def mk2(): u => MkBx2{x => x}

law dup2:
  @-a: Data -> @+x: a -> Pr2<a>

def dup2(): a => x => MkPr2{x, x}

law fst2:
  for -a: Data
  for p: Pr2<a>
  U32

def fst2(a, p):
  match p:
    case MkPr2{x, y}:
      0

law main:
  U32

def main(): fst2(Bx2, dup2(Bx2)(mk2(Unit{})))

#|Error:
#|- expected : Data
#|- observed : Type
#|Location: main
#|38 | 
#|39>| def main(): fst2(Bx2, dup2(Bx2)(mk2(Unit{})))
#|   |                  ^^^
#|40 |
#|exit 1
