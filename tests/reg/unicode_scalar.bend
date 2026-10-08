# Valid Unicode boundary scalars survive Char construction and elimination.
import Base

def roundtrip(n: U32) -> U32:
  Char.to_u32(Char.from_u32(n))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(roundtrip(55295)))
    IO.print(U32.show(roundtrip(57344)))
    IO.print(U32.show(roundtrip(1114111)))

#|55295
#|57344
#|1114111
