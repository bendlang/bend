type Color is Data:
  Red{}
  Green{}
  Blue{}

type Triple is Data:
  Triple{a: Color, b: Color, c: Color}

law main:
  for a: Triple
  Color

def main(a):
  match a:
    case Triple{Red{},   a, b}:
      a
    case Triple{Green{}, a, b}:
      b
    case Triple{Blue{},  a, b}:
      b

#|\{Triple: \{Red: (a => b => a); Green: (a => b => b); Blue: (a => b => b)}}
