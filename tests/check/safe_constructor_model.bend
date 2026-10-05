type In is Data:
  Mk{}

type Out is Data:
  Wrap{value: In}

def id(~x: Out) -> Out:
  x

def main() -> Out:
  id(~Wrap{Mk{}})

#|Wrap{Mk{}}
