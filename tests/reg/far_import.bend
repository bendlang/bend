# reg (reg_far_import): a module imported from another directory
# (../io/far_types.bend) named its constructors with the path walked to
# it, so its effect's CID_FAR_TYPES_DEEP was CID_____IO_FAR_TYPES_DEEP in
# the program and its JS tag "far_types.Deep" was "../io/far_types.Deep",
# and neither lane built. An effect now names its module's constructors
# as the module does, CID(Deep) on both lanes, read in the module's
# namespace (its Deep, not this program's): a C id, or in JS the tag,
# which is the constructor's key.
import Base
import ../io/far_types.bend as F

def far.sum(t: F.Far) -> U32:
  match t:
    case F.Near{v}:
      v
    case F.Deep{l, r}:
      (far.sum(l) + far.sum(r) : U32)

type Depth is Data:
  Deep{d: U32}

def depth(x: Depth) -> U32:
  match x:
    case Deep{d}:
      d

def main() -> IO(Unit):
  do IO<Unit>:
    t : F.Far <- F.far.make(3)
    IO.print(U32.show((far.sum(t) + depth(Deep{30}) : U32)))

#|66
