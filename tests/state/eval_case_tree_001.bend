# 4-ctor enum ladder, complete: all four arms close by computation;
# the proof value refolds to the ref (main's eta form replaces --eval)
type Dir is Data:
  Up{}
  Rt{}
  Dn{}
  Lf{}

law turn:
  for d: Dir
  Dir

def turn(d):
  match d:
    case Up{}:
      Rt{}
    case Rt{}:
      Dn{}
    case Dn{}:
      Lf{}
    case Lf{}:
      Up{}

law back:
  for d: Dir
  Dir

def back(d):
  match d:
    case Up{}:
      Dn{}
    case Rt{}:
      Lf{}
    case Dn{}:
      Up{}
    case Lf{}:
      Rt{}

law turn_turn:
  for d: Dir
  {turn(turn(d)) == back(d) : Dir}

def turn_turn(d):
  match d:
    case Up{}:
      {==}
    case Rt{}:
      {==}
    case Dn{}:
      {==}
    case Lf{}:
      {==}

law main:
  @d: Dir -> {turn(turn(d)) == back(d) : Dir}

def main():
  d => turn_turn(d)

#|d => turn_turn(d)
