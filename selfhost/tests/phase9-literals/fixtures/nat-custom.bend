type Nat is Data:
  Zero{}
  Succ{pred: Nat}

def main() -> Nat:
  3n

#|3n
