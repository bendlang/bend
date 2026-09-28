import Base
type Choice is Data:
  Left{}
  Right{}
def f(x: Choice) -> U32:
  match x:
    case Left{}: 0
    case rest: Unit{}
