# an Array's cell is its element datatype's open layout (a type parameter
# boxed), so a generic body over Array<Boxed<A>> and a caller that builds
# Array<Boxed<Duo>> agree on the leaf class: the C lane once laid the
# caller's cell flat (two words, class 1) while the body tested class 0,
# took the ANode arm on a leaf, answered True{} against an accepted proof
# of False{}, and the flipped tag copied an affine closure (22, not 32)
import Base

type Duo is Data:
  DuoV{a: U32, b: U32}

type Boxed<-A: Data> is Data:
  BoxedV{item: A}

def node_tag(value: Bool) -> Bool:
  match value:
    case False{}:
      True{}
    case True{}:
      True{}

def tag(-A: Data, array: Array<Boxed<A>>) -> Bool:
  match array:
    case ALeaf{item}:
      False{}
    case ANode{left, right}:
      node_tag(tag(A, left))

def runtime_tag() -> Bool:
  tag(Duo, ALeaf{BoxedV{DuoV{10, 20}}})

def static_tag() -> {runtime_tag() == False{} : Bool}:
  {==}

def payload_grade(tag: Bool) -> Quant:
  match tag:
    case False{}:
      &1
    case True{}:
      &2

def Payload(tag: Bool) -> Kind(payload_grade(tag)):
  match tag:
    case False{}:
      U32 -> U32
    case True{}:
      U32

type Copies<tag: Bool> is Kind(payload_grade(tag)):
  CopiesValue{fst: Payload(tag), snd: Payload(tag)}

def forge(tag: Bool, a: Payload(tag), b: Payload(tag)) -> Copies<tag>:
  match tag:
    case False{}:
      CopiesValue{a, b}
    case True{}:
      +copy = a
      CopiesValue{copy, copy}

def array_sum(array: Array<U32>) -> U32:
  match array:
    case ALeaf{value}:
      value
    case ANode{left, right}:
      (array_sum(left) + array_sum(right) : U32)

def capture(array: Array<U32>) -> (U32 -> U32):
  n => (array_sum(array) + n : U32)

def invoke(copies: Copies<False{}>) -> U32:
  match copies:
    case CopiesValue{fst, snd}:
      (fst(1) + snd(1) : U32)

def affine() -> U32:
  invoke(forge(runtime_tag(), capture(ALeaf{10}), capture(ALeaf{20})))

def main() -> Bool & U32:
  (runtime_tag(), affine())

#|(False{}, 32)
