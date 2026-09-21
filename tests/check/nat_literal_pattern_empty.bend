# the unchecked literal pattern let a closed term inhabit Empty: the
# literal 0n matched a Zero that carries a field as a bare Zero, the
# arm's goal became @w:U -> Empty, and the self-call f(q) passed without
# descending. the literal is refused like Zero{} is
type U is Data:
  Un{}
type N is Data:
  Zero{w: U}
  Succ{p: N}
type D is Data:
  K{z: N}
type Empty is Data:

def f(b: N) -> Empty:
  match b:
    case 0n:
      {\{K: q => w => f(q)} : D -> U -> Empty}(K{Zero{Un{}}})
    case Succ{p}:
      f(p)

def boom() -> Empty:
  f(Zero{Un{}})

#|Error:
#|- message  : a Zero pattern with 1 field
#|Location:
#|15 |   match b:
#|16>|     case 0n:
#|17 |       {\{K: q => w => f(q)} : D -> U -> Empty}(K{Zero{Un{}}})
#|exit 1
