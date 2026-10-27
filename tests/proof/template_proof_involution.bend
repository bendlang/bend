# Reuse a template proof twice to derive four applications from two.
import Base

law not_twice:
  for b: Bool
  {Bool.not(Bool.not(b)) == b : Bool}

def not_twice(b):
  match b:
    case False{}:
      {==}
    case True{}:
      {==}

law four_steps:
  for ~f: Bool -> Bool
  for ~undo: (@x: Bool -> {f(f(x)) == x : Bool})
  for +x: Bool
  {f(f(f(f(x)))) == x : Bool}

def four_steps(f, undo, x):
  Equal.trans(Bool, f(f(f(f(x)))), f(f(x)), x, undo(f(f(x))), undo(x))

law use:
  for b: Bool
  {Bool.not(Bool.not(Bool.not(Bool.not(b)))) == b : Bool}

def use(b):
  four_steps(~(x => Bool.not(x)), ~(x => not_twice(x)), b)

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
