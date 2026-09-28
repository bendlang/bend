# a redex whose body is an annotated lambda-match applied on: the beta
# steps keep the annotation, which is what lets the match infer (this
# file declares its own Nat: no Base, no build)
type Nat is Data:
  Zero{}
  Succ{pred: Nat}

def main() -> Nat:
  (x => {\{Zero: 1n; Succ: p => 2n} : Nat -> Nat})(0n)(3n)

#|2n
