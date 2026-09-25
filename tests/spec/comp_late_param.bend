# comp-splice pin (spec_comp_late_param): bend3 accepted a comp param
# declared AFTER the matched column (the commuting application). a ~
# clause after a plain one is refused where it is written: only leading
# clauses take ~, so f heads no template.
import Base

type L is Data:
  C{h: U32, t: L}
  N{}

law each:
  for xs: L
  for ~f: U32 -> U32
  L

def each(xs, f):
  match xs:
    case C{h, t}:
      C{f(h), each(t, f)}
    case N{}:
      N{}

law total:
  for xs: L
  U32

def total(xs):
  match xs:
    case C{h, t}:
      (h + total(t) : U32)
    case N{}:
      0

law main:
  U32

def main():
  total(each(C{1, C{2, C{3, N{}}}}, x => (x * 2 : U32)))

#|Error:
#|- expected : a plain clause (only leading clauses take ~)
#|- observed : '~'
#|Location:
#|12 |   for xs: L
#|13>|   for ~f: U32 -> U32
#|   |       ^
#|14 |   L
#|exit 1
