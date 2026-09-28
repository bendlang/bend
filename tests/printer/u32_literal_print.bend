# a u32 literal prints back as its number, and a term built on wide
# literals prints as it was written
import Base

def wide(a: U32) -> U32:
  U32.add(3000000000, a)

def main(a: U32, b: U32) -> U32:
  U32.add(wide(a), U32.add(4294967295, b))

#|a => b => U32.add(U32.add(3000000000, a), U32.add(4294967295, b))
