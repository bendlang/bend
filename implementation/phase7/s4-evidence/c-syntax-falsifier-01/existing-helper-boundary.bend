type Flag is Data:
  Flag{}

type Box is Data:
  Box{+value: Flag}

def make(+x: Flag) -> Box:
  Box{x}

def take(+b: Box) -> Flag:
  match b:
    case Box{value}:
      value

def use(+x: Flag) -> Flag:
  take(make(x))
