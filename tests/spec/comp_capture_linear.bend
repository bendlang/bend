# comp-splice pin (spec_comp_capture_linear): bend3's capture honesty,
# negative side -- a recursive template capturing a closure-typed var
# died BadUsage at the instantiation (closures never contract). bend's ~
# law map checks once, f an opaque constant; the lambda captures g, a
# parameter, unbound in the empty context a ~ argument checks in, so
# the call is refused. (the affine wall itself is pinned by the capture
# twins.)
import Base

type L is Data:
  C{h: U32, t: L}
  N{}

law map:
  for ~f: U32 -> U32
  for xs: L
  L

def map(f, xs):
  match xs:
    case C{h, t}:
      C{f(h), map(f, t)}
    case N{}:
      N{}

law bad:
  for g: U32 -> U32
  for xs: L
  L

def bad(g, xs):
  map(x => g(x), xs)

law main:
  L

def main():
  bad(y => (y + 1 : U32), C{1, C{2, N{}}})

#|Error:
#|- expected : a template applied to closed ~ arguments (g is a variable here, not comptime: pass it at run time)
#|- observed : map
#|Context:
#|- g  : @_:U32 -> U32
#|- xs : L
#|Location: bad
#|31 | def bad(g, xs):
#|32>|   map(x => g(x), xs)
#|   |   ^^^
#|33 |
#|exit 1
