# comp-splice pin (spec_comp_capture_linear): bend3's capture honesty,
# negative side -- a recursive template capturing a closure-typed var
# died BadUsage at the instantiation (closures never contract). bend
# has no comp surface at all; the ~ binder pins bend's own parse
# refusal (the affine wall itself is pinned by the capture twins).
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
#|- expected : a name
#|- observed : '~'
#|Location:
#|12 | law map:
#|13>|   for ~f: U32 -> U32
#|14 |   for xs: L
#|exit 1
