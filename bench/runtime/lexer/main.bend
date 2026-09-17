import Base
# Lexer: a tokenizer over generated source text, the suite's String
# stress case. Bend's String is a cons list, one node per character,
# so the lexer walks a linked list where C walks bytes; that gap is
# the point, and the program is spelled the natural way anyway.
# 2^size lines fork as a balanced batch tree. Leaf i hashes its index
# into a seed and expands the template
# "i = ( n o i ) o ( n o i ) o ( n o i ) ;" into one line of source:
# i becomes an identifier of 1-8 random lowercase letters, n a number
# of 1-6 random decimal digits, o one of + - * /, and any other
# template character copies itself; placeholder k draws from an
# xorshift stream salted by the seed and k, so the tail of the line
# is built first and each expansion is consed in front of it. The
# lexer then walks the line character by character as a three-mode
# machine (between tokens, inside an identifier, inside a number) and
# folds every token into the line checksum in order, acc = acc *
# 2654435761 ^ (kind * 40503 + payload): an identifier is kind 1 with
# the FNV-1a hash of its letters, a number kind 2 with its decimal
# value (wrapping), an operator or punctuation character kind 3 with
# its code; spaces are skipped. Line checksums sum up the fork tree.
# A template or source character is classified by comparisons on its
# code (there is no match on a word); a helper decides on the class.
#
# Sizes: small size = 8n (expect 1822208108), big size = 23n (expect
# 2401049475); both verified against the C twin.

type Slot is Data:
  Id{}
  Nm{}
  Op{}
  Lit{}

type Cls is Data:
  Letter{}
  Digit{}
  Space{}
  Punct{}

type Mode is Data:
  Gap{}
  InId{h: U32}
  InNm{v: U32}

# xorshift: x ^= x<<13; x ^= x>>17; x ^= x<<5
def prng(+x: U32) -> U32:
  +b = U32.xor(x, U32.shln(x, 13n))
  +d = U32.xor(b, U32.shrn(b, 17n))
  U32.xor(d, U32.shln(d, 5n))

# line seed: hash of the line index
def seed(i: U32) -> U32:
  prng(((i + 1) * 2654435761 : U32))

# placeholder seed: the line seed salted by the template position
def salt(s: U32, k: U32) -> U32:
  prng(U32.xor(s, (k * 2654435761 : U32)))

# the operator: + - * / by the two low bits of the seed
def op.pick(b1: Bool, b0: Bool) -> Char:
  match b1 b0:
    case False{} False{}:
      '+'
    case False{} True{}:
      '-'
    case True{} False{}:
      '*'
    case True{} True{}:
      '/'

def op(+t: U32, rest: String) -> String:
  SCon{op.pick(U32.is_ne(U32.and(t, 2), 0), U32.is_ne(U32.and(t, 1), 0)), rest}

# an identifier: n random lowercase letters, one prng step each
def ident(n: Nat, t: U32, rest: String) -> String:
  match n:
    case 0n:
      rest
    case 1n+p:
      +u = prng(t)
      SCon{Chr{(97 + u % 26 : U32)}, ident(p, u, rest)}

# a number: n random decimal digits, one prng step each
def num(n: Nat, t: U32, rest: String) -> String:
  match n:
    case 0n:
      rest
    case 1n+p:
      +u = prng(t)
      SCon{Chr{(48 + u % 10 : U32)}, num(p, u, rest)}

# one placeholder in front of the rest of the line: an identifier of
# 1 + (t & 7) letters, a number of 1 + t % 6 digits, an operator, or
# the template character itself
def expand(sl: Slot, c: U32, +t: U32, rest: String) -> String:
  match sl:
    case Id{}:
      ident(U32.to_nat((1 + U32.and(t, 7) : U32)), t, rest)
    case Nm{}:
      num(U32.to_nat((1 + t % 6 : U32)), t, rest)
    case Op{}:
      op(t, rest)
    case Lit{}:
      SCon{Chr{c}, rest}

# the slot of a template character: i, n, o, or a literal
def slot.go(i: Bool, n: Bool, o: Bool) -> Slot:
  match i n o:
    case True{} _ _:
      Id{}
    case _ True{} _:
      Nm{}
    case _ _ True{}:
      Op{}
    case _ _ _:
      Lit{}

def slot(+c: U32) -> Slot:
  slot.go(U32.is_eq(c, 105), U32.is_eq(c, 110), U32.is_eq(c, 111))

# one template character, read twice: for its slot and as a literal
def gen.at(+c: U32, t: U32, rest: String) -> String:
  expand(slot(c), c, t, rest)

# the line: the template expanded character by character, placeholder
# k seeded by salt(s, k), each expansion consed onto the built tail
def gen(tpl: String, +s: U32, +k: U32) -> String:
  match tpl:
    case SNil{}:
      SNil{}
    case SCon{Chr{c}, u}:
      gen.at(c, salt(s, k), gen(u, s, (k + 1 : U32)))

def tpl() -> String:
  "i = ( n o i ) o ( n o i ) o ( n o i ) ;"

# the class of a source character
def cls.go(l: Bool, d: Bool, s: Bool) -> Cls:
  match l d s:
    case True{} _ _:
      Letter{}
    case _ True{} _:
      Digit{}
    case _ _ True{}:
      Space{}
    case _ _ _:
      Punct{}

def cls(+c: U32) -> Cls:
  cls.go(U32.is_le(97, c) && U32.is_le(c, 122),
    U32.is_le(48, c) && U32.is_le(c, 57), U32.is_eq(c, 32))

# one token into the line checksum
def mix(acc: U32, kind: U32, x: U32) -> U32:
  U32.xor((acc * 2654435761 : U32), (kind * 40503 + x : U32))

# FNV-1a: one letter into the identifier hash
def fnv(h: U32, c: U32) -> U32:
  (U32.xor(h, c) * 16777619 : U32)

# the machine: (mode, acc) steps over one classified character; a
# letter extends an identifier, a digit a number, and anything else
# closes the open token, then starts what the character begins
def step.at(m: Mode, k: Cls, c: U32, acc: U32) -> Mode & U32:
  match m k:
    case Gap{} Letter{}:
      (InId{fnv(2166136261, c)}, acc)
    case Gap{} Digit{}:
      (InNm{(c - 48 : U32)}, acc)
    case Gap{} Space{}:
      (Gap{}, acc)
    case Gap{} Punct{}:
      (Gap{}, mix(acc, 3, c))
    case InId{h} Letter{}:
      (InId{fnv(h, c)}, acc)
    case InId{h} Digit{}:
      (InNm{(c - 48 : U32)}, mix(acc, 1, h))
    case InId{h} Space{}:
      (Gap{}, mix(acc, 1, h))
    case InId{h} Punct{}:
      (Gap{}, mix(mix(acc, 1, h), 3, c))
    case InNm{v} Letter{}:
      (InId{fnv(2166136261, c)}, mix(acc, 2, v))
    case InNm{v} Digit{}:
      (InNm{(v * 10 + (c - 48) : U32)}, acc)
    case InNm{v} Space{}:
      (Gap{}, mix(acc, 2, v))
    case InNm{v} Punct{}:
      (Gap{}, mix(mix(acc, 2, v), 3, c))

def step(m: Mode, +c: U32, acc: U32) -> Mode & U32:
  step.at(m, cls(c), c, acc)

# end of line: close the open token
def flush(m: Mode, acc: U32) -> U32:
  match m:
    case Gap{}:
      acc
    case InId{h}:
      mix(acc, 1, h)
    case InNm{v}:
      mix(acc, 2, v)

# the lexer: one step per character, (mode, acc) riding as r
def lex(s: String, r: Mode & U32) -> U32:
  match s:
    case SNil{}:
      (m, acc) = r
      flush(m, acc)
    case SCon{Chr{c}, t}:
      (m, acc) = r
      lex(t, step(m, c, acc))

# one line: generate it, then lex it
def line(i: U32) -> U32:
  lex(gen(tpl(), seed(i), 0), (Gap{}, 0))

# batch tree over the line index space; line checksums sum
def batch(+d: Nat, +i: U32) -> U32:
  match d:
    case 0n:
      line(i)
    case 1n+p:
      a b = batch(p, i) batch(p, (i + U32.shln(1, p) : U32))
      (a + b : U32)

def size.small() -> Nat:
  8n

def expect.small() -> U32:
  1822208108

def size.big() -> Nat:
  23n

def expect.big() -> U32:
  2401049475

def main() -> IO(Unit):
  IO.print(U32.show(batch!(size.big(), 0)))
