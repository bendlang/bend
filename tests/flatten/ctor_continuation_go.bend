# a constructor spells its continuation as a trailing lambda, and the
# residual effect tree prints back through the printer
# ported from bend3: local IO renamed (base owns the name), words become
# ctor nats, the doubled x + t goes affine
type W is Data:
  Z{}
  S{p: W}

type Io is Type:
  Done{value: W}
  Tick{cont: W -> Io}
  Print{text: W, cont: W -> Io}

law main:
  for f: W -> Io
  Io

def main(f):
  f(S{Z{}})

#|f => f(S{Z{}})
