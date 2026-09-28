# F32.read and a literal round a decimal to binary32 once, as strtof
# does, on every lane: through binary64 first, a text whose binary64
# is a binary32 midpoint rounded to the even side, not the text's side
import Base

def bits(m: Maybe<&2, F32>) -> U32:
  match m:
    case None{}:
      0
    case Some{F32{w}}:
      U32{w}

def read(s: String) -> String:
  U32.show(bits(F32.read(s)))

def main.out() -> String:
  read("0.9999999701976776") ++ " "
    ++ read("1.0000000596046447753906250001") ++ " "
    ++ read("16777217") ++ " "
    ++ read("340282356779733661637539395458142568447") ++ " "
    ++ read("340282356779733661637539395458142568448") ++ " "
    ++ read("7.0064923216240853546186479164495806564013097093825788587853414194489554134293030074331909418106079101562501e-46") ++ " "
    ++ read("-0.9999999701976776")

def main.lit() -> String:
  U32.show(bits(Some{0.9999999701976776})) ++ " "
    ++ U32.show(bits(Some{1.0000000596046447753906250001})) ++ " "
    ++ U32.show(bits(Some{16777217.0})) ++ " "
    ++ U32.show(bits(Some{340282356779733661637539395458142568447.0})) ++ " "
    ++ U32.show(bits(Some{7.0064923216240853546186479164495806564013097093825788587853414194489554134293030074331909418106079101562501e-46}))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(main.out())
    IO.print(main.lit())

#|1065353215 1065353217 1266679808 2139095039 2139095040 1 3212836863
#|1065353215 1065353217 1266679808 2139095039 1
