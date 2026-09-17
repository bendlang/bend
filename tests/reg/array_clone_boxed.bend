# regression witness: Array.clone of an ARR (boxed elements) retains
# every element -- blk_copy once copied the owning handles raw, so the
# two arrays owned each element twice and the second drop freed it
# again. Both copies are read, one is swapped, one is dropped unread;
# the leaves come from Array.new (one handle shared by 2^d cells) and
# from constructors (a five-node String in one leaf).
import Base

law rd:
  for a: Array<String>
  String

def rd(a):
  match a:
    case ALeaf{x}:
      x
    case ANode{xs, ys}:
      String.append(rd(xs), rd(ys))

law drop:
  for a: Array<String>
  for s: String
  String

def drop(a, s):
  s

law both:
  for c: Array<String> & Array<String>
  String

def both(c):
  (a, b) = c
  String.append(rd(a), rd(b))

law one:
  for c: Array<String> & Array<String>
  String

def one(c):
  (a, b) = c
  drop(a, rd(b))

law swap.fin:
  for a: Array<String>
  for w: Array<String> & String
  String

def swap.fin(a, w):
  (b, old) = w
  String.append(rd(a), String.append(rd(b), old))

law swap.go:
  for c: Array<String> & Array<String>
  String

def swap.go(c):
  (a, b) = c
  swap.fin(a, Array.swap(String, b, 2, "zz"))

law main.out:
  String

def main.out():
  p = both(Array.clone(String, ["ab" : String*4n]))
  q = one(Array.clone(String, ANode{ALeaf{"hello"}, ALeaf{"world"}}))
  r = swap.go(Array.clone(String,
    ANode{ANode{ALeaf{"a"}, ALeaf{"b"}}, ANode{ALeaf{"c"}, ALeaf{"d"}}}))
  s = one(Array.clone(String, ALeaf{"leaf"}))
  String.append(p, String.append(q, String.append(r, s)))

law main:
  IO(Unit)

def main():
  IO.print(main.out())

#|ababababababababhelloworldabcdabzzdcleaf
