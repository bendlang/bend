# A language scientist needs a streaming codec for symbolic binary trees.
# Emit postfix bytecode into a supplied continuation. Join pops right, then left;
# stack underflow rejects. Prove execution and the exact converse: every program
# accepted from an empty stack with one tree is precisely that tree's encoding.
import Base

type Tree is Data:
  Leaf{symbol: Nat}
  Fork{left: Tree, right: Tree}

type Token is Data:
  Push{symbol: Nat}
  Join{}

def run(p: List<&2, Token>, s: List<&2, Tree>) -> Maybe<&2, List<&2, Tree>>:
  match p:
    case Nil{}:
      Some{s}
    case Con{h, t}:
      match h:
        case Push{n}:
          run(t, Con{Leaf{n}, s})
        case Join{}:
          match s:
            case Nil{}:
              None{}
            case Con{r, rest}:
              match rest:
                case Nil{}:
                  None{}
                case Con{l, tail}:
                  run(t, Con{Fork{l, r}, tail})

law emit:
  for t: Tree
  for k: List<&2, Token>
  List<&2, Token>

law emit_leaf:
  for n: Nat
  for k: List<&2, Token>
  {emit(Leaf{n}, k) == Con{Push{n}, k} : List<&2, Token>}

law emit_fork:
  for l: Tree
  for r: Tree
  for k: List<&2, Token>
  {emit(Fork{l, r}, k) == emit(l, emit(r, Con{Join{}, k})) : List<&2, Token>}

law execution:
  for t: Tree
  for +s: List<&2, Tree>
  for +k: List<&2, Token>
  {run(emit(t, k), s) == run(k, Con{t, s}) : Maybe<&2, List<&2, Tree>>}

law complete:
  for +p: List<&2, Token>
  for +t: Tree
  for e: {run(p, Nil{}) == Some{Con{t, Nil{}}} : Maybe<&2, List<&2, Tree>>}
  {emit(t, Nil{}) == p : List<&2, Token>}

# solution

def emit(t, k):
  match t:
    case Leaf{n}:
      Con{Push{n}, k}
    case Fork{l, r}:
      emit(l, emit(r, Con{Join{}, k}))

def emit_leaf(n, k):
  {==}

def emit_fork(l, r, k):
  {==}

def execution(t, s, k):
  match t:
    case Leaf{n}:
      {==}
    case Fork{+l, +r}:
      %execution(r, Con{l, s}, Con{Join{}, k}) :
        {run(emit(l, emit(r, Con{Join{}, k})), s) == _ : Maybe<&2, List<&2, Tree>>}
      execution(l, s, emit(r, Con{Join{}, k}))

def record(s: List<&2, Tree>, k: List<&2, Token>) -> List<&2, Token>:
  match s:
    case Nil{}:
      k
    case Con{t, rest}:
      record(rest, emit(t, k))

def Trace(code: List<&2, Token>, r: Maybe<&2, List<&2, Tree>>) -> Type:
  match r:
    case None{}:
      Unit
    case Some{out}:
      {record(out, Nil{}) == code : List<&2, Token>}

def trace(+p: List<&2, Token>, +s: List<&2, Tree>) -> Trace(record(s, p), run(p, s)):
  match p:
    case Nil{}:
      {==}
    case Con{h, t}:
      match h:
        case Push{n}:
          trace(t, Con{Leaf{n}, s})
        case Join{}:
          match s:
            case Nil{}: Unit{}
            case Con{r, rest}:
              match rest:
                case Nil{}: Unit{}
                case Con{l, tail}: trace(t, Con{Fork{l, r}, tail})

def complete(p, t, e):
  %e : Trace(p, _)
  trace(p, Nil{})
