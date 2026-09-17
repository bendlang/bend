type Bit is Data:
  Zer{}
  One{}

type BitPair is Data:
  Pair{f: Bit, s: Bit}

law main:
  for a: BitPair
  Bit

def main(a):
  match a:
    case Pair{Zer{}, a}:
      a
    case Pair{One{}, a}:
      a

#|\{Pair: \{Zer: (a => a); One: (a => a)}}
