# a template applied to two Array trees with the same leaves got one
# specialization (#834): term_show keyed both as `[Unit{}, Unit{}, Unit{}]`,
# so contradiction's Pick reduced to seed's Unit and a proof of Empty
# checked. The key now tells the shapes apart.
type Empty is Data:

type Unit is Data:
  Unit{}

type Array<-T: Type> is Type:
  ALeaf{value: T}
  ANode{xs: Array<T>, ys: Array<T>}

def EmptyIfLeftIsNode(xs: Array<Unit>) -> Type:
  match xs:
    case ALeaf{x}:
      Unit
    case ANode{ALeaf{x}, r}:
      Unit
    case ANode{ANode{a, b}, r}:
      Empty

def Pick(~xs: Array<Unit>) -> Type:
  EmptyIfLeftIsNode(xs)

def seed() -> Pick(~ANode{ALeaf{Unit{}}, ANode{ALeaf{Unit{}}, ALeaf{Unit{}}}}):
  Unit{}

def contradiction() -> Pick(~ANode{ANode{ALeaf{Unit{}}, ALeaf{Unit{}}}, ALeaf{Unit{}}}):
  seed

#|Error:
#|- expected : Empty
#|- observed : Unit
#|Location: contradiction
#|29 | def contradiction() -> Pick(~ANode{ANode{ALeaf{Unit{}}, ALeaf{Unit{}}}, ALeaf{Unit{}}}):
#|30>|   seed
#|31 | 
#|exit 1
