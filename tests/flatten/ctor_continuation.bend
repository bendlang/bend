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

law go:
  for f: W -> Io
  Io

def go(f):
  f(S{Z{}})

law main:
  Io

def main():
  go(n => Print{n, x => Tick{t => Done{S{x}}}})

#|Print{S{Z{}}, x => Tick{t => Done{S{x}}}}
