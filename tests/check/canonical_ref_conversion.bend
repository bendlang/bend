# conversion is CANONICAL at the ref head: a stuck dispatch keeps its own
# ref spelling, and two of distinct defs compare by their bodies, once
# on their arguments. So two defs with byte-identical case trees convert
# applied to an opaque var (bend3, where this was ported from, refused)
import Base

type Nc is Data:
  Zc{}
  Sc{p: Nc}

law f:
  for t: Nc
  U32

def f(t):
  match t:
    case Zc{}:
      0
    case Sc{p}:
      1

law g:
  for t: Nc
  U32

def g(t):
  match t:
    case Zc{}:
      0
    case Sc{p}:
      1

law eq:
  for t: Nc
  {f(t) == g(t) : U32}

def eq(t):
  {==}

law main:
  U32

def main(): 0

#|0
