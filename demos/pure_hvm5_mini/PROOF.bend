# HVM5 in Bend -- the proofs. This file imports the interpreter (as
# Hvm) and the claims (as Laws) and fills every law. word_joins is an
# induction over the source: a name character is put back by go_cat
# (the head over the re-joined rest) and the rest is the induction
# hypothesis. skip_is_drop builds its witness by induction: a skipped
# head adds one to the rest's witness (skip_step), a kept head or an
# empty source gives 0. pak_braces splits the display with opens_cat
# (a count over an append is the sum), counts the open braces of the
# run (bits_open_opens, an induction over the run's length with the
# bit's digit split by pick_opens) and the none of its closing
# braces (bits_close_opens). The cursor laws are inductions over the
# source and the position; the closed laws compute.

import Base
import ./main.bend as Hvm
import ./LAWS.bend as Laws

# The lexer
# ---------

# the head put back over the re-joined rest
law go_cat:
  for c: Char
  for p: String & String
  {SCon{c, Hvm.word_cat(p)} == Hvm.word_cat(Hvm.str_word.go(c, p)) : String}

def go_cat(c, p):
  (w, u) = p
  {==}

def Laws.word_joins(s, z):
  match s z:
    case SCon{c, +t} True{}:
      %go_cat(c, Hvm.str_word(t, Hvm.chr_name(Hvm.str_at(t, 0n))))
        : {_ == SCon{c, t} : String}
      %Laws.word_joins(t, Hvm.chr_name(Hvm.str_at(t, 0n)))
        : {SCon{c, Hvm.word_cat(Hvm.str_word(t, Hvm.chr_name(Hvm.str_at(t, 0n))))}
           == SCon{c, _} : String}
      {==}
    case SCon{c, t} False{}:
      {==}
    case SNil{} _:
      {==}

# a skipped head: the cursor moves one more than the rest's witness
law skip_step:
  for c: Char
  for -t: String
  for -y: Hvm.Ws
  for w: &n: Nat -> {Hvm.str_skip(t, y) == Hvm.str_drop(t, n) : String}
  exs n: Nat
  {Hvm.str_skip(t, y) == Hvm.str_drop(SCon{c, t}, n) : String}

def skip_step(c, t, y, w):
  (n, e) = w
  (1n+n, e)

def Laws.skip_is_drop(s, z):
  match s z:
    case SCon{c, +t} Hvm.Sp{}:
      skip_step(c, t, Hvm.str_ws(t), Laws.skip_is_drop(t, Hvm.str_ws(t)))
    case SCon{c, +t} Hvm.Cm{}:
      skip_step(c, t, Hvm.str_cm(t), Laws.skip_is_drop(t, Hvm.str_cm(t)))
    case SCon{c, t} Hvm.No{}:
      (0n, {==})
    case SNil{} _:
      (0n, {==})

# The printer
# -----------

law go_add:
  for brace: Bool
  for -x: Nat
  for -y: Nat
  {Nat.add(Hvm.opens.go(brace, x), y) == Hvm.opens.go(brace, Nat.add(x, y)) : Nat}

def go_add(brace, x, y):
  match brace:
    case True{}:
      {==}
    case False{}:
      {==}

# the braces of an append are the sum of the braces
law opens_cat:
  for a: String
  for -b: String
  {Nat.add(Hvm.opens(a), Hvm.opens(b)) == Hvm.opens(a ++ b) : Nat}

def opens_cat(a, b):
  match a:
    case SNil{}:
      {==}
    case SCon{Chr{c}, t}:
      %opens_cat(t, b)
        : {Nat.add(Hvm.opens.go(Hvm.chr_is(c, '{'), Hvm.opens(t)), Hvm.opens(b))
           == Hvm.opens.go(Hvm.chr_is(c, '{'), _) : Nat}
      go_add(Hvm.chr_is(c, '{'), Hvm.opens(t), Hvm.opens(b))

# a bit's digit, then "{": one brace more than the rest, for either bit
law pick_opens:
  for b: Bool
  for -r: String
  {1n+Hvm.opens(r) == Hvm.opens(Hvm.pick(String, b, "0", "1") ++ ("{" ++ r)) : Nat}

def pick_opens(b, r):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

# a run of n constructors opens n braces
law bits_open_opens:
  for n: Nat
  for +w: U32
  {n == Hvm.opens(Hvm.bits_open(n, w)) : Nat}

def bits_open_opens(n, w):
  match n:
    case 0n:
      {==}
    case 1n+p:
      %pick_opens(Hvm.bit0(w), Hvm.bits_open(p, (w >> 1n : U32)))
        : {1n+p == _ : Nat}
      %bits_open_opens(p, (w >> 1n : U32)) : {1n+p == 1n+_ : Nat}
      {==}

# the closing braces open none
law bits_close_opens:
  for n: Nat
  {0n == Hvm.opens(Hvm.bits_close(n)) : Nat}

def bits_close_opens(n):
  match n:
    case 0n:
      {==}
    case 1n+p:
      bits_close_opens(p)

law add_zero:
  for x: Nat
  {x == Nat.add(x, 0n) : Nat}

def add_zero(x):
  match x:
    case 0n:
      {==}
    case 1n+p:
      %add_zero(p) : {1n+p == 1n+_ : Nat}
      {==}

def Laws.pak_braces(p, x):
  %opens_cat(Hvm.bits_open(Hvm.run_len(p), p),
      Hvm.term_show(x) ++ Hvm.bits_close(Hvm.run_len(p)))
    : {Nat.add(Hvm.run_len(p), Hvm.opens(Hvm.term_show(x))) == _ : Nat}
  %opens_cat(Hvm.term_show(x), Hvm.bits_close(Hvm.run_len(p)))
    : {Nat.add(Hvm.run_len(p), Hvm.opens(Hvm.term_show(x)))
       == Nat.add(Hvm.opens(Hvm.bits_open(Hvm.run_len(p), p)), _) : Nat}
  %bits_open_opens(Hvm.run_len(p), p)
    : {Nat.add(Hvm.run_len(p), Hvm.opens(Hvm.term_show(x)))
       == Nat.add(_, Nat.add(Hvm.opens(Hvm.term_show(x)),
            Hvm.opens(Hvm.bits_close(Hvm.run_len(p))))) : Nat}
  %bits_close_opens(Hvm.run_len(p))
    : {Nat.add(Hvm.run_len(p), Hvm.opens(Hvm.term_show(x)))
       == Nat.add(Hvm.run_len(p), Nat.add(Hvm.opens(Hvm.term_show(x)), _)) : Nat}
  %add_zero(Hvm.opens(Hvm.term_show(x)))
    : {Nat.add(Hvm.run_len(p), Hvm.opens(Hvm.term_show(x)))
       == Nat.add(Hvm.run_len(p), _) : Nat}
  {==}

# The cursor
# ----------

def Laws.drop_drop(s, m, n):
  match s m:
    case SNil{} 0n:
      {==}
    case SNil{} 1n+p:
      {==}
    case SCon{h, t} 0n:
      {==}
    case SCon{h, t} 1n+p:
      Laws.drop_drop(t, p, n)

def Laws.at_drop(s, n, k):
  match s n:
    case SNil{} 0n:
      {==}
    case SNil{} 1n+p:
      {==}
    case SCon{Chr{c}, t} 0n:
      {==}
    case SCon{Chr{c}, t} 1n+p:
      Laws.at_drop(t, p, k)

# Sanity
# ------

def Laws.run_push_pop(b):
  match b:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.name_round_trip():
  {==}

def Laws.book_depth_fits():
  {==}
