# a Base-free module's list and tuple literals and <> are its own Con,
# Nil and Tuple, alone and imported alike, whatever the entry declares
type T is Data:
  A{}
  B{}

type List is Data:
  Nil{}
  Con{head: T, tail: List}

type Tuple is Data:
  Tuple{fst: T, snd: T}

def head(xs: List) -> T:
  match xs:
    case []:
      A{}
    case x <> _:
      x

def snd(p: Tuple) -> T:
  match p:
    case (_, b):
      b

def t() -> T:
  snd((A{}, head(B{} <> [A{}])))

def main() -> T:
  t()

#|B{}
