# assert as a plain fn signature: the term-less entry's type is a chain
# of alls, and the later unannotated `def add(x,y):` fills it.
# ported from bend3: + becomes U32.add
import Base

law add:
  for x: U32
  for y: U32
  U32

def add(x, y):
  U32.add(x, y)

law main:
  U32

def main():
  add(40, 2)

#|42
