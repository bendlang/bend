import Base
type Single is Data:
  Only{}
def f(x: Single) -> U32:
  match x:
    case Only{}: 0
    case rest: Unit{}
def main() -> U32: f(Only{})
