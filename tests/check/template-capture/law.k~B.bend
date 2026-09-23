import ./law.bend as L

type Empty is Data:

type Marker is Data:
  x{}

def L.k(B.x):
  x

type Bad is Type:
  MkBad{apply: @+b: L.k(~Empty) -> Empty}

def x() -> Type:
  Bad

def Bad.apply(b: Bad) -> (@+x: L.k(~Empty) -> Empty):
  match b:
    case MkBad{f}:
      f

def step(+b: L.k(~Empty)) -> Empty:
  Bad.apply(b)(MkBad{Bad.apply(b)})

def boom() -> Empty:
  step(MkBad{step})
