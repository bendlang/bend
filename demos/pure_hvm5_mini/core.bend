# HVM5 in Bend -- the core: what the laws are about, apart from the
# parser and the evaluator in main.bend, which are @unsafe (a parse
# phase is not a smaller argument, and a normalization need not end).
# Here: the runtime terms, the lexer and the parser's cursor, run
# words, name codes, the printer and the book's depth. LAWS.bend
# imports this file alone, so PROOF.bend checks without main.bend.

import Base

# Types
# =====

# Term: a runtime term. Abs and Nam appear in normal forms only: a
# lambda shown with its display name.
type Term is Data:
  Var{i: U32}
  Co0{+l: U32, i: U32}
  Co1{+l: U32, i: U32}
  Era{}
  Sup{+l: U32, a: Term, b: Term}
  Lam{+i: U32, f: Term}
  Drp{f: Term}
  Cal{f: Term, x: Term}
  One{}
  Use{f: Term}
  Pak{+p: U32, t: Term}
  Won{+p: U32}
  Tup{a: Term, b: Term}
  Get{f: Term}
  Mat{f: Term, g: Term}
  Ref{+n: U32}
  Abs{+n: U32, f: Term}
  Nam{+n: U32}

# Ws: the source head as whitespace: a blank, a comment, or neither.
type Ws is Data:
  Sp{}
  Cm{}
  No{}

# Constants
# =========

# the display-name alphabet, hvm5.c's: a name code is base 64 over it
def alphabet() -> String:
  "_abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789$"

# "λ" as the two bytes the output writes: the one place a code stands
# for a character, since a Char literal is the code point (955) and
# IO.print writes one byte per Char
def lam() -> String:
  SCon{Chr{206}, SCon{Chr{187}, ""}}

# Pick
# ====

def pick(-A: Type, z: Bool, a: A, b: A) -> A:
  match z:
    case True{}:
      a
    case False{}:
      b

# Chr
# ===

def chr_code(ch: Char) -> U32:
  Chr{x} = ch
  x

# is code c the character ch
def chr_is(c: U32, ch: Char) -> Bool:
  U32.is_eq(c, chr_code(ch))

# Str
# ===

# the code at position n (0 past the end)
def str_at(s: String, n: Nat) -> U32:
  match s n:
    case SCon{Chr{c}, t} 0n:
      c
    case SCon{h, t} 1n+p:
      str_at(t, p)
    case SNil{} _:
      0

# the string past n characters
def str_drop(s: String, n: Nat) -> String:
  match s n:
    case SCon{h, t} 1n+p:
      str_drop(t, p)
    case u _:
      u

# the position of code c in s, or the length of s; z: is the head c
def str_find(s: String, z: Bool, +c: U32, +i: U32) -> U32:
  match s z:
    case _ True{}:
      i
    case SCon{h, +t} False{}:
      str_find(t, U32.is_eq(str_at(t, 0n), c), c, (i + 1 : U32))
    case SNil{} False{}:
      i

# the digit of code c in the alphabet; 64 when it is not a digit
def alpha(+c: U32) -> U32:
  +a = alphabet()
  str_find(a, U32.is_eq(str_at(a, 0n), c), c, 0)

# a name character: a digit, or "-" so a dead dup side reads as a name
def chr_name(+c: U32) -> Bool:
  U32.is_lt(alpha(c), 64) || chr_is(c, '-')

# a name's code: six bits per character, first character highest
def name_code(s: String, +acc: U32) -> U32:
  match s:
    case SCon{Chr{c}, t}:
      name_code(t, ((acc << 6n : U32) + alpha(c) : U32))
    case SNil{}:
      acc

def ws_new(sp: Bool, cm: Bool) -> Ws:
  match sp cm:
    case True{} _:
      Sp{}
    case _ True{}:
      Cm{}
    case _ _:
      No{}

# the source head as whitespace: a blank or "~", or "//"
def str_ws(s: String) -> Ws:
  match s:
    case SCon{Chr{+c}, t}:
      ws_new(U32.is_le(c, chr_code(' ')) || chr_is(c, '~'),
        chr_is(c, '/') && chr_is(str_at(t, 0n), '/'))
    case SNil{}:
      No{}

# the source head inside a comment: a newline ends it
def str_cm(s: String) -> Ws:
  match s:
    case SCon{Chr{c}, t}:
      +nl = chr_is(c, '\n')
      ws_new(nl, Bool.not(nl))
    case SNil{}:
      No{}

# blanks and comments dropped from the head; z classifies the head
def str_skip(s: String, z: Ws) -> String:
  match s z:
    case SCon{c, +t} Sp{}:
      str_skip(t, str_ws(t))
    case SCon{c, +t} Cm{}:
      str_skip(t, str_cm(t))
    case u _:
      u

def str_word.go(c: Char, p: String & String) -> String & String:
  (w, u) = p
  (SCon{c, w}, u)

# the word at the head, and the rest; z: is the head a name character
def str_word(s: String, z: Bool) -> String & String:
  match s z:
    case SCon{c, +t} True{}:
      str_word.go(c, str_word(t, chr_name(str_at(t, 0n))))
    case u _:
      ("", u)

# Spec
# ====
# What LAWS.bend measures: the word and the rest re-joined (the lexer
# loses nothing), and the "{" of a string (the printer's braces).

def word_cat(p: String & String) -> String:
  (w, u) = p
  w ++ u

def opens.go(brace: Bool, n: Nat) -> Nat:
  match brace:
    case True{}:
      1n+n
    case False{}:
      n

# how many "{" a string holds
def opens(s: String) -> Nat:
  match s:
    case SNil{}:
      0n
    case SCon{Chr{c}, t}:
      opens.go(chr_is(c, '{'), opens(t))

# Run words
# =========

# a run word: n bits, w their values (outermost lowest)
def run_word(+n: U32, +w: U32) -> U32:
  ((n << 24n) .|. w : U32)

# bit b pushed outermost onto the run word p
def run_push(+p: U32, +b: U32) -> U32:
  run_word(((p >> 24n) + 1 : U32), (((p .&. 16777215) << 1n) .|. b : U32))

# the run word without its outermost bit
def run_pop(+p: U32) -> U32:
  ((((p >> 24n) - 1) << 24n) .|. ((p .&. 16777215) >> 1n) : U32)

def bit0(+p: U32) -> Bool:
  U32.is_eq((p .&. 1 : U32), 0)

# Show
# ====

# one display-name digit
def nam_digit(d: U32) -> String:
  SCon{Chr{str_at(alphabet(), U32.to_nat(d))}, ""}

# a name: base-64 digits, most significant first (print_name); one: n
# is a single digit; d bounds the digits
def nam_show(d: Nat, one: Bool, +n: U32) -> String:
  match d one:
    case 0n _:
      ""
    case 1n+p True{}:
      nam_digit(n)
    case 1n+p False{}:
      +h = (n >> 6n : U32)
      nam_show(p, U32.is_lt(h, 64), h) ++ nam_digit(U32.and(n, 63))

# a name from its code
def nam(+n: U32) -> String:
  nam_show(6n, U32.is_lt(n, 64), n)

# the constructors a run word opens, outermost first; n: bits left
def bits_open(n: Nat, +w: U32) -> String:
  match n:
    case 0n:
      ""
    case 1n+p:
      "#" ++ pick(String, bit0(w), "0", "1") ++ "{" ++ bits_open(p, (w >> 1n : U32))

def bits_close(n: Nat) -> String:
  match n:
    case 0n:
      ""
    case 1n+p:
      "}" ++ bits_close(p)

def run_len(+p: U32) -> Nat:
  U32.to_nat((p >> 24n : U32))

def term_show(t: Term) -> String:
  match t:
    case Nam{n}:
      nam(n)
    case Abs{n, f}:
      lam() ++ nam(n) ++ "." ++ term_show(f)
    case Lam{i, f}:
      lam() ++ nam(i) ++ "." ++ term_show(f)
    case Drp{f}:
      lam() ++ "- " ++ term_show(f)
    case Use{f}:
      lam() ++ "() " ++ term_show(f)
    case Get{f}:
      lam() ++ "! " ++ term_show(f)
    case Mat{f, g}:
      lam() ++ "{#0:" ++ term_show(f) ++ "; #1:" ++ term_show(g) ++ "}"
    case Era{}:
      "&{}"
    case One{}:
      "()"
    case Sup{l, a, b}:
      "&" ++ nam(l) ++ "{" ++ term_show(a) ++ "," ++ term_show(b) ++ "}"
    case Tup{a, b}:
      "#(" ++ term_show(a) ++ "," ++ term_show(b) ++ ")"
    case Pak{p, x}:
      bits_open(run_len(p), p) ++ term_show(x) ++ bits_close(run_len(p))
    case Won{p}:
      bits_open(run_len(p), p) ++ "()" ++ bits_close(run_len(p))
    case Cal{f, x}:
      "(" ++ term_show(f) ++ " " ++ term_show(x) ++ ")"
    case u:
      "<var>"

# Book
# ====

# the depth of an array with room for n entries; f: the bits left to try
def book_depth(f: Nat, +n: U32, +d: Nat) -> Nat:
  match f:
    case 0n:
      d
    case 1n+p:
      pick(Nat, U32.is_le(n, (1 << d : U32)), d, book_depth(p, n, 1n+d))
