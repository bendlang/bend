# descent rejects minting: the argument spends a fresh lambda each
# round (with f = id the call rebuilds C{y => y} forever) -- f(C{y =>
# y}) shrinks no column, so the self-call is refused.
# ported from bend3: bare ctors, main returns the test's own type
type T is Type:
  C{f: T -> T}
  N{}

law loop:
  for t: T
  T

def loop(t):
  match t:
    case C{f}:
      loop(f(C{y => y}))
    case t:
      t

law main:
  T

def main(): N{}

#|Error:
#|- expected : a decreasing self-call (arguments are read left to right: each passed unchanged until one shrinks)
#|- observed : loop
#|Context:
#|- f : @_:T -> T
#|Location: loop
#|15 |     case C{f}:
#|16>|       loop(f(C{y => y}))
#|   |       ^^^^
#|17 |     case t:
#|exit 1
