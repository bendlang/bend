# braces annotate and name no operator: a chain inside braces takes
# its own parens ({(a + b : U32) : U32}), a bare chain there is Nat's,
# and {a == b : T} stays the equality type
import Base

def main(a: U32, b: U32) -> U32:
  {(a + b : U32) : U32}

def g(a: Nat, b: Nat) -> Nat:
  {a + b : Nat}

def h(a: Nat, b: Nat) -> Type:
  {a + 1n == b : Nat}

#|a => b => U32.add(a, b)
