# Helpers for the rules in this folder that are written in Bend.
import Base
import ../src/lint.bend as Lint

# A line of a text: the offset of its first character, and its length
# without the line break (nor a \r before it).
type Line is Data:
  Line{beg: U32, len: U32}

def lines.beg(nl: Bool, +at: U32, beg: U32) -> U32:
  match nl:
    case True{}:
      U32.add(at, 1)
    case False{}:
      beg

def lines.len(nl: Bool, len: U32) -> U32:
  match nl:
    case True{}:
      0
    case False{}:
      U32.add(len, 1)

def lines.cut(cr: Bool, len: U32) -> U32:
  match cr:
    case True{}:
      U32.sub(len, 1)
    case False{}:
      len

def lines.push(nl: Bool, beg: U32, len: U32, cr: Bool, acc: List<&2, Line>) -> List<&2, Line>:
  match nl:
    case True{}:
      Line{beg, lines.cut(cr, len)} <> acc
    case False{}:
      acc

# A tail call: bend runs it as a loop, so a long text does not overflow the
# stack. `cr` says the last character was a \r.
def lines.go(s: String, +at: U32, +beg: U32, +len: U32, cr: Bool, acc: List<&2, Line>) -> List<&2, Line>:
  match s:
    case SNil{}:
      Line{beg, len} <> acc
    case SCon{+c, rest}:
      lines.go(rest, U32.add(at, 1), lines.beg(Char.is_eq(c, '\n'), at, beg), lines.len(Char.is_eq(c, '\n'), len), Char.is_eq(c, '\r'), lines.push(Char.is_eq(c, '\n'), beg, len, cr, acc))

# The lines of a text, the last one first.
def lines(s: String) -> List<&2, Line>:
  lines.go(s, 0, 0, 0, False{}, [])

def root_or(root: Bool, s: Lint.Source, later: Maybe<&2, Lint.Source>) -> Maybe<&2, Lint.Source>:
  match root:
    case True{}:
      Some{s}
    case False{}:
      later

def is_root(s: Lint.Source) -> Bool:
  match s:
    case Lint.Source{path, text, root}:
      root

# The source of the file linted.
def root(srcs: List<&2, Lint.Source>) -> Maybe<&2, Lint.Source>:
  match srcs:
    case Nil{}:
      None{}
    case Con{+s, rest}:
      root_or(is_root(s), s, root(rest))
