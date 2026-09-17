# a cons chain off a non-list tail prints as a <> b <> t, at the parser's
# precedence: the interpreter shows a stuck tail (a parameter); no Base,
# so no compiled lane
type List is Data:
  Nil{}
  Con{head: List, tail: List}

def chain(t: List) -> List:
  Con{Nil{}, Con{Nil{}, t}}

def main() -> List -> List:
  t => chain(t)

#|t => [] <> [] <> t
