# Invalid Char construction must not disappear in a following to_u32.
import Base

def roundtrip(n: U32) -> U32:
  Char.to_u32(Char.from_u32(n))

def main() -> IO(Unit):
  IO.print(U32.show(roundtrip(57343)))

#|bend: 57343 is not a Unicode scalar value
#|exit 1
