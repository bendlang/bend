# Official BLAKE3 vectors around the chunk boundary and an odd 31-chunk tree.
import Base
import ../../bend2/hashes/main.bend as Hashes

def Vec.go(n: Nat, +i: U32, acc: List<&2,U32>) -> List<&2,U32>:
  match n:
    case 0n:
      List.reverse(&2,U32,acc)
    case 1n+p:
      Vec.go(p,U32.add(i,1),U32.mod(i,251) <> acc)

def Vec.bytes(n: Nat) -> List<&2,U32>:
  Vec.go(n,0,Nil{})

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Hashes.BLAKE3.hex(Vec.bytes(1023n)))
    IO.print(Hashes.BLAKE3.hex(Vec.bytes(1024n)))
    IO.print(Hashes.BLAKE3.hex(Vec.bytes(1025n)))
    IO.print(Hashes.BLAKE3.hex(Vec.bytes(31744n)))

#|10108970eeda3eb932baac1428c7a2163b0e924c9a9e25b35bba72b28f70bd11
#|42214739f095a406f3fc83deb889744ac00df831c10daa55189b5d121c855af7
#|d00278ae47eb27b34faecf67b4fe263f82d5412916c1ffd97c8cb7fb814b8444
#|62b6960e1a44bcc1eb1a611a8d6235b6b4b78f32e7abc4fb4c6cdcce94895c47
