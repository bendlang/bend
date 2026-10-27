# a template call in a type is the template's body at its arguments, no
# instance: Pick(~Nat) computes to Nat wherever it stands, and the same
# call in a body is an instance of it
import Base

def Pick(~T: Type) -> Type:
  T

def wrap(x: Pick(~Nat)) -> Pick(~Nat):
  x

# A partial instance in a body must keep its source call in dependent types.
def apply(~f: Quant -> Quant, x: Quant, y: Quant) -> Quant:
  f(x)

def same(-A: Type, f: A) -> {f == f : A}:
  {==}

def partial() -> {apply(~x => x) == apply(~x => x) : Quant -> Quant -> Quant}:
  same(Quant -> Quant -> Quant, apply(~x => x))

def partial_arg() -> {apply(~x => x, &1) == apply(~x => x, &1) : Quant -> Quant}:
  same(Quant -> Quant, apply(~x => x, &1))

def under_binder() -> {x => apply(~y => y, x) == x => apply(~y => y, x) : Quant -> Quant -> Quant}:
  same(Quant -> Quant -> Quant, x => apply(~y => y, x))

# Pruning the enclosing match must also preserve its arm's source call.
def pruned_parent() -> {\{Unit: apply(~x => x, &1); rest => apply(~x => x, &1)} == \{Unit: apply(~x => x, &1); rest => apply(~x => x, &1)} : Unit -> Quant -> Quant}:
  same(Unit -> Quant -> Quant, \{Unit: apply(~x => x, &1); rest => apply(~x => x, &1)})

# A substituted match can lose a fallback in only one occurrence.
type U is Data:
  A{}
  B{}

type Tag<-f: U -> U> is Data:
  T{}

def tag(f: U -> U) -> Tag<f>:
  T{}

def residual(f: U -> U) -> Tag<\{A: A{}; f}>:
  tag(\{A: A{}; f})

def original() -> Tag<\{A: A{}; B: B{}; rest => A{}}>:
  residual(\{B: B{}; rest => A{}})

def closed(~f: U -> U) -> Tag<\{A: A{}; f}>:
  tag(\{A: A{}; f})

def specialized() -> U:
  _ = closed(~\{B: B{}; rest => A{}})
  A{}

def call(~f: U -> U) -> U:
  f(A{})

# A checked let type must remain available when emitting a template model.
def checked_alias() -> U:
  call(~(x => (-F = {U -> U : Type}; f = {y => y : F}; f(x))))

# An inferred Type annotation must not hide the argument's stronger Data kind.
def typed_arg(-T: Type, x: T) -> T:
  x

def inferred_kind() -> U:
  +x = typed_arg((-q = &1; U), A{});
  x

def raw_match() -> U:
  call(~\{A: A{}; B: B{}})

# A full-domain argument also handles the remaining B inputs.
def remaining(~f: U -> U) -> U -> U:
  \{A: A{}; f}

# A substituted constructor keeps its type when a let must infer it.
def keep(~x: U) -> U:
  y = x;
  y

# Match refinement and rewriting also substitute values into inferred lets.
def constructor_goal() -> @x: U -> ((-z = x; U) -> U):
  \{A: +v => v; B: +v => v}

def rewrite_evidence(e: {A{} == A{} : U}) -> U -> U:
  %h@e : ((-z = h; U) -> U)
  +v => v

def rewrite_endpoint(e: {A{} == A{} : U}) -> U -> U:
  %h@e : ((-z = _; U) -> U)
  +v => v

def uniform(value: U, matched: U, evidence: U, endpoint: U) -> U:
  match value, matched, evidence, endpoint:
    case A{}, A{}, A{}, A{}:
      A{}
    case _, _, _, _:
      B{}

def uniform_cases() -> U:
  uniform(keep(~A{}), constructor_goal()(A{}, A{}), rewrite_evidence({==})(A{}), rewrite_endpoint({==})(A{}))

def result(t: Tag<\{A: A{}; B: B{}; rest => A{}}>, a: U, b: U, c: U, d: U) -> Pick(~Nat):
  match t, a, b, c, d:
    case T{}, A{}, A{}, B{}, A{}:
      wrap(3n)
    case t, a, b, c, d:
      0n

def main() -> Pick(~Nat):
  result(original(), specialized(), raw_match(), remaining(~\{A: A{}; B: B{}})(B{}), uniform_cases())

#|3n
