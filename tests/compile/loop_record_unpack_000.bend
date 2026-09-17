# loop-record unpack: a self-tail def's single-ctor record param
# destructures at entry and rides the back edge. Covers the literal
# back edge, an exit with the record, an arm that never touches it, a
# helper-produced back edge, and a def with no destructure at all
# ported from bend3: counters walk Nats, % spells U32.mod
import Base

type St is Data:
  MkSt{a: U32, b: U32}

law sum:
  for st: St
  U32

def sum(st):
  MkSt{a, b} = st
  U32.add(a, b)

law go:
  for +i : Nat
  for st : St
  St

def go(i, st):
  match i:
    case 0n:
      st
    case 1n+p:
      MkSt{a, b} = st
      go(p, MkSt{b, U32.mod(U32.add(a, U32.add(1, U32.from_nat(p))), 65521)})

law step:
  for st: St
  St

def step(st):
  MkSt{a, b} = st
  MkSt{b, U32.mod(U32.mul(a, 3), 65521)}

law go2:
  for i  : Nat
  for st : St
  U32

def go2(i, st):
  match i:
    case 0n:
      sum(st)
    case 1n+p:
      go2(p, step(st))

law go3:
  for i  : Nat
  for st : St
  U32

def go3(i, st):
  match i:
    case 0n:
      7
    case 1n+p:
      MkSt{a, b} = st
      go3(p, MkSt{b, a})

law go4:
  for i  : Nat
  for st : St
  U32

def go4(i, st):
  match i:
    case 0n:
      MkSt{a, b} = st
      U32.add(a, b)
    case 1n+p:
      go4(p, step(st))

law main.out:
  U32

def main.out():
  U32.add(U32.add(U32.add(sum(go(12n, MkSt{1, 2})), go2(9n, MkSt{3, 4})), go3(5n, MkSt{5, 6})), go4(8n, MkSt{7, 8}))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|2356
