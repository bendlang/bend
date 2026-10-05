type In is Data:
  Mk{}

def Unit() -> In:
  Mk{}

def idt(~A: Type, x: A) -> A:
  x

def main() -> In:
  idt(~In, Mk{})

#|Mk{}
