# two share cells found equal must not merge by copying a value: z holds
# f(c) and c holds f(z), so pointing c at z's value made c := f(f(c)), a
# cyclic term that overflowed the stack when lowered to BendTT (#1984)
import Base

type T is Type:
  A{}
  B{}

def f(b: T) -> T:
  match b:
    case A{}:
      B{}
    case B{}:
      A{}

def P(c: T) -> Type:
  &z: T -> {f(c) == z : T} & {f(z) == c : T}

def p() -> P(A{}):
  (B{}, {==}, {==})

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
