type Flag is Data:
  Flag{}

type Box is Data:
  Box{+value: Flag}

def make(+x: Flag) -> Box:
  Box{x}

def use(+x: Flag) -> Flag:
  +made = make(x)
  match made:
    case Box{value}:
      value
