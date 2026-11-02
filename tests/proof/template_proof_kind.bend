# A λ that returns a Type-kind datatype stays bare in later domains, so its kind is visible.
import Base

type T is Type:
  A{}
  B{}

def both(x: T, y: T) -> Nat:
  match x:
    case A{}:
      match y:
        case A{}: 0n
        case B{}: 1n
    case B{}:
      match y:
        case A{}: 2n
        case B{}: 3n

law via:
  for ~F: Unit -> Type
  for ~g: F(Unit{}) -> Nat
  for x: F(Unit{})
  {g(x) == g(x) : Nat}

def via(F, g, x):
  {==}

law use:
  for x: T
  {both(x, x) == both(x, x) : Nat}

def use(x):
  via(~(u => T), ~(y => both(y, y)), x)

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
