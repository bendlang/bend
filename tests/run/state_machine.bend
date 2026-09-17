# a state machine at runtime: turnstile (Locked/Open) driven by an input
# list, counting passes and rejections; nested match dispatch per step
# ported from bend3: the multi-column match survives whole -- nested
# ctor patterns in the input column, the state beside it; strict, the
# continuation def folded away
import Base

type St is Data:
  Locked{}
  Open{}

type In is Data:
  Coin{}
  Push{}
  N{}
  C{i: In, t: In}

law step:
  for i    : In
  for s    : St
  for pass : U32
  for rej  : U32
  U32

def step(i, s, pass, rej):
  match i s:
    case N{} _:
      U32.add(U32.mul(pass, 10), rej)
    case C{Coin{}, t} _:
      step(t, Open{}, pass, rej)
    case C{Push{}, t} Open{}:
      step(t, Locked{}, U32.add(pass, 1), rej)
    case C{Push{}, t} Locked{}:
      step(t, Locked{}, pass, U32.add(rej, 1))
    case C{N{}, t} _:
      99
    case C{C{a, b}, t} _:
      99
    case Coin{} _:
      99
    case Push{} _:
      99

law main.out:
  U32

def main.out():
  ins = {C{Push{}, C{Coin{}, C{Push{}, C{Coin{}, C{Coin{}, C{Push{}, N{}}}}}}} : In}
  step(ins, Locked{}, 0, 0)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|21
