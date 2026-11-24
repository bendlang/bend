# regression witness: emit_unfold annotated let-bound arguments with
# raw callee telescope types from tele_unbind(m.tld!.T).doms instead of
# substituting the call arguments step-by-step. A caller with a colliding
# erased parameter (-A at index 0) hijacked facts_hot, leaving the real
# instantiated ADT cold and crashing native C with SIGSEGV.
import Base

type Node is Data:
  Leaf{v: U32}
  Bin{l: Node, r: Node}

type Node2 is Data:
  Tip{v: U32}
  Fork{l: Node2, r: Node2}

type Node3 is Data:
  One{v: U32}
  Two{l: Node3, r: Node3}

def nsum(n: Node) -> U32:
  match n:
    case Leaf{v}:
      v
    case Bin{l, r}:
      U32.add(nsum(l), nsum(r))

def n2sum(n: Node2) -> U32:
  match n:
    case Tip{v}:
      v
    case Fork{l, r}:
      U32.add(n2sum(l), n2sum(r))

def n3sum(n: Node3) -> U32:
  match n:
    case One{v}:
      v
    case Two{l, r}:
      U32.add(n3sum(l), n3sum(r))

def sum_node(p: Sigma<&2, &2, Node, _ => Node>) -> U32:
  Tuple{a, b} = p
  U32.add(nsum(a), nsum(b))

def sum_node2(p: Sigma<&2, &2, Node2, _ => Node2>) -> U32:
  Tuple{a, b} = p
  U32.add(n2sum(a), n2sum(b))

def sum_node3(p: Sigma<&2, &2, Node3, _ => Node3>) -> U32:
  Tuple{a, b} = p
  U32.add(n3sum(a), n3sum(b))

def mk_node2(n: U32) -> Node2:
  Fork{Fork{Tip{n}, Tip{4}}, Tip{5}}

def dup(-A: Data, b: Bool, +x: A) -> Sigma<&2, &2, A, _ => A>:
  match b:
    case True{}:
      Tuple{x, x}
    case False{}:
      Tuple{x, x}

def bnot(b: Bool) -> Bool:
  match b:
    case True{}:
      False{}
    case False{}:
      True{}

def Pick(b: Bool) -> Data:
  match b:
    case True{}:
      Node3
    case False{}:
      U32

def dup_dep(b: Bool, +x: Pick(b)) -> Sigma<&2, &2, Pick(b), _ => Pick(b)>:
  match b:
    case True{}:
      Tuple{x, x}
    case False{}:
      Tuple{x, x}

# 1) Colliding caller -A: Type (index 0) calling dup(Node, True{}, ...)
def caller1(-A: Type, n: U32) -> U32:
  sum_node(dup(Node, True{}, Bin{Bin{Leaf{n}, Leaf{1}}, Leaf{2}}))

# 2) Caller's own erased -C: Data (index 1) passed through to dup(C, ...)
#    with a non-Var expression, while caller's index-0 -A collides with dup's -A
def caller2(-A: Type, -C: Data, mk: U32 -> C, f: Sigma<&2, &2, C, _ => C> -> U32, n: U32) -> U32:
  f(dup(C, True{}, mk(n)))

# 3) Dependent parameter type Pick(b) with earlier folded Bool argument
def caller3(-b: Bool, n: U32) -> U32:
  sum_node3(dup_dep(bnot(False{}), Two{Two{One{n}, One{6}}, One{1}}))

def main() -> IO(Unit):
  r1 = caller1(Unit, 20)
  r2 = caller2(Unit, Node2, mk_node2, sum_node2, 3)
  r3 = caller3(False{}, 5)
  IO.print(U32.show(U32.add(U32.add(r1, r2), r3)))

#|94
