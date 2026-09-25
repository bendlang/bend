# usage errors speak human: binder names print bare and the quantity
# prints as words (consumed more than once), never an internal key --
# church-two needs f twice, but a lambda binder is affine
import Base
type MNat is Data:
  MZ{}
  MS{pred: MNat}

type Term is Type:
  TLam{bod: Term -> Term}
  TApp{fun: Term, arg: Term}
  TVar{idx: MNat}

law c2:
  Term

def c2():
  TLam{f => TLam{x => TApp{f, TApp{f, x}}}}

#|Error:
#|- expected : f
#|- observed : f (consumed more than once)
#|Location: c2
#|17 | def c2():
#|18>|   TLam{f => TLam{x => TApp{f, TApp{f, x}}}}
#|   |        ^
#|19 |
#|exit 1
