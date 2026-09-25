# #841's exploit: a ( .. : T) around a template call once renamed the
# operators inside its ~ argument after the instance was keyed; the
# annotation now names only its own operator expression, and one that
# reaches no operator is refused with the repair
type Empty is Data:

type Unit is Data:
  Unit{}

def Nat.add(a: Type, b: Type) -> Type:
  Unit

def Bar.add(a: Type, b: Type) -> Type:
  Empty

def Pick(~x: Type) -> Type:
  x

def contradiction() -> (Pick(~Unit + Unit) : Bar):
  Unit{}

#|Error:
#|- message  : a type for this operator (write (a + b : Nat))
#|Location:
#|18 | 
#|19>| def contradiction() -> (Pick(~Unit + Unit) : Bar):
#|   |                                    ^
#|20 |   Unit{}
#|Note: we broke this after launch, sorry. Until 2.0.16 a bare operator meant Nat.
#|That was a bug: operators demand annotation. Wrap the expression and it'll work again.
#|exit 1
