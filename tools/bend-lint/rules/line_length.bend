# style/line-length: a line longer than the option `max` (100 by default),
# in characters. The finding covers the part past the limit. No fix.
import Base
import ../src/lint.bend as Lint
import ./shared.bend as Shared

def id() -> String:
  "style/line-length"

def types() -> Bool:
  False{}

def diag(path: String, +max: U32, +beg: U32, +len: U32) -> Lint.Diag:
  Lint.Diag{Lint.Warning{}, "Keep the line to " ++ U32.show(max) ++ " characters; it has " ++ U32.show(len) ++ ".", Some{Lint.Span{path, U32.add(beg, max), U32.add(beg, len)}}, []}

def keep(long: Bool, +path: String, +max: U32, +beg: U32, +len: U32, acc: List<&2, Lint.Diag>) -> List<&2, Lint.Diag>:
  match long:
    case True{}:
      diag(path, max, beg, len) <> acc
    case False{}:
      acc

# The lines come last first, so adding each finding to the front puts them
# in order. A tail call.
def scan(+path: String, +max: U32, lines: List<&2, Shared.Line>, acc: List<&2, Lint.Diag>) -> List<&2, Lint.Diag>:
  match lines:
    case Nil{}:
      acc
    case Con{Shared.Line{+beg, +len}, rest}:
      scan(path, max, rest, keep(U32.is_gt(len, max), path, max, beg, len, acc))

def check(+max: U32, src: Maybe<&2, Lint.Source>) -> List<&2, Lint.Diag>:
  match src:
    case None{}:
      []
    case Some{Lint.Source{path, text, root}}:
      scan(path, max, Shared.lines(text), [])

def run(input: Lint.Input) -> IO(List<&2, Lint.Diag>):
  match input:
    case Lint.Input{sources, facts, options}:
      IO.pure(List<&2, Lint.Diag>, check(Lint.option_number(options, "max", 100), Shared.root(sources)))

def main() -> IO(Unit):
  Lint.serve(run)
