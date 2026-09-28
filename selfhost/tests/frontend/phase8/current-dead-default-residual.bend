# a fallback reached past a constructor's last case is dead: after
# With{Only{}}, the inner default binds a Single with no constructor
# left, so it elaborates to \{} and is never checked against the goal
# Witness(With{_}), which a stuck field cannot reduce (#1091)
import Base

type Single is Data:
  Only{}

type Choice is Data:
  With{item: Single}
  Other{}

def Witness(x: Choice) -> Type:
  match x:
    case With{Only{}}: Unit
    case rest: Unit

def witness(x: Choice) -> Witness(x):
  match x:
    case With{Only{}}: Unit{}
    case Other{}: Unit{}
    case rest: Unit{}

def main() -> Witness(Other{}):
  witness(Other{})

