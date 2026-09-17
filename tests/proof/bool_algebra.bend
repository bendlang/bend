# Base Bool algebra: proven laws (and_comm, not_not) instantiate at
# concrete booleans like any theorem.
# ported from bend3: bend's base carries the OPERATIONS only, so the
# laws are proved here over base Bool and then instantiated
import Base

law and_comm:
  for a: Bool
  for b: Bool
  {Bool.and(a, b) == Bool.and(b, a) : Bool}

def and_comm(a, b):
  match a, b:
    case True{}, True{}:
      {==}
    case True{}, False{}:
      {==}
    case False{}, True{}:
      {==}
    case False{}, False{}:
      {==}

law not_not:
  for b: Bool
  {Bool.not(Bool.not(b)) == b : Bool}

def not_not(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

law q:
  {Bool.and(True{}, False{}) == Bool.and(False{}, True{}) : Bool}

def q(): and_comm(True{}, False{})

law w:
  {Bool.not(Bool.not(False{})) == False{} : Bool}

def w(): not_not(False{})

law main:
  {Bool.and(True{}, False{}) == Bool.and(False{}, True{}) : Bool}

def main(): q()

#|{==}
