# drops: deep both ways, a spine that is not the last field, shared subtrees dropped by several holders
# and threads, constants, arrays and closures inside nodes
import Base

type Tree is Data:
  Leaf{}
  Node{l: Tree, key: U32, r: Tree}

type Snoc is Data:
  QNil{}
  Sn{init: Snoc, t: Tree, x: U32}

type Rose is Data:
  Rose{v: U32, kids: List<&2, Rose>}

type Obj is Type:
  ONil{}
  Obj{f: U32 -> U32, a: Array<U32>, t: Tree, next: Obj}

def lit() -> Tree:
  Node{Node{Leaf{}, 1, Leaf{}}, 2, Node{Leaf{}, 3, Leaf{}}}

def left(+n: Nat, acc: Tree) -> Tree:
  match n:
    case 0n:
      acc
    case 1n+p:
      left(p, Node{acc, U32.from_nat(n), Leaf{}})

def right(+n: Nat, acc: Tree) -> Tree:
  match n:
    case 0n:
      acc
    case 1n+p:
      right(p, Node{Leaf{}, U32.from_nat(n), acc})

# both children are one shared subtree, all the way down
def dag(+n: Nat) -> Tree:
  match n:
    case 0n:
      lit()
    case 1n+p:
      +s = dag(p)
      Node{s, U32.from_nat(n), s}

def gen(+d: Nat, +i: U32) -> Tree:
  match d:
    case 0n:
      Leaf{}
    case 1n+e:
      Node{gen(e, U32.mul(i, 2)), i, gen(e, U32.add(U32.mul(i, 2), 1))}

def top(t: Tree) -> U32:
  match t:
    case Leaf{}:
      7
    case Node{l, k, r}:
      k

def snoc(+n: Nat, +t: Tree, acc: Snoc) -> Snoc:
  match n:
    case 0n:
      acc
    case 1n+p:
      snoc(p, t, Sn{acc, t, U32.from_nat(n)})

def snoc_top(s: Snoc) -> U32:
  match s:
    case QNil{}:
      0
    case Sn{i, t, x}:
      U32.add(x, top(t))

@unsafe def rose(+d: Nat, +w: Nat, +i: U32) -> Rose:
  match d:
    case 0n:
      Rose{i, []}
    case 1n+e:
      Rose{i, rose.kids(e, w, w, i)}

@unsafe def rose.kids(+d: Nat, +w: Nat, +j: Nat, +i: U32) -> List<&2, Rose>:
  match j:
    case 0n:
      []
    case 1n+q:
      rose(d, w, U32.add(i, U32.from_nat(j))) <> rose.kids(d, w, q, i)

def rose_top(r: Rose) -> U32:
  match r:
    case Rose{v, ks}:
      U32.add(v, U32.from_nat(List.length(&2, Rose, ks)))

def objs(+n: Nat, +t: Tree, acc: Obj) -> Obj:
  match n:
    case 0n:
      acc
    case 1n+p:
      +m = U32.from_nat(n)
      objs(p, t, Obj{U32.add(m), Array.new(U32, 3n, m), t, acc})

def obj_top(o: Obj) -> U32:
  match o:
    case ONil{}:
      0
    case Obj{f, a, t, nx}:
      U32.add(f(1), top(t))

# several holders of one tree drop it, some on other threads
def holders(+n: Nat, +t: Tree) -> U32:
  match n:
    case 0n:
      top(t)
    case 1n+p:
      a b = top(t) holders(p, t)
      U32.add(a, b)

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.print(U32.show(top(left(300000n, Leaf{}))))
    Unit <- IO.print(U32.show(top(right(300000n, Leaf{}))))
    Unit <- IO.print(U32.show(top(dag(40n))))
    Unit <- IO.print(U32.show(snoc_top(snoc(200000n, gen(3n, 1), QNil{}))))
    Unit <- IO.print(U32.show(snoc_top(snoc(1000n, lit(), QNil{}))))
    Unit <- IO.print(U32.show(rose_top(rose(6n, 5n, 1))))
    Unit <- IO.print(U32.show(obj_top(objs(5000n, gen(4n, 1), ONil{}))))
    Unit <- IO.print(U32.show(holders(2000n, dag(30n))))
    Unit <- IO.print(U32.show(holders(2000n, gen(8n, 1))))
    IO.print(U32.show(holders(300n, left(70n, gen(5n, 1)))))

#|1
#|1
#|40
#|2
#|3
#|6
#|3
#|60030
#|2001
#|301
