# refusal pin: bend3 rejected a non-Data argument at a Data-bounded
# datatype param inside another datatype's ctor field (dat_check
# formation). bend's grades keep the wall: Box7's T is bounded by
# Data (Kind(&2)), and a function type is Type (Kind(&1)), which never
# fits Data, so Bad's field is refused at its own ctor.
import Base

type Box7<T: Data> is Data:
  MkBox7{v: T}
type Bad is Data:
  MkBad{v: Box7<(U32 -> U32)>}

law main:
  U32

def main(): 0

#|Error:
#|- expected : Data
#|- observed : Type
#|Location: MkBad
#|10 | type Bad is Data:
#|11>|   MkBad{v: Box7<(U32 -> U32)>}
#|12 |
#|exit 1
