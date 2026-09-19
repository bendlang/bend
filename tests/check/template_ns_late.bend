# a template call inside ( .. : T) instantiates after the parens close, so
# the operators in its ~ arguments carry the namespace T names, not Nat
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
#|- expected : Empty
#|- observed : Unit
#|Location: contradiction
#|17 | def contradiction() -> (Pick(~Unit + Unit) : Bar):
#|18>|   Unit{}
#|19 | 
#|exit 1
