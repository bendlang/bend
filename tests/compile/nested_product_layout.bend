# A nested product must not keep flattening its fields into exponentially
# large inline layouts.
import Base

type BoxK<-a: Data> is Data:
  BoxK{f0: a, f1: a, f2: a, f3: a, f4: a, f5: a, f6: a, f7: a}

def mk0() -> U32:
  1

def mk1() -> BoxK<U32>:
  BoxK{mk0(), mk0(), mk0(), mk0(), mk0(), mk0(), mk0(), mk0()}

def mk2() -> BoxK<BoxK<U32>>:
  BoxK{mk1(), mk1(), mk1(), mk1(), mk1(), mk1(), mk1(), mk1()}

def mk3() -> BoxK<BoxK<BoxK<U32>>>:
  BoxK{mk2(), mk2(), mk2(), mk2(), mk2(), mk2(), mk2(), mk2()}

def mk4() -> BoxK<BoxK<BoxK<BoxK<U32>>>>:
  BoxK{mk3(), mk3(), mk3(), mk3(), mk3(), mk3(), mk3(), mk3()}

def mk5() -> BoxK<BoxK<BoxK<BoxK<BoxK<U32>>>>>:
  BoxK{mk4(), mk4(), mk4(), mk4(), mk4(), mk4(), mk4(), mk4()}

def mk6() -> BoxK<BoxK<BoxK<BoxK<BoxK<BoxK<U32>>>>>>:
  BoxK{mk5(), mk5(), mk5(), mk5(), mk5(), mk5(), mk5(), mk5()}

def mk7() -> BoxK<BoxK<BoxK<BoxK<BoxK<BoxK<BoxK<U32>>>>>>>:
  BoxK{mk6(), mk6(), mk6(), mk6(), mk6(), mk6(), mk6(), mk6()}

def top(p: BoxK<BoxK<BoxK<BoxK<BoxK<BoxK<BoxK<U32>>>>>>>) -> U32:
  0

def main() -> IO(Unit):
  IO.print(U32.show(top(mk7())))

#|0
