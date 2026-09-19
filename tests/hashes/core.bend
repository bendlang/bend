# Internal word primitives: carry and rotation counts normalize by width.
import Base
import ../../bend2/hashes/internal/core.bend as C

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(C.Hex.bytes(C.Bytes.u64be(C.W64.add(C.W64{0,4294967295},C.W64{0,1}),Nil{})))
    IO.print(C.Hex.bytes(C.Bytes.u32be(C.Bits.rotr32(305419896,33n),Nil{})))
    IO.print(C.Hex.bytes(C.Bytes.u32be(C.Bits.rotl32(305419896,33n),Nil{})))
    IO.print(C.Hex.bytes(C.Bytes.u64be(C.W64.rotr(C.W64{19088743,2309737967},65n),Nil{})))
    IO.print(C.Hex.bytes(C.Bytes.u64be(C.W64.rotl(C.W64{19088743,2309737967},128n),Nil{})))

#|0000000100000000
#|091a2b3c
#|2468acf0
#|8091a2b3c4d5e6f7
#|0123456789abcdef
