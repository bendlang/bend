# The contract between bend-lint and a rule written in Bend. A rule file
# imports this file and defines:
#
#   def id() -> String:          # namespace/name, the code of its findings
#   def types() -> Bool:         # True{} to get the checker's facts
#   def run(input: Lint.Input) -> IO(List<&2, Lint.Diag>):
#   def main() -> IO(Unit):
#     Lint.serve(run)
#
# Offsets count characters (code points) from the start of a file. The
# rule's options come from bend-lint.json; read them with option_number,
# option_flag and option_text, each with a default.
import Base

# A checked term, and a type: indexes into bend-lint's tables for one run.
# Only the effects below read them.
type Fact is Data:
  Fact{id: U32}

type Term is Data:
  Term{id: U32}

type Source is Data:
  Source{path: String, text: String, root: Bool}

# An option's value: a whole number (a U32), a boolean, or text.
type Value is Data:
  Num{value: U32}
  Flag{value: Bool}
  Text{value: String}

type Option is Data:
  Option{key: String, value: Value}

type Input is Data:
  Input{sources: List<&2, Source>, facts: List<&2, Fact>, options: List<&2, Option>}

type Span is Data:
  Span{path: String, beg: U32, end: U32}

type Severity is Data:
  Error{}
  Warning{}
  Information{}
  Hint{}

# Safe keeps behavior; Suggested may change it; Dangerous may break code.
type Applicability is Data:
  Safe{}
  Suggested{}
  Dangerous{}

type Edit is Data:
  Edit{span: Span, text: String}

type Fix is Data:
  Fix{title: String, applicability: Applicability, edits: List<&2, Edit>}

type Diag is Data:
  Diag{severity: Severity, message: String, span: Maybe<&2, Span>, fixes: List<&2, Fix>}

# How many times a term may be used.
type Quantity is Data:
  Erased{}
  Once{}
  Many{}

type Use is Data:
  Use{name: String, quantity: Quantity}

# A fact as bend-lint sees it: the def it is in, whether that def is a
# template instance, the kind of its term once an annotation is stripped
# (Var, App, ...), the name a Var refers to (else ""), how many times the
# term is demanded, and the spans of the checked term and of the stripped
# one.
type View is Data:
  View{owner: String, inst: Bool, kind: String, name: String, quantity: Quantity, span: Maybe<&2, Span>, inner: Maybe<&2, Span>}

def input() -> IO(Input):
  import "./lint.js"

def report(diags: List<&2, Diag>) -> IO(Unit):
  import "./lint.js"

def view(fact: Fact) -> IO(View):
  import "./lint.js"

# The type the fact's term was checked against, or inferred.
def type_of(fact: Fact) -> IO(Term):
  import "./lint.js"

# The type of the binder a Var fact refers to.
def binder(fact: Fact) -> IO(Maybe<&2, Term>):
  import "./lint.js"

# Whether two types are equal, as the checker compares them in the fact's
# scope.
def same(fact: Fact, a: Term, b: Term) -> IO(Bool):
  import "./lint.js"

def show(fact: Fact, t: Term) -> IO(String):
  import "./lint.js"

# The normal form of a type, in the fact's scope.
def normal(fact: Fact, t: Term) -> IO(Term):
  import "./lint.js"

# The variables the fact's term uses, each with how many times.
def uses(fact: Fact) -> IO(List<&2, Use>):
  import "./lint.js"

# The text under a span, in the file on disk.
def text(span: Span) -> IO(String):
  import "./lint.js"

def pick(hit: Bool, v: Value, later: Maybe<&2, Value>) -> Maybe<&2, Value>:
  match hit:
    case True{}:
      Some{v}
    case False{}:
      later

# The value of an option, if it is given.
def find(opts: List<&2, Option>, +key: String) -> Maybe<&2, Value>:
  match opts:
    case Nil{}:
      None{}
    case Con{Option{k, v}, rest}:
      pick(String.eq(k, key), v, find(rest, key))

def option_number_or(m: Maybe<&2, Value>, default: U32) -> U32:
  match m:
    case Some{Num{n}}:
      n
    case Some{Flag{b}}:
      default
    case Some{Text{t}}:
      default
    case None{}:
      default

# An option's value, or `default` when it is not given or of another type.
def option_number(opts: List<&2, Option>, key: String, default: U32) -> U32:
  option_number_or(find(opts, key), default)

def option_flag_or(m: Maybe<&2, Value>, default: Bool) -> Bool:
  match m:
    case Some{Flag{b}}:
      b
    case Some{Num{n}}:
      default
    case Some{Text{t}}:
      default
    case None{}:
      default

def option_flag(opts: List<&2, Option>, key: String, default: Bool) -> Bool:
  option_flag_or(find(opts, key), default)

def option_text_or(m: Maybe<&2, Value>, default: String) -> String:
  match m:
    case Some{Text{t}}:
      t
    case Some{Num{n}}:
      default
    case Some{Flag{b}}:
      default
    case None{}:
      default

def option_text(opts: List<&2, Option>, key: String, default: String) -> String:
  option_text_or(find(opts, key), default)

def serve(run: Input -> IO(List<&2, Diag>)) -> IO(Unit):
  IO.bind(Input, Unit, input(), i => IO.bind(List<&2, Diag>, Unit, run(i), report))
