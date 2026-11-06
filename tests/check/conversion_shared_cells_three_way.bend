# a class of three or more share cells is still compared once: b's pair
# links c under b, a's pair then links b under a, so c is two links from
# its root, and the last pair (a, c) must follow both, or it walks the
# 18 levels as a tree. the separate ma/mb/mc make the rigid pass fail,
# so the full-book pass does the linking; 18, not more, because BendTT
# doesn't share cells yet and runs out of fuel past 19 (#1555)
import Base

def ma(x: U32, y: U32) -> U32:
  (x * 31 + y : U32)

def mb(x: U32, y: U32) -> U32:
  (x * 31 + y : U32)

def mc(x: U32, y: U32) -> U32:
  (x * 31 + y : U32)

def G(+x: U32) -> Type:
  +a0 = x
  +a1 = ma(a0, a0)
  +a2 = ma(a1, a1)
  +a3 = ma(a2, a2)
  +a4 = ma(a3, a3)
  +a5 = ma(a4, a4)
  +a6 = ma(a5, a5)
  +a7 = ma(a6, a6)
  +a8 = ma(a7, a7)
  +a9 = ma(a8, a8)
  +a10 = ma(a9, a9)
  +a11 = ma(a10, a10)
  +a12 = ma(a11, a11)
  +a13 = ma(a12, a12)
  +a14 = ma(a13, a13)
  +a15 = ma(a14, a14)
  +a16 = ma(a15, a15)
  +a17 = ma(a16, a16)
  +a18 = ma(a17, a17)
  +b0 = x
  +b1 = mb(b0, b0)
  +b2 = mb(b1, b1)
  +b3 = mb(b2, b2)
  +b4 = mb(b3, b3)
  +b5 = mb(b4, b4)
  +b6 = mb(b5, b5)
  +b7 = mb(b6, b6)
  +b8 = mb(b7, b7)
  +b9 = mb(b8, b8)
  +b10 = mb(b9, b9)
  +b11 = mb(b10, b10)
  +b12 = mb(b11, b11)
  +b13 = mb(b12, b12)
  +b14 = mb(b13, b13)
  +b15 = mb(b14, b14)
  +b16 = mb(b15, b15)
  +b17 = mb(b16, b16)
  +b18 = mb(b17, b17)
  +c0 = x
  +c1 = mc(c0, c0)
  +c2 = mc(c1, c1)
  +c3 = mc(c2, c2)
  +c4 = mc(c3, c3)
  +c5 = mc(c4, c4)
  +c6 = mc(c5, c5)
  +c7 = mc(c6, c6)
  +c8 = mc(c7, c7)
  +c9 = mc(c8, c8)
  +c10 = mc(c9, c9)
  +c11 = mc(c10, c10)
  +c12 = mc(c11, c11)
  +c13 = mc(c12, c12)
  +c14 = mc(c13, c13)
  +c15 = mc(c14, c14)
  +c16 = mc(c15, c15)
  +c17 = mc(c16, c16)
  +c18 = mc(c17, c17)
  {(b18, a18, a18) == (c18, b18, c18) : U32 & U32 & U32}

def t(+x: U32) -> G(x):
  {==}

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
