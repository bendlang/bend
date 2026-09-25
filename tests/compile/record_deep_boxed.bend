# a value past 247 words travels boxed: BoxK<BoxK<U32>> is 64 flat words,
# one level more is one box of a 512-word node, and the level above eight
# boxes, flat again. The seeded build crosses the box on the way in
# and the match on the way out; the constant chain (#843, 8^7 words at
# depth 7) folds to one static image
import Base

type BoxK<-a: Data> is Data:
  BoxK{f0: a, f1: a, f2: a, f3: a, f4: a, f5: a, f6: a, f7: a}

law mk1:
  for +x: U32
  BoxK<U32>

def mk1(x):
  BoxK{
    x,
    (x + 1 : U32),
    (x + 2 : U32),
    (x + 3 : U32),
    (x + 4 : U32),
    (x + 5 : U32),
    (x + 6 : U32),
    (x + 7 : U32)}

law mk2:
  for +x: U32
  BoxK<BoxK<U32>>

def mk2(x):
  BoxK{
    mk1(x),
    mk1((x + 8 : U32)),
    mk1((x + 16 : U32)),
    mk1((x + 24 : U32)),
    mk1((x + 32 : U32)),
    mk1((x + 40 : U32)),
    mk1((x + 48 : U32)),
    mk1((x + 56 : U32))}

law mk3:
  for +x: U32
  BoxK<BoxK<BoxK<U32>>>

def mk3(x):
  BoxK{
    mk2(x),
    mk2((x + 64 : U32)),
    mk2((x + 128 : U32)),
    mk2((x + 192 : U32)),
    mk2((x + 256 : U32)),
    mk2((x + 320 : U32)),
    mk2((x + 384 : U32)),
    mk2((x + 448 : U32))}

law mk4:
  for +x: U32
  BoxK<BoxK<BoxK<BoxK<U32>>>>

def mk4(x):
  BoxK{
    mk3(x),
    mk3((x + 512 : U32)),
    mk3((x + 1024 : U32)),
    mk3((x + 1536 : U32)),
    mk3((x + 2048 : U32)),
    mk3((x + 2560 : U32)),
    mk3((x + 3072 : U32)),
    mk3((x + 3584 : U32))}

law one1:
  BoxK<U32>

def one1():
  BoxK{1, 1, 1, 1, 1, 1, 1, 1}

law one2:
  BoxK<BoxK<U32>>

def one2():
  BoxK{one1(), one1(), one1(), one1(), one1(), one1(), one1(), one1()}

law one3:
  BoxK<BoxK<BoxK<U32>>>

def one3():
  BoxK{one2(), one2(), one2(), one2(), one2(), one2(), one2(), one2()}

law one4:
  BoxK<BoxK<BoxK<BoxK<U32>>>>

def one4():
  BoxK{one3(), one3(), one3(), one3(), one3(), one3(), one3(), one3()}

law dig:
  for b: BoxK<BoxK<BoxK<BoxK<U32>>>>
  U32

def dig(b):
  match b:
    case BoxK{a0, a1, a2, a3, a4, a5, a6, a7}:
      match a5:
        case BoxK{b0, b1, b2, b3, b4, b5, b6, b7}:
          match b2:
            case BoxK{c0, c1, c2, c3, c4, c5, c6, c7}:
              match c7:
                case BoxK{d0, d1, d2, d3, d4, d5, d6, d7}:
                  d3

law main.out:
  U32

def main.out():
  (dig(mk4(0)) + dig(one4()) : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|2748
