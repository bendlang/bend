# A ~ argument that names a run-time Data variable (#1483): --verdict
# passes each such capture to the template's instance as a parameter.
import Base

def least(lo: Nat, xs: List<&2, Nat>) -> Data:
  {List.all(~&2, ~Nat, ~(y => Nat.is_le(lo, y)), xs) == True{} : Bool}

def least_nil(lo: Nat) -> least(lo, Nil{}):
  {==}

def least_cons(lo: Nat, x: Nat, xs: List<&2, Nat>, h: {True{} == Nat.is_le(lo, x) : Bool}, t: least(lo, xs)) -> least(lo, x <> xs):
  %e@h : {List.all.if(u => List.all(~&2, ~Nat, ~(y => Nat.is_le(lo, y)), xs), _) == True{} : Bool}
  t

def zero_le(+x: Nat) -> {True{} == Nat.is_le(0n, x) : Bool}:
  match x:
    case 0n:
      {==}
    case 1n+p:
      {==}

def least_zero(+xs: List<&2, Nat>) -> least(0n, xs):
  match xs:
    case []:
      {==}
    case x <> rest:
      least_cons(0n, x, rest, zero_le(x), least_zero(rest))

# a capture is named by its place in the instance: T's own h does not
# take lo's name
def T(~f: Nat -> Bool, h: Nat, xs: List<&2, Nat>) -> Data:
  {List.all(~&2, ~Nat, ~(y => Bool.and(f(y), Nat.is_le(y, h))), xs) == True{} : Bool}

def T_nil(lo: Nat, h: Nat) -> T(~(y => Nat.is_le(lo, y)), h, []):
  {==}

# a capture whose type names another
type Box<n: Nat> is Data:
  B{v: Nat}

def Box.get(n: Nat, b: Box<n>) -> Nat:
  match b:
    case B{v}:
      v

def above(n: Nat, b: Box<n>, xs: List<&2, Nat>) -> Data:
  {List.all(~&2, ~Nat, ~(y => Nat.is_le(Box.get(n, b), y)), xs) == True{} : Bool}

def above_nil(n: Nat, b: Box<n>) -> above(n, b, Nil{}):
  {==}

# in a datatype's field
type Above<lo: Nat, xs: List<&2, Nat>> is Data:
  Mk{p: {List.all(~&2, ~Nat, ~(y => Nat.is_le(lo, y)), xs) == True{} : Bool}}

def above_mk(lo: Nat) -> Above<lo, Nil{}>:
  Mk{{==}}

# a law over its own ~b: its type at each b names the closed instance
law refl_all:
  for ~b: Bool
  for xs: List<&2, Bool>
  {List.all(~&2, ~Bool, ~(y => Bool.and(y, b)), xs) == List.all(~&2, ~Bool, ~(y => Bool.and(y, b)), xs) : Bool}

def refl_all(b, xs):
  {==}

# a variable the argument's normal form drops is no capture
def none(-lo: Nat, xs: List<&2, Bool>) -> Data:
  {List.all(~&2, ~Bool, ~(y => Bool.and(False{}, Nat.is_le(lo, 0n))), xs) == True{} : Bool}

def none_nil(-lo: Nat) -> none(lo, []):
  {==}

# an instance passes its own captures on, by the callee's places
def V(~n: Nat, g: Box<n> -> Nat) -> Data:
  {g(B{0n}) == 0n : Nat}

def W(~m: Nat -> Nat, h: Nat) -> Data:
  V(~Nat.add(h, m(0n)), b => 0n)

def W_ok(j: Nat, k: Nat) -> W(~(z => j), k):
  {==}

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
