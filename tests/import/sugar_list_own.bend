import ./sugar_list_own_lib.bend as L

type List is Data:
  Nil{}
  Con{head: L.T, tail: List}

type Tuple is Data:
  Tuple{fst: L.T, snd: L.T}

def main() -> L.T:
  L.t()

#|sugar_list_own_lib.B{}
