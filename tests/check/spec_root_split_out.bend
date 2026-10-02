# --verdict puts a root out of scope, at once, where splitting cannot end
# or has nothing to split into: ap_f's kind recurses through Ap's field v,
# whose declared type applies the parameter F (here G, which is Ap again),
# and void_f's kind matches a value of an empty datatype
import Base

type Ap<-F: Data -> Data, -X: Data> is Data:
  Ap{v: F(X)}

def G(X: Data) -> Data:
  Ap<G, X>

def ap_q(a: G(Nat)) -> Quant:
  match a:
    case Ap{v}: ap_q(v)

def ap_f(a: G(Nat), -A: Kind(ap_q(a)), x: Nat) -> Nat:
  x

type Void is Data:

def void_q(v: Void) -> Quant:
  match v:

def void_f(v: Void, -A: Kind(void_q(v)), x: Nat) -> Nat:
  x

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
