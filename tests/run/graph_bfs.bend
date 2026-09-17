# graph reachability over an adjacency-bitmask array: BFS by frontier
# masks (visited fixpoint), the unreachable island stays out
# ported from bend3: the slab becomes Array.new + swap writes (8 = 2^3
# slots), counters become Nat, shift counts ride U32.to_nat; strict --
# the read/dispatch defs folded into the counter matches, shared words
# +U32, walked Nats +Nat
import Base

law wr:
  for m: Array<U32>
  for i: U32
  for v: U32
  Array<U32>

law wr.fin:
  for w: Array<U32> & U32
  Array<U32>

def wr.fin(w):
  (m2, old) = w
  m2

def wr(m, i, v):
  wr.fin(Array.swap(U32, m, i, v))

law gather.pick:
  for acc : U32
  for row : U32
  for z   : Bool
  U32

def gather.pick(acc, row, z):
  match z:
    case True{}:
      acc
    case False{}:
      U32.or(acc, row)

law gather:
  for i         : Nat
  for w         : Array<U32> & U32
  for +frontier : U32
  for acc       : U32
  (Array<U32> & U32)

def gather(i, w, frontier, acc):
  match i:
    case 0n:
      (m2, row) = w
      (m2, acc)
    case 1n+p0:
      (m2, row) = w
      +p = {p0 : Nat}
      +j = {U32.from_nat(p) : U32}
      gather(p, Array.get(U32, m2, U32.from_nat(Nat.sub(p, 1n))), frontier,
        gather.pick(acc, row, U32.is_zero(U32.and(U32.shrn(frontier, U32.to_nat(j)), 1))))

law bfs.step:
  for +visited : U32
  for g        : Array<U32> & U32
  Array<U32> & U32

def bfs.step(visited, g):
  (m3, next) = g
  (m3, U32.or(visited, next))

law bfs:
  for fuel : Nat
  for w    : Array<U32> & U32
  (Array<U32> & U32)

def bfs(fuel, w):
  match fuel:
    case 0n:
      w
    case 1n+f:
      (m2, visited0) = w
      +visited = {visited0 : U32}
      bfs(f, bfs.step(visited, gather(8n, Array.get(U32, m2, 7), visited, 0)))

law pop:
  for i   : Nat
  for +n  : U32
  for acc : U32
  U32

def pop(i, n, acc):
  match i:
    case 0n:
      acc
    case 1n+p:
      pop(p, U32.shr(n), U32.add(acc, U32.and(n, 1)))

law build:
  Array<U32>

def build():
  wr(wr(wr(wr(wr(wr([0 : U32*8n], 0, 6), 1, 8), 2, 24), 3, 32), 5, 2), 6, 128)

law go:
  for m: Array<U32>
  U32

law go.fin:
  for w: Array<U32> & U32
  U32

def go.fin(w):
  (m2, reach0) = w
  +reach = {reach0 : U32}
  U32.add(U32.mul(reach, 100), pop(8n, reach, 0))

def go(m):
  go.fin(bfs(8n, (m, 1)))

law main.out:
  U32

def main.out():
  go(wr(build(), 7, 64))

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|6306
