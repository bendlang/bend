# audit 080: binder-name capture soundness. `snd2(b,a)` reduces to `a`
# (its second argument), so `worse` gives x:a but claims goal b, and
# must be rejected -- a capture bug would accept it and inhabit Empty.
# ported from bend3
type Unit5 is Data:
  U5{}

type Empty5 is Data:

law snd2:
  @a:Type -> @b:Type -> Type

def snd2(): a => b => b

law worse:
  @a:Type -> @b:Type -> @x:snd2(b, a) -> b

def worse(): a => b => x => x

law main:
  Empty5

def main(): worse(Unit5, Empty5, U5{})

#|Error:
#|- expected : b
#|- observed : a
#|Context:
#|- a : Type
#|- b : Type
#|- x : a
#|Location: worse
#|17 | 
#|18>| def worse(): a => b => x => x
#|   |                             ^
#|19 |
#|exit 1
