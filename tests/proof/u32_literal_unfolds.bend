# a u32 literal is one Lit node whose word unfolds whole where a chain
# is read: a comparison sees a wide literal as its U32{WCon{..}} and a
# wrapping operation reduces onto one, and a match reads a wide literal
# pattern
import Base

law wrap_inc:
  {U32.inc(4294967295) == 0 : U32}

def wrap_inc():
  {==}

law wrap_add:
  {U32.add(4294967290, 10) == 4 : U32}

def wrap_add():
  {==}

law add_zero:
  {U32.add(3000000000, 0) == 3000000000 : U32}

def add_zero():
  {==}

law sub_wrap:
  {U32.sub(0, 1) == 4294967295 : U32}

def sub_wrap():
  {==}

def classify(n: U32) -> U32:
  match n:
    case 3000000000:
      7
    case 4294967295:
      9
    case _:
      1

law classify_big:
  {classify(3000000000) == 7 : U32}

def classify_big():
  {==}

def main() -> U32:
  U32.add(classify(3000000000), classify(4294967295))

#|16
