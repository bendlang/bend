# a call met only after a def unfolds converts with its copy before
# either unfolds: the two sides are written alike. big() is 2^30, a chain
# of Succ the full pass would walk on both sides (a stack overflow)
import Base

type Box is Data:
  Box{n: Nat}

def big() -> Nat:
  Nat.pow(2n, 30n)

def pow2(+n: Nat) -> Nat:
  Nat.pow(2n, n)

def boxed() -> Box:
  Box{big()}

def boxed_at(+n: Nat) -> Box:
  Box{pow2(n)}

# a nullary call, on either side
def boxed_eq() -> {Box{big()} == boxed() : Box}:
  {==}

def boxed_sym() -> {boxed() == Box{big()} : Box}:
  {==}

# a literal argument
def literal_eq() -> {Box{pow2(30n)} == boxed_at(30n) : Box}:
  {==}

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
