# HVM5 in Bend
# ============
#
# A port of hvm5.c: an Interaction Calculus evaluator with the same
# syntax, semantics and interaction counting as the C reference.
#
#   Term ::=
#     | x                  variable
#     | &{}                eraser
#     | &L{a,b}            superposition
#     | ! &L{a,b} = v; k   duplication
#     | λx.f               lambda
#     | λ- f               drop lambda
#     | (f x)              application
#     | ()                 unit
#     | λ() f              unit eliminator
#     | #0{x}              left constructor
#     | #1{x}              right constructor
#     | λ{#0:f; #1:g}      constructor eliminator
#     | #(a,b)             pair
#     | λ! f               pair eliminator
#     | @ref               reference
#     | @ref(a,b,..)       reference applied to arguments
#
# Terms are Bend constructors, so term memory is Bend's own: erasing a
# term is dropping it. A run of #0/#1 is one word: 24 bits and their
# count, outermost bit lowest, as hvm5.c packs them; a run over () is
# the word alone (Won), so a bit chain costs no heap at all.
#
# The env is an Array of cells indexed by binder id. A lambda's cell
# holds its argument (Sub) once applied; a dup's cell holds the value
# until a side asks (Sha, or Haf when the other side is dead), then
# the twin's copy. A cell read by its variable goes to the free list:
# the cell stores the old head (Num), and the words fh and nx (the
# head, the next fresh id) ride the loop. A dropped term is walked so
# its cells follow (hvm5.c's collect): an erased argument, a loser
# branch, a dead dup side's copy. The book is an Array of templates
# (Tpl, the parser's output) by definition index, the parser numbering
# names and binders as it meets them. A reference moves its template
# out of the book, copies it in place and writes it back: the copier
# (inst) only reads the template, so the compiler lends it and no node
# is rebuilt. A binder's cell hands its occurrence to the copy and a
# fresh cell takes the binder. Under fusion, hvm5.c's L_RF0 loop, the
# copier runs the head of the template against the pending arguments
# instead of copying it: a lambda or a drop takes an argument, a unit
# or pair eliminator takes a unit or a pair, a constructor eliminator
# takes a bit and goes on with the branch it selects, an application
# pushes its argument's copy; a root eliminator meeting an argument
# that is no bit waits for its whnf (K_DISP). Only what the arguments
# cannot decide gets copied.
#
# The evaluator is one loop over the env, the book, a mode, a stack
# and the registers. The mode is a term to evaluate (Go), a whnf to
# deliver to the top frame (Kn) or a stuck term unwinding the stack
# (Sk: hvm5.c dies here). The stack is hvm5.c's: a pending argument,
# an eliminator waiting for its scrutinee, a dup cell waiting for its
# value, a deferred @ref. Strong normalization runs in the same loop:
# an NfK frame normalizes the children of the whnf it receives, and a
# frame per node shape rebuilds it. Every helper answers the next
# state; the loop matches the mode and the top frame.
#
# The parser is a continuation monad over the parser state, in
# do-notation: a primitive is a def over the continuation and the
# state. An error prints and stops: nothing after it runs. A form that
# looks ahead before it reads more terms resumes as a phase (Ph) of
# term, the one recursive parser.
#
# Names and labels are codes, as in hvm5.c: six bits per character of
# the display alphabet, first character highest. The program to run
# is the src constant, since a Bend binary takes no arguments; the
# output is hvm5 -s's. A literal holds λ as one code point (955); the
# output writes it as its two UTF-8 bytes.

import Base

# Types
# =====

# Tpl: a template, the parser's output: the syntax with its binders
# as ids. Dup/Dux (both sides live, one side live) exist here only: a
# copy turns them into a cell.
type Tpl is Data:
  TVar{+i: U32}
  TCo0{+l: U32, +i: U32}
  TCo1{+l: U32, +i: U32}
  TEra{}
  TSup{+l: U32, a: Tpl, b: Tpl}
  TDup{+a: U32, +b: U32, v: Tpl, k: Tpl}
  TDux{+a: U32, v: Tpl, k: Tpl}
  TLam{+i: U32, f: Tpl}
  TDrp{f: Tpl}
  TApp{f: Tpl, x: Tpl}
  TOne{}
  TUse{f: Tpl}
  TPak{+p: U32, t: Tpl}
  TWon{+p: U32}
  TTup{a: Tpl, b: Tpl}
  TGet{f: Tpl}
  TMat{f: Tpl, g: Tpl}
  TRef{+n: U32}

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

# Cell: an env slot: a substitution, a dup value not yet copied (both
# sides live, or the twin dead), a free-list link, nothing, a dup
# side dropped while its value is under evaluation.
type Cell is Data:
  Sub{t: Term}
  Sha{v: Term}
  Haf{v: Term}
  Num{+n: U32}
  Nul{}
  Ded{}

# Sh1, Sh2: the shape of a node with one child, with two: what a dup
# copies, an eliminator a sup splits, or inst builds over the copied
# children.
type Sh1 is Data:
  SUse{}
  SGet{}
  SDrp{}
  SLam{+n: U32}
  SPak{+p: U32}

type Sh2 is Data:
  STup{}
  SMat{}
  SApp{}
  SSup{+l: U32}

# Kont: the stack. Arg: a pending argument. Usk, Mtk, Gtk: an
# eliminator waiting for its scrutinee. Dpk: dup cell i (label l)
# waiting for its value, side sd asking, fl: is the twin alive. Rfk:
# a deferred eliminator @ref. NfK: the whnf arriving gets normalized
# deeper. The N-frames rebuild a node from its normalized children.
type Kont is Data:
  Arg{x: Term, k: Kont}
  Usk{f: Term, k: Kont}
  Mtk{f: Term, g: Term, k: Kont}
  Gtk{f: Term, k: Kont}
  Dpk{+l: U32, +i: U32, +sd: U32, +fl: U32, k: Kont}
  Rfk{+r: U32, k: Kont}
  NfK{k: Kont}
  NSupA{+l: U32, b: Term, k: Kont}
  NSupB{+l: U32, a: Term, k: Kont}
  NTupA{b: Term, k: Kont}
  NTupB{a: Term, k: Kont}
  NMatA{g: Term, k: Kont}
  NMatB{f: Term, k: Kont}
  NPak{+p: U32, k: Kont}
  NUse{k: Kont}
  NGet{k: Kont}
  NDrp{k: Kont}
  NAbs{+n: U32, k: Kont}
  End{}

# Mode: a term to evaluate, a whnf to deliver, a stuck term unwinding
# the stack.
type Mode is Data:
  Go{t: Term}
  Kn{w: Term}
  Sk{w: Term}

# S: the machine: the env, the book, the mode, the stack, the
# interaction count, the free-list head, the next fresh id.
type S is Type:
  S{env: Array<Cell>, book: Array<Tpl>, m: Mode, k: Kont, +c: U32, +fh: U32, +nx: U32}

# Out: what the loop answers: the normal form and the interaction
# count, or a request to its driver: expand definition r, or resolve
# a deferred eliminator @r with the whnf w of its scrutinee (K_DISP).
type Out is Type:
  Fin{env: Array<Cell>, book: Array<Tpl>, t: Term, +c: U32}
  Exp{env: Array<Cell>, book: Array<Tpl>, k: Kont, +c: U32, +fh: U32, +nx: U32, +r: U32}
  Dsp{env: Array<Cell>, book: Array<Tpl>, k: Kont, +c: U32, +fh: U32, +nx: U32, +r: U32, w: Term}

# FK: the frames of a collect walk: the sibling still to free. FS: the
# walk's state; Fr: its answer, the env and the free-list head.
type FK is Data:
  FEnd{}
  FNxt{t: Term, k: FK}

type FS is Type:
  FS{env: Array<Cell>, t: Term, k: FK, +fh: U32}

type Fr is Type:
  Fr{env: Array<Cell>, +fh: U32}

# Al: fresh cells taken: the env, their ids, the allocator words.
type Al is Type:
  Al{env: Array<Cell>, +n: U32, +fh: U32, +nx: U32}

type Al2 is Type:
  Al2{env: Array<Cell>, +n: U32, +p: U32, +fh: U32, +nx: U32}

type Al3 is Type:
  Al3{env: Array<Cell>, +n: U32, +p: U32, +r: U32, +fh: U32, +nx: U32}

# Fz: whether a copy fuses leading binders with pending arguments:
# at the root of a reference (a Mat root defers instead), under its
# fused binders, or not at all.
type Fz is Data:
  FRoot{+r: U32}
  FLam{}
  FOff{}

# Ins: a copy: the env, the instance, the stack, the interaction
# count, the allocator words.
type Ins is Type:
  Ins{env: Array<Cell>, t: Term, k: Kont, +c: U32, +fh: U32, +nx: U32}

# IM: the copier's phase over the template node in hand and its
# sibling: copy it; copy it under a one-child shape; copy it and its
# sibling under a two-child shape; its sibling, the left copy done;
# copy it under a fresh binder cell; copy it as a dup's value and take
# a cell, then its body; copy it once a dropped argument is freed;
# done (a deferred root).
type IM is Type:
  IGo{env: Array<Cell>, +fh: U32, +nx: U32, fz: Fz, k: Kont, +c: U32}
  IUn{sh: Sh1, env: Array<Cell>, +fh: U32, +nx: U32, k: Kont, +c: U32}
  ITw{sh: Sh2, env: Array<Cell>, +fh: U32, +nx: U32, k: Kont, +c: U32}
  ILt{sh: Sh2, r: Ins}
  IAl{al: Al, +i: U32, k: Kont, +c: U32}
  IDv{+a: U32, +b: U32, env: Array<Cell>, +fh: U32, +nx: U32, k: Kont, +c: U32}
  IDq{+a: U32, +b: U32, r: Ins}
  IXv{+a: U32, env: Array<Cell>, +fh: U32, +nx: U32, k: Kont, +c: U32}
  IXq{+a: U32, r: Ins}
  IFr{fr: Fr, +nx: U32, k: Kont, +c: U32}
  IGr{env: Array<Cell>, +fh: U32, +nx: U32, k: Kont, +c: U32}
  IAg{env: Array<Cell>, +fh: U32, +nx: U32, k: Kont, +c: U32}
  IAr{r: Ins}
  IEnd{ins: Ins}

# Hc: the syntax form the first two characters of the source open;
# HCtr{b} is #0 (b false) or #1.
type Hc is Data:
  HEra{}
  HSup{}
  HDup{}
  HTup{}
  HCtr{b: Bool}
  HRef{}
  HOne{}
  HApp{}
  HMat{}
  HDrp{}
  HGet{}
  HUse{}
  HLam{}
  HOth{}

# Ws: the source head as whitespace: a blank, a comment, or neither.
type Ws is Data:
  Sp{}
  Cm{}
  No{}

# Occ: how a binder occurs: a variable, a dup side (label, cell).
type Occ is Data:
  OVar{+i: U32}
  OCo0{+l: U32, +i: U32}
  OCo1{+l: U32, +i: U32}

# Bind: a scoped binder: its name, its occurrence, its use count.
type Bind is Data:
  Bind{+nm: String, +oc: Occ, +u: U32}

# Names: the definition names met so far, each with its index; the
# next index.
type Names is Data:
  Names{m: Map<&2, U32>, +n: U32}

# Ent: a parsed definition: its index and its template.
type Ent is Data:
  Ent{ix: U32, t: Tpl}

# St: the parser state: the head form, the source (blanks skipped),
# the scope, the next binder id, the names.
type St is Data:
  St{+h: Hc, src: String, sc: List<&2, Bind>, +vc: U32, ns: Names}

# Dp: a dup's sides: both dead, one live (its cell), both live.
type Dp is Data:
  Dead{}
  Half{+j: U32}
  Both{+i: U32, +j: U32}

# Ph: the parser phase: a term; a term whose head form is known; a
# reference with or without arguments; a call after "(", closed or
# not; a call after an argument, with a comma or not; a dup's body.
type Ph is Data:
  Trm{}
  PAt{h: Hc}
  PArg{op: Bool, f: Tpl}
  PCls{cl: Bool, f: Tpl}
  PSep{m: Bool, f: Tpl}
  PDup{d: Dp, v: Tpl}

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

# the program: hvm5 -s of this file prints the same
def program() -> String:
  "// Booleans are bit runs over (); @not flips one.\n" ++
  "@not = λ{#0: λ- #1{()}; #1: λ- #0{()}};\n" ++
  "// Church numeral 2: the function is shared by a dup.\n" ++
  "@two = λf. ! &F{f0, f1} = f; λx. (f0 (f1 x));\n" ++
  "// 2^2 flips of a bit, applied to both bits at once.\n" ++
  "@main = ! &A{f, g} = @two(@two(@not)); &S{(f #0{()}), (g #1{()})};\n"

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

# Hc
# ==

def hc_hash(+d: U32) -> Hc:
  pick(Hc, chr_is(d, '('), HTup{}, HCtr{chr_is(d, '1')})

def hc_lam(+d: U32) -> Hc:
  pick(Hc, chr_is(d, '{'), HMat{},
  pick(Hc, chr_is(d, '-'), HDrp{},
  pick(Hc, chr_is(d, '!'), HGet{},
  pick(Hc, chr_is(d, '('), HUse{}, HLam{}))))

# the form opened by the two characters c, d
def hc_new(+c: U32, +d: U32) -> Hc:
  pick(Hc, chr_is(c, '&'), pick(Hc, chr_is(d, '{'), HEra{}, HSup{}),
  pick(Hc, chr_is(c, '!'), HDup{},
  pick(Hc, chr_is(c, '#'), hc_hash(d),
  pick(Hc, chr_is(c, '@'), HRef{},
  pick(Hc, chr_is(c, '('), pick(Hc, chr_is(d, ')'), HOne{}, HApp{}),
  pick(Hc, chr_is(c, 'λ'), hc_lam(d), HOth{}))))))

# St
# ==

# a state over a source: blanks skipped, the head classified
def st_new(+src: String, sc: List<&2, Bind>, vc: U32, ns: Names) -> St:
  +s = str_skip(src, str_ws(src))
  St{hc_new(str_at(s, 0n), str_at(s, 1n)), s, sc, vc, ns}

# Parser monad
# ============

# a parser of an A: it takes the continuation and the state; the last
# continuation runs the program
def P(-A: Type) -> Type:
  (A -> St -> IO(Unit)) -> St -> IO(Unit)

def P.pure(-A: Type, x: A) -> P(A):
  k => s => k(x, s)

def P.bind(-A: Type, -B: Type, m: P(A), f: A -> P(B)) -> P(B):
  k => s => m(a => f(a)(k), s)

# an error: it prints, and nothing after it runs
def fail(-A: Type, msg: String) -> P(A):
  k => s => IO.print(msg)

# the form at the head
def peek(k: Hc -> St -> IO(Unit), s: St) -> IO(Unit):
  St{h, src, sc, vc, ns} = s
  k(h, St{h, src, sc, vc, ns})

# n characters consumed
def drop(n: Nat, k: Unit -> St -> IO(Unit), s: St) -> IO(Unit):
  St{h, src, sc, vc, ns} = s
  k(Unit{}, st_new(str_drop(src, n), sc, vc, ns))

def name.go(
  sc: List<&2, Bind>,
  vc: U32,
  ns: Names,
  k: String -> St -> IO(Unit),
  p: String & String
) -> IO(Unit):
  (w, u) = p
  k(w, st_new(u, sc, vc, ns))

# the name at the head
def name(k: String -> St -> IO(Unit), s: St) -> IO(Unit):
  St{h, +src, sc, vc, ns} = s
  name.go(sc, vc, ns, k, str_word(src, chr_name(str_at(src, 0n))))

# the name at the head, as a code
def label() -> P(U32):
  do P<U32>:
    w : String <- name
    return name_code(w, 0)

def opt.go(hit: Bool, k: Bool -> St -> IO(Unit), s: St, t: String) -> IO(Unit):
  match hit:
    case True{}:
      St{h, src, sc, vc, ns} = s
      k(True{}, st_new(t, sc, vc, ns))
    case False{}:
      k(False{}, s)

# an optional character: consumed when present; the answer says which
def opt(ch: Char, k: Bool -> St -> IO(Unit), s: St) -> IO(Unit):
  St{h, +src, sc, vc, ns} = s
  opt.go(chr_is(str_at(src, 0n), ch), k, St{h, src, sc, vc, ns}, str_drop(src, 1n))

# an optional character, consumed when present
def skip(ch: Char) -> P(Unit):
  do P<Unit>:
    hit : Bool <- opt(ch)
    return Unit{}

def sym.go(hit: Bool, ch: Char) -> P(Unit):
  match hit:
    case True{}:
      P.pure(Unit, Unit{})
    case False{}:
      fail(Unit, "parse error: expected '" ++ SCon{ch, "'"})

# a required character
def sym(+ch: Char) -> P(Unit):
  do P<Unit>:
    hit : Bool <- opt(ch)
    sym.go(hit, ch)

# the closing brace of a form that opened one
def close(br: Bool) -> P(Unit):
  match br:
    case True{}:
      sym('}')
    case False{}:
      P.pure(Unit, Unit{})

# a variable binder pushed onto the scope: its id
def bindv(x: String, k: U32 -> St -> IO(Unit), s: St) -> IO(Unit):
  St{h, src, sc, vc, ns} = s
  k(vc, St{h, src, Bind{x, OVar{vc}, 0} <> sc, (vc + 1 : U32), ns})

def bindc.go(
  da: Bool,
  db: Bool,
  +l: U32,
  a: String,
  b: String,
  k: Dp -> St -> IO(Unit),
  s: St
) -> IO(Unit):
  match da db:
    case True{} True{}:
      k(Dead{}, s)
    case True{} False{}:
      St{h, src, sc, vc, ns} = s
      k(Half{vc}, St{h, src, Bind{b, OCo1{l, vc}, 0} <> sc, (vc + 1 : U32), ns})
    case False{} True{}:
      St{h, src, sc, vc, ns} = s
      k(Half{vc}, St{h, src, Bind{a, OCo0{l, vc}, 0} <> sc, (vc + 1 : U32), ns})
    case False{} False{}:
      St{h, src, sc, vc, ns} = s
      k(Both{vc, (vc + 1 : U32)}, St{h, src,
        Bind{b, OCo1{l, (vc + 1 : U32)}, 0} <> (Bind{a, OCo0{l, vc}, 0} <> sc),
        (vc + 2 : U32), ns})

# a dup's live sides pushed onto the scope ("-" is a dead side)
def bindc(l: U32, +a: String, +b: String, k: Dp -> St -> IO(Unit), s: St) -> IO(Unit):
  bindc.go(String.eq(a, "-"), String.eq(b, "-"), l, a, b, k, s)

def pop.go(ok: Bool, nm: String, u: U32) -> P(Unit):
  match ok:
    case True{}:
      P.pure(Unit, Unit{})
    case False{}:
      fail(Unit, "non-linear variable: " ++ nm ++ " used " ++ U32.show(u) ++ " times")

# the innermost binder popped: it was used once
def pop(k: Unit -> St -> IO(Unit), s: St) -> IO(Unit):
  St{h, src, sc, vc, ns} = s
  match sc:
    case Bind{nm, oc, u} <> r:
      pop.go(U32.is_eq(u, 1), nm, u)(k, St{h, src, r, vc, ns})
    case Nil{}:
      k(Unit{}, St{h, src, Nil{}, vc, ns})

def sc_find.go(+n: String, +oc: Occ, +u: U32, hit: Bool, p: List<&2, Bind> & Maybe<&2, Occ>) -> List<&2, Bind> & Maybe<&2, Occ>:
  match hit:
    case True{}:
      (r, m) = p
      (Bind{n, oc, (u + 1 : U32)} <> r, Some{oc})
    case False{}:
      (r, m) = p
      (Bind{n, oc, u} <> r, m)

# the nearest binder named nm, its use counted; done: one was found
def sc_find(sc: List<&2, Bind>, +nm: String, +done: Bool) -> List<&2, Bind> & Maybe<&2, Occ>:
  match sc:
    case Bind{n, oc, u} <> r:
      +hit = Bool.not(done) && String.eq(n, nm)
      sc_find.go(n, oc, u, hit, sc_find(r, nm, done || hit))
    case Nil{}:
      (Nil{}, None{})

# the occurrence term of a binder
def occ_term(oc: Occ) -> Tpl:
  match oc:
    case OVar{i}:
      TVar{i}
    case OCo0{l, i}:
      TCo0{l, i}
    case OCo1{l, i}:
      TCo1{l, i}

def look.go(
  nm: String,
  k: Tpl -> St -> IO(Unit),
  h: Hc,
  src: String,
  vc: U32,
  ns: Names,
  p: List<&2, Bind> & Maybe<&2, Occ>
) -> IO(Unit):
  (r, m) = p
  match m:
    case Some{oc}:
      k(occ_term(oc), St{h, src, r, vc, ns})
    case None{}:
      IO.print("unbound variable: " ++ nm)

# a variable occurrence
def look(+nm: String, k: Tpl -> St -> IO(Unit), s: St) -> IO(Unit):
  St{h, src, sc, vc, ns} = s
  look.go(nm, k, h, src, vc, ns, sc_find(sc, nm, False{}))

# is the source over
def eof(k: Bool -> St -> IO(Unit), s: St) -> IO(Unit):
  St{h, src, sc, vc, ns} = s
  match src:
    case SNil{}:
      k(True{}, St{h, SNil{}, sc, vc, ns})
    case SCon{c, t}:
      k(False{}, St{h, SCon{c, t}, sc, vc, ns})

def names_find.old(n: U32, p: Map<&2, U32> & U32) -> Names & U32:
  (m, ix) = p
  (Names{m, n}, ix)

def names_find.go(+nm: String, +n: U32, p: Map<&2, U32> & Bool) -> Names & U32:
  (m, has) = p
  match has:
    case True{}:
      names_find.old(n, Map.get(U32, 0, m, nm))
    case False{}:
      (Names{Map.set(&2, U32, m, nm, n), (n + 1 : U32)}, n)

# the index of a name: the next one when the name is new
def names_find(ns: Names, +nm: String) -> Names & U32:
  Names{m, n} = ns
  names_find.go(nm, n, Map.has(&2, U32, m, nm))

def index.go(
  k: U32 -> St -> IO(Unit),
  h: Hc,
  src: String,
  sc: List<&2, Bind>,
  vc: U32,
  p: Names & U32
) -> IO(Unit):
  (ns, ix) = p
  k(ix, St{h, src, sc, vc, ns})

# the definition index of a name
def index(w: String, k: U32 -> St -> IO(Unit), s: St) -> IO(Unit):
  St{h, src, sc, vc, ns} = s
  index.go(k, h, src, sc, vc, names_find(ns, w))

# the name at the head, as a definition index
def ref() -> P(U32):
  do P<U32>:
    w : String <- name
    index(w)

# Parser
# ======

# a run word: n bits, w their values (outermost lowest)
def run_word(+n: U32, +w: U32) -> U32:
  ((n << 24n) .|. w : U32)

# bit b pushed outermost onto the run word p
def run_push(+p: U32, +b: U32) -> U32:
  run_word(((p >> 24n) + 1 : U32), (((p .&. 16777215) << 1n) .|. b : U32))

# is the run word full (24 bits)
def run_full(+p: U32) -> Bool:
  U32.is_eq((p >> 24n : U32), 24)

def term_pak.pak(full: Bool, +b: U32, +p: U32, t: Tpl) -> Tpl:
  match full:
    case True{}:
      TPak{run_word(1, b), TPak{p, t}}
    case False{}:
      TPak{run_push(p, b), t}

def term_pak.won(full: Bool, +b: U32, +p: U32) -> Tpl:
  match full:
    case True{}:
      TPak{run_word(1, b), TWon{p}}
    case False{}:
      TWon{run_push(p, b)}

# #b{x}: the run of x grows when it has room, else a new run starts
def term_pak(b: Bool, x: Tpl) -> Tpl:
  match x:
    case TPak{p, t}:
      term_pak.pak(run_full(p), pick(U32, b, 1, 0), p, t)
    case TWon{p}:
      term_pak.won(run_full(p), pick(U32, b, 1, 0), p)
    case TOne{}:
      TWon{run_word(1, pick(U32, b, 1, 0))}
    case y:
      TPak{run_word(1, pick(U32, b, 1, 0)), y}

# a term
@unsafe
def term(ph: Ph) -> P(Tpl):
  match ph:
    case Trm{}:
      do P<Tpl>:
        h : Hc <- peek
        term(PAt{h})
    case PAt{HEra{}}:
      do P<Tpl>:
        Unit <- drop(2n)
        Unit <- sym('}')
        return TEra{}
    case PAt{HSup{}}:
      do P<Tpl>:
        Unit <- drop(1n)
        l : U32 <- label()
        Unit <- sym('{')
        a : Tpl <- term(Trm{})
        Unit <- sym(',')
        b : Tpl <- term(Trm{})
        Unit <- sym('}')
        return TSup{l, a, b}
    case PAt{HDup{}}:
      do P<Tpl>:
        Unit <- drop(1n)
        Unit <- sym('&')
        l : U32 <- label()
        Unit <- sym('{')
        a : String <- name
        Unit <- sym(',')
        b : String <- name
        Unit <- sym('}')
        Unit <- sym('=')
        v : Tpl <- term(Trm{})
        Unit <- sym(';')
        d : Dp <- bindc(l, a, b)
        term(PDup{d, v})
    case PAt{HTup{}}:
      do P<Tpl>:
        Unit <- drop(2n)
        a : Tpl <- term(Trm{})
        Unit <- sym(',')
        b : Tpl <- term(Trm{})
        Unit <- sym(')')
        return TTup{a, b}
    case PAt{HCtr{b}}:
      do P<Tpl>:
        Unit <- drop(2n)
        br : Bool <- opt('{')
        x : Tpl <- term(Trm{})
        Unit <- close(br)
        return term_pak(b, x)
    case PAt{HRef{}}:
      do P<Tpl>:
        Unit <- drop(1n)
        ix : U32 <- ref()
        op : Bool <- opt('(')
        term(PArg{op, TRef{ix}})
    case PAt{HOne{}}:
      do P<Tpl>:
        Unit <- drop(2n)
        return TOne{}
    case PAt{HApp{}}:
      do P<Tpl>:
        Unit <- drop(1n)
        f : Tpl <- term(Trm{})
        x : Tpl <- term(Trm{})
        Unit <- sym(')')
        return TApp{f, x}
    case PAt{HMat{}}:
      do P<Tpl>:
        Unit <- drop(2n)
        Unit <- sym('#')
        Unit <- sym('0')
        Unit <- sym(':')
        f : Tpl <- term(Trm{})
        Unit <- skip(';')
        Unit <- sym('#')
        Unit <- sym('1')
        Unit <- sym(':')
        g : Tpl <- term(Trm{})
        Unit <- skip(';')
        Unit <- sym('}')
        return TMat{f, g}
    case PAt{HDrp{}}:
      do P<Tpl>:
        Unit <- drop(2n)
        f : Tpl <- term(Trm{})
        return TDrp{f}
    case PAt{HGet{}}:
      do P<Tpl>:
        Unit <- drop(2n)
        f : Tpl <- term(Trm{})
        return TGet{f}
    case PAt{HUse{}}:
      do P<Tpl>:
        Unit <- drop(2n)
        Unit <- sym(')')
        f : Tpl <- term(Trm{})
        return TUse{f}
    case PAt{HLam{}}:
      do P<Tpl>:
        Unit <- drop(1n)
        x : String <- name
        Unit <- sym('.')
        i : U32 <- bindv(x)
        f : Tpl <- term(Trm{})
        Unit <- pop
        return TLam{i, f}
    case PAt{HOth{}}:
      do P<Tpl>:
        n : String <- name
        look(n)
    case PArg{False{}, f}:
      P.pure(Tpl, f)
    case PArg{True{}, f}:
      do P<Tpl>:
        cl : Bool <- opt(')')
        term(PCls{cl, f})
    case PCls{True{}, f}:
      P.pure(Tpl, f)
    case PCls{False{}, f}:
      term(PSep{True{}, f})
    case PSep{True{}, f}:
      do P<Tpl>:
        a : Tpl <- term(Trm{})
        m : Bool <- opt(',')
        term(PSep{m, TApp{f, a}})
    case PSep{False{}, f}:
      do P<Tpl>:
        Unit <- sym(')')
        return f
    case PDup{Dead{}, v}:
      do P<Tpl>:
        q : Tpl <- term(Trm{})
        return TApp{TDrp{q}, v}
    case PDup{Half{j}, v}:
      do P<Tpl>:
        q : Tpl <- term(Trm{})
        Unit <- pop
        return TDux{j, v, q}
    case PDup{Both{i, j}, v}:
      do P<Tpl>:
        q : Tpl <- term(Trm{})
        Unit <- pop
        Unit <- pop
        return TDup{i, j, v, q}

# the definitions to the end of the source; done: is the source over
@unsafe
def defs(done: Bool, es: List<&2, Ent>) -> P(List<&2, Ent>):
  match done:
    case True{}:
      P.pure(List<&2, Ent>, es)
    case False{}:
      do P<List<&2, Ent>>:
        Unit <- sym('@')
        ix : U32 <- ref()
        Unit <- sym('=')
        t : Tpl <- term(Trm{})
        Unit <- sym(';')
        e : Bool <- eof
        defs(e, Ent{ix, t} <> es)

# the definitions of the source
def prog() -> P(List<&2, Ent>):
  do P<List<&2, Ent>>:
    e : Bool <- eof
    defs(e, Nil{})

# Pak
# ===

# the run word without its outermost bit
def run_pop(+p: U32) -> U32:
  ((((p >> 24n) - 1) << 24n) .|. ((p .&. 16777215) >> 1n) : U32)

def pak_pop.go(one: Bool, +p: U32, t: Term) -> Term:
  match one:
    case True{}:
      t
    case False{}:
      Pak{run_pop(p), t}

def pak_pop(+p: U32, t: Term) -> Term:
  pak_pop.go(U32.is_eq((p >> 24n : U32), 1), p, t)

def won_pop.go(one: Bool, +p: U32) -> Term:
  match one:
    case True{}:
      One{}
    case False{}:
      Won{run_pop(p)}

def won_pop(+p: U32) -> Term:
  won_pop.go(U32.is_eq((p >> 24n : U32), 1), p)

def bit0(+p: U32) -> Bool:
  U32.is_eq((p .&. 1 : U32), 0)

# The env
# =======

def num(s: Cell) -> U32:
  match s:
    case Num{n}:
      n
    case _:
      0

def cel(s: Cell) -> Term:
  match s:
    case Sub{t}:
      t
    case _:
      Era{}

def subst(env: Array<Cell>, i: U32, v: Cell) -> Array<Cell>:
  Array.set(Cell, env, i, v)

def cov.go(z: Bool, +l: U32, +i: U32) -> Term:
  match z:
    case True{}:
      Co0{l, i}
    case False{}:
      Co1{l, i}

# the occurrence term of dup side sd (0 = Co0, 1 = Co1)
def cov(+sd: U32, +l: U32, +i: U32) -> Term:
  cov.go(U32.is_eq(sd, 0), l, i)

def park.go(z: Bool, w: Term) -> Cell:
  match z:
    case True{}:
      Haf{w}
    case False{}:
      Sha{w}

# a dup value parked back: Haf when the twin is dead (fl = 0)
def park(+fl: U32, w: Term) -> Cell:
  park.go(U32.is_eq(fl, 0), w)

# a fresh cell holding v: the free-list head (its link is the new
# head), else the next id (a virgin cell's Nul link reads 0)
def alloc.go(+n: U32, +nx: U32, p: Array<Cell> & Cell) -> Al:
  (env, s) = p
  Al{env, n, num(s), nx}

def alloc.at(env: Array<Cell>, +fh: U32, +nx: U32, v: Cell, z: Bool) -> Al:
  match z:
    case True{}:
      alloc.go(nx, (nx + 1 : U32), Array.swap(Cell, env, nx, v))
    case False{}:
      alloc.go(fh, nx, Array.swap(Cell, env, fh, v))

def alloc(env: Array<Cell>, +fh: U32, +nx: U32, v: Cell) -> Al:
  alloc.at(env, fh, nx, v, U32.is_eq(fh, 0))

def alloc2.fin(+n: U32, al: Al) -> Al2:
  Al{env, p, fh, nx} = al
  Al2{env, n, p, fh, nx}

def alloc2.go(v2: Cell, al: Al) -> Al2:
  Al{env, n, fh, nx} = al
  alloc2.fin(n, alloc(env, fh, nx, v2))

def alloc2(env: Array<Cell>, +fh: U32, +nx: U32, v1: Cell, v2: Cell) -> Al2:
  alloc2.go(v2, alloc(env, fh, nx, v1))

def alloc3.fin(+n: U32, +p: U32, al: Al) -> Al3:
  Al{env, r, fh, nx} = al
  Al3{env, n, p, r, fh, nx}

def alloc3.go(v3: Cell, al: Al2) -> Al3:
  Al2{env, n, p, fh, nx} = al
  alloc3.fin(n, p, alloc(env, fh, nx, v3))

def alloc3(env: Array<Cell>, +fh: U32, +nx: U32, v1: Cell, v2: Cell, v3: Cell) -> Al3:
  alloc3.go(v3, alloc2(env, fh, nx, v1, v2))

# Book
# ====

def book_put(book: Array<Tpl>, r: U32, t: Tpl) -> Array<Tpl>:
  Array.set(Tpl, book, r, t)

# Collection
# ==========
#
# A dropped term returns its cells to the free list, as hvm5.c's
# collect. A lambda's binder reads Era from now on (its variable may
# live in a dup's copy). A dropped dup side leaves the twin sole
# (Haf), frees the copy parked for it, or marks a value still under
# evaluation (Ded), whose copy the settling side frees.

def free_var(k: FK, +fh: U32, +i: U32, p: Array<Cell> & Cell) -> FS:
  (env, s) = p
  match s:
    case Sub{u}:
      FS{env, u, k, i}
    case _:
      FS{env, Era{}, k, i}

def free_cov(k: FK, +fh: U32, +i: U32, p: Array<Cell> & Cell) -> FS:
  (env, s) = p
  match s:
    case Sha{v}:
      FS{subst(env, i, Haf{v}), Era{}, k, fh}
    case Haf{v}:
      FS{subst(env, i, Num{fh}), v, k, i}
    case Sub{u}:
      FS{subst(env, i, Num{fh}), u, k, i}
    case _:
      FS{subst(env, i, Ded{}), Era{}, k, fh}

@unsafe
def free_run(s: FS) -> Fr:
  FS{env, t, k, fh} = s
  match t:
    case Var{+i}:
      free_run(free_var(k, fh, i, Array.swap(Cell, env, i, Num{fh})))
    case Co0{l, +i}:
      free_run(free_cov(k, fh, i, Array.swap(Cell, env, i, Nul{})))
    case Co1{l, +i}:
      free_run(free_cov(k, fh, i, Array.swap(Cell, env, i, Nul{})))
    case Lam{i, f}:
      free_run(FS{subst(env, i, Sub{Era{}}), f, k, fh})
    case Sup{l, a, b}:
      free_run(FS{env, a, FNxt{b, k}, fh})
    case Cal{a, b}:
      free_run(FS{env, a, FNxt{b, k}, fh})
    case Tup{a, b}:
      free_run(FS{env, a, FNxt{b, k}, fh})
    case Mat{a, b}:
      free_run(FS{env, a, FNxt{b, k}, fh})
    case Drp{f}:
      free_run(FS{env, f, k, fh})
    case Use{f}:
      free_run(FS{env, f, k, fh})
    case Get{f}:
      free_run(FS{env, f, k, fh})
    case Pak{p, f}:
      free_run(FS{env, f, k, fh})
    case _:
      match k:
        case FEnd{}:
          Fr{env, fh}
        case FNxt{u, q}:
          free_run(FS{env, u, q, fh})

def free(env: Array<Cell>, t: Term, +fh: U32) -> Fr:
  free_run(FS{env, t, FEnd{}, fh})

# Nodes
# =====

def node1(sh: Sh1, x: Term) -> Term:
  match sh:
    case SUse{}:
      Use{x}
    case SGet{}:
      Get{x}
    case SDrp{}:
      Drp{x}
    case SLam{n}:
      Lam{n, x}
    case SPak{p}:
      Pak{p, x}

def node2(sh: Sh2, a: Term, b: Term) -> Term:
  match sh:
    case STup{}:
      Tup{a, b}
    case SMat{}:
      Mat{a, b}
    case SApp{}:
      Cal{a, b}
    case SSup{l}:
      Sup{l, a, b}

# Instantiation
# =============
#
# inst copies a borrowed template, riding fh/nx, moving each binder's
# occurrence out of its cell. The phase (IM) says what to do with the
# template node in hand, t, and its sibling, s: copy it; copy it and
# wrap the copy in a one-child shape; copy it as the left child of a
# two-child shape, then its sibling (ILt holds the left copy); copy it
# under a fresh binder cell; copy a dup's value, take its cell, then
# copy the body; copy it once a dropped argument is freed. At the root
# of a reference (FRoot) and under its fused binders (FLam) a leading
# lambda or drop meets a pending Arg frame instead of being copied
# (L_RF0), and a root that is a constructor eliminator defers to its
# scrutinee (K_DISP): the copy answers the scrutinee under an Rfk
# frame (IEnd).

def inst.var(k: Kont, +c: U32, +fh: U32, +nx: U32, p: Array<Cell> & Cell) -> Ins:
  (env, s) = p
  Ins{env, cel(s), k, c, fh, nx}

# a dup side's occurrence: the cell holds the fresh dup cell's id
def inst.cov(k: Kont, +c: U32, +fh: U32, +nx: U32, +l: U32, z: Bool, p: Array<Cell> & Cell) -> Ins:
  (env, s) = p
  Ins{env, cov.go(z, l, num(s)), k, c, fh, nx}

def inst.one(sh: Sh1, r: Ins) -> Ins:
  Ins{env, t, k, c, fh, nx} = r
  Ins{env, node1(sh, t), k, c, fh, nx}

def inst.two(sh: Sh2, a: Term, r: Ins) -> Ins:
  Ins{env, b, k, c, fh, nx} = r
  Ins{env, node2(sh, a, b), k, c, fh, nx}

# a lambda: fused with a pending argument, else under a fresh cell
def inst.lam(env: Array<Cell>, +fh: U32, +nx: U32, fz: Fz, k: Kont, +c: U32, +i: U32) -> IM:
  match fz:
    case FOff{}:
      IAl{alloc(env, fh, nx, Nul{}), i, k, c}
    case _:
      match k:
        case Arg{x, q}:
          IGo{subst(env, i, Sub{x}), fh, nx, FLam{}, q, (c + 1 : U32)}
        case k2:
          IAl{alloc(env, fh, nx, Nul{}), i, k2, c}

# a drop: fused with a pending argument (freed), else copied
def inst.drp(env: Array<Cell>, +fh: U32, +nx: U32, fz: Fz, k: Kont, +c: U32) -> IM:
  match fz:
    case FOff{}:
      IUn{SDrp{}, env, fh, nx, k, c}
    case _:
      match k:
        case Arg{x, q}:
          IFr{free(env, x, fh), nx, q, (c + 1 : U32)}
        case k2:
          IUn{SDrp{}, env, fh, nx, k2, c}

# a unit eliminator: fused with a pending () (L_RF0), else copied
def inst.use(env: Array<Cell>, +fh: U32, +nx: U32, fz: Fz, k: Kont, +c: U32) -> IM:
  match fz:
    case FOff{}:
      IUn{SUse{}, env, fh, nx, k, c}
    case _:
      match k:
        case Arg{x, q}:
          match x:
            case One{}:
              IGo{env, fh, nx, FLam{}, q, (c + 1 : U32)}
            case x2:
              IUn{SUse{}, env, fh, nx, Arg{x2, q}, c}
        case k2:
          IUn{SUse{}, env, fh, nx, k2, c}

# a pair eliminator: fused with a pending pair (its parts become the
# pending arguments), else copied
def inst.get(env: Array<Cell>, +fh: U32, +nx: U32, fz: Fz, k: Kont, +c: U32) -> IM:
  match fz:
    case FOff{}:
      IUn{SGet{}, env, fh, nx, k, c}
    case _:
      match k:
        case Arg{x, q}:
          match x:
            case Tup{a, b}:
              IGo{env, fh, nx, FLam{}, Arg{a, Arg{b, q}}, (c + 1 : U32)}
            case x2:
              IUn{SGet{}, env, fh, nx, Arg{x2, q}, c}
        case k2:
          IUn{SGet{}, env, fh, nx, k2, c}

# a constructor eliminator meets a pending bit: the branch it selects
# (t for #0, the sibling s for #1) runs on the rest, fused
def inst.mat.bit(env: Array<Cell>, +fh: U32, +nx: U32, k: Kont, +c: U32, y: Term, z: Bool) -> IM:
  match z:
    case True{}:
      IGo{env, fh, nx, FLam{}, Arg{y, k}, (c + 1 : U32)}
    case False{}:
      IGr{env, fh, nx, Arg{y, k}, (c + 1 : U32)}

# a constructor eliminator meets a pending argument that is no bit:
# at the root it defers to the argument's whnf (K_DISP), else the
# eliminator is copied
def inst.mat.no(+fz: Fz, env: Array<Cell>, +fh: U32, +nx: U32, x: Term, q: Kont, +c: U32) -> IM:
  match fz:
    case FRoot{r}:
      IEnd{Ins{env, x, Rfk{r, q}, c, fh, nx}}
    case _:
      ITw{SMat{}, env, fh, nx, Arg{x, q}, c}

def inst.mat(env: Array<Cell>, +fh: U32, +nx: U32, +fz: Fz, k: Kont, +c: U32) -> IM:
  match fz:
    case FOff{}:
      ITw{SMat{}, env, fh, nx, k, c}
    case _:
      match k:
        case Arg{x, q}:
          match x:
            case Pak{p, t}:
              inst.mat.bit(env, fh, nx, q, c, pak_pop(p, t), bit0(p))
            case Won{p}:
              inst.mat.bit(env, fh, nx, q, c, won_pop(p), bit0(p))
            case x2:
              inst.mat.no(fz, env, fh, nx, x2, q, c)
        case k2:
          ITw{SMat{}, env, fh, nx, k2, c}

# an application under fusion: the argument's copy becomes a pending
# argument of the head (an application spine ends in the @ref it
# calls, expanded by the loop)
def inst.app(env: Array<Cell>, +fh: U32, +nx: U32, fz: Fz, k: Kont, +c: U32) -> IM:
  match fz:
    case FOff{}:
      ITw{SApp{}, env, fh, nx, k, c}
    case _:
      IAg{env, fh, nx, k, c}

# a dup's cell taken: both binders point at it
def inst.dq(+a: U32, +b: U32, al: Al, k: Kont, +c: U32) -> IM:
  Al{env, n, fh, nx} = al
  IGo{subst(subst(env, a, Num{n}), b, Num{n}), fh, nx, FOff{}, k, c}

def inst.xq(+a: U32, al: Al, k: Kont, +c: U32) -> IM:
  Al{env, n, fh, nx} = al
  IGo{subst(env, a, Num{n}), fh, nx, FOff{}, k, c}

@unsafe
def inst(m: IM, t: Tpl, s: Tpl) -> Ins:
  match m:
    case IGo{env, fh, nx, fz, k, c}:
      match t:
        case TVar{i}:
          inst.var(k, c, fh, nx, Array.swap(Cell, env, i, Nul{}))
        case TCo0{l, i}:
          inst.cov(k, c, fh, nx, l, True{}, Array.swap(Cell, env, i, Nul{}))
        case TCo1{l, i}:
          inst.cov(k, c, fh, nx, l, False{}, Array.swap(Cell, env, i, Nul{}))
        case TSup{l, a, b}:
          inst(ITw{SSup{l}, env, fh, nx, k, c}, a, b)
        case TDup{a, b, v, q}:
          inst(IDv{a, b, env, fh, nx, k, c}, v, q)
        case TDux{a, v, q}:
          inst(IXv{a, env, fh, nx, k, c}, v, q)
        case TLam{i, f}:
          inst(inst.lam(env, fh, nx, fz, k, c, i), f, TEra{})
        case TDrp{f}:
          inst(inst.drp(env, fh, nx, fz, k, c), f, TEra{})
        case TApp{f, x}:
          inst(inst.app(env, fh, nx, fz, k, c), f, x)
        case TUse{f}:
          inst(inst.use(env, fh, nx, fz, k, c), f, TEra{})
        case TPak{p, f}:
          inst(IUn{SPak{p}, env, fh, nx, k, c}, f, TEra{})
        case TWon{p}:
          Ins{env, Won{p}, k, c, fh, nx}
        case TTup{a, b}:
          inst(ITw{STup{}, env, fh, nx, k, c}, a, b)
        case TGet{f}:
          inst(inst.get(env, fh, nx, fz, k, c), f, TEra{})
        case TMat{f, g}:
          inst(inst.mat(env, fh, nx, fz, k, c), f, g)
        case TOne{}:
          Ins{env, One{}, k, c, fh, nx}
        case TRef{n}:
          Ins{env, Ref{n}, k, c, fh, nx}
        case _:
          Ins{env, Era{}, k, c, fh, nx}
    case IUn{sh, env, fh, nx, k, c}:
      inst.one(sh, inst(IGo{env, fh, nx, FOff{}, k, c}, t, TEra{}))
    case ITw{sh, env, fh, nx, k, c}:
      inst(ILt{sh, inst(IGo{env, fh, nx, FOff{}, k, c}, t, TEra{})}, s, TEra{})
    case ILt{sh, r}:
      Ins{env, a, k, c, fh, nx} = r
      inst.two(sh, a, inst(IGo{env, fh, nx, FOff{}, k, c}, t, TEra{}))
    case IAl{al, i, k, c}:
      Al{env, n, fh, nx} = al
      inst.one(SLam{n}, inst(IGo{subst(env, i, Sub{Var{n}}), fh, nx, FOff{}, k, c}, t, TEra{}))
    case IDv{a, b, env, fh, nx, k, c}:
      inst(IDq{a, b, inst(IGo{env, fh, nx, FOff{}, k, c}, t, TEra{})}, s, TEra{})
    case IDq{a, b, r}:
      Ins{env, v, k, c, fh, nx} = r
      inst(inst.dq(a, b, alloc(env, fh, nx, Sha{v}), k, c), t, TEra{})
    case IXv{a, env, fh, nx, k, c}:
      inst(IXq{a, inst(IGo{env, fh, nx, FOff{}, k, c}, t, TEra{})}, s, TEra{})
    case IXq{a, r}:
      Ins{env, v, k, c, fh, nx} = r
      inst(inst.xq(a, alloc(env, fh, nx, Haf{v}), k, c), t, TEra{})
    case IFr{fr, nx, k, c}:
      Fr{env, fh} = fr
      inst(IGo{env, fh, nx, FLam{}, k, c}, t, TEra{})
    case IGr{env, fh, nx, k, c}:
      inst(IGo{env, fh, nx, FLam{}, k, c}, s, TEra{})
    case IAg{env, fh, nx, k, c}:
      inst(IAr{inst(IGo{env, fh, nx, FOff{}, k, c}, s, TEra{})}, t, TEra{})
    case IAr{r}:
      Ins{env, x, k, c, fh, nx} = r
      inst(IGo{env, fh, nx, FLam{}, Arg{x, k}, c}, t, TEra{})
    case IEnd{ins}:
      ins

# References
# ==========
#
# A reference's template is moved out of the book, copied in place
# (the copy borrows it) and written back (ref_fin).

def ref_fin(book: Array<Tpl>, +r: U32, u: Tpl, ins: Ins) -> S:
  Ins{env, t, k, c, fh, nx} = ins
  S{env, book_put(book, r, u), Go{t}, k, c, fh, nx}

def ref_tpl(env: Array<Cell>, book: Array<Tpl>, k: Kont, +c: U32, +fh: U32, +nx: U32, +r: U32, +u: Tpl) -> S:
  ins = inst(IGo{env, fh, nx, FRoot{r}, k, (c + 1 : U32)}, u, TEra{})
  ref_fin(book, r, u, ins)

def go_ref(env: Array<Cell>, k: Kont, +c: U32, +fh: U32, +nx: U32, +r: U32, p: Array<Tpl> & Tpl) -> S:
  (book, u) = p
  ref_tpl(env, book, k, c, fh, nx, r, u)

# K_DISP: a deferred eliminator @ref meets its scrutinee's whnf: a bit
# selects the branch to copy (fused with the rest of the scrutinee),
# any other whnf meets a copy of the whole template
def dsp_bit(env: Array<Cell>, k: Kont, +c: U32, +fh: U32, +nx: U32, f: Tpl, g: Tpl, y: Term, z: Bool) -> Ins:
  match z:
    case True{}:
      inst(IGo{env, fh, nx, FLam{}, Arg{y, k}, (c + 1 : U32)}, f, TEra{})
    case False{}:
      inst(IGo{env, fh, nx, FLam{}, Arg{y, k}, (c + 1 : U32)}, g, TEra{})

def dsp_go(env: Array<Cell>, k: Kont, +c: U32, +fh: U32, +nx: U32, w: Term, u: Tpl) -> Ins:
  match w:
    case Pak{b, t}:
      match u:
        case TMat{f, g}:
          dsp_bit(env, k, c, fh, nx, f, g, pak_pop(b, t), bit0(b))
        case _:
          Ins{env, Era{}, k, c, fh, nx}
    case Won{b}:
      match u:
        case TMat{f, g}:
          dsp_bit(env, k, c, fh, nx, f, g, won_pop(b), bit0(b))
        case _:
          Ins{env, Era{}, k, c, fh, nx}
    case w2:
      inst(IGo{env, fh, nx, FOff{}, Arg{w2, k}, c}, u, TEra{})

def dsp_tpl(env: Array<Cell>, book: Array<Tpl>, k: Kont, +c: U32, +fh: U32, +nx: U32, +r: U32, w: Term, +u: Tpl) -> S:
  ins = dsp_go(env, k, c, fh, nx, w, u)
  ref_fin(book, r, u, ins)

def dsp(env: Array<Cell>, k: Kont, +c: U32, +fh: U32, +nx: U32, +r: U32, w: Term, p: Array<Tpl> & Tpl) -> S:
  (book, u) = p
  dsp_tpl(env, book, k, c, fh, nx, r, w, u)

# The evaluator
# =============
#
# Every helper answers the next S; run matches the stack and the mode.

# the mode to resume after a free (one interaction)
def freed(book: Array<Tpl>, k: Kont, +c: U32, +nx: U32, m: Mode, fr: Fr) -> S:
  Fr{env, fh} = fr
  S{env, book, m, k, (c + 1 : U32), fh, nx}

# a Var read its cell: the substitution continues (the cell is free),
# else the variable is stuck
def go_var(book: Array<Tpl>, k: Kont, +c: U32, +fh: U32, +nx: U32, +i: U32, p: Array<Cell> & Cell) -> S:
  (env, s) = p
  match s:
    case Sub{t}:
      S{env, book, Go{t}, k, c, i, nx}
    case u:
      S{subst(env, i, u), book, Sk{Var{i}}, k, c, fh, nx}

# a dup var read its cell (left empty): the twin's copy, or an
# unresolved value evaluated under a Dpk frame, or stuck
def go_cov(book: Array<Tpl>, k: Kont, +c: U32, +fh: U32, +nx: U32, +l: U32, +i: U32, +sd: U32, p: Array<Cell> & Cell) -> S:
  (env, s) = p
  match s:
    case Sub{t}:
      S{subst(env, i, Num{fh}), book, Go{t}, k, c, i, nx}
    case Sha{v}:
      S{env, book, Go{v}, Dpk{l, i, sd, 1, k}, c, fh, nx}
    case Haf{v}:
      S{env, book, Go{v}, Dpk{l, i, sd, 0, k}, c, fh, nx}
    case u:
      S{subst(env, i, u), book, Sk{cov(sd, l, i)}, k, c, fh, nx}

# Application
# -----------

def app_sup(book: Array<Tpl>, k: Kont, +c: U32, +l: U32, a: Term, b: Term, al: Al) -> S:
  Al{env, n, fh, nx} = al
  S{env, book, Kn{Sup{l, Cal{a, Co0{l, n}}, Cal{b, Co1{l, n}}}}, k, (c + 1 : U32), fh, nx}

def app(env: Array<Cell>, book: Array<Tpl>, k: Kont, +c: U32, +fh: U32, +nx: U32, w: Term, x: Term) -> S:
  match w:
    case Lam{i, f}:
      S{subst(env, i, Sub{x}), book, Go{f}, k, (c + 1 : U32), fh, nx}
    case Drp{f}:
      freed(book, k, c, nx, Go{f}, free(env, x, fh))
    case Sup{l, a, b}:
      app_sup(book, k, c, l, a, b, alloc(env, fh, nx, Sha{x}))
    case Era{}:
      freed(book, k, c, nx, Kn{Era{}}, free(env, x, fh))
    case Use{f}:
      S{env, book, Go{x}, Usk{f, k}, c, fh, nx}
    case Mat{f, g}:
      S{env, book, Go{x}, Mtk{f, g, k}, c, fh, nx}
    case Get{f}:
      S{env, book, Go{x}, Gtk{f, k}, c, fh, nx}
    case u:
      S{env, book, Sk{Cal{u, x}}, k, c, fh, nx}

# a one-child eliminator (shape sh) meets a sup: each side gets it,
# with its child shared through a fresh cell
def eli_sup(book: Array<Tpl>, k: Kont, +c: U32, +m: U32, x: Term, y: Term, +sh: Sh1, al: Al) -> S:
  Al{env, n, fh, nx} = al
  S{env, book, Kn{Sup{m, Cal{node1(sh, Co0{m, n}), x}, Cal{node1(sh, Co1{m, n}), y}}}, k, (c + 1 : U32), fh, nx}

def use(env: Array<Cell>, book: Array<Tpl>, k: Kont, +c: U32, +fh: U32, +nx: U32, w: Term, f: Term) -> S:
  match w:
    case One{}:
      S{env, book, Go{f}, k, (c + 1 : U32), fh, nx}
    case Era{}:
      freed(book, k, c, nx, Kn{Era{}}, free(env, f, fh))
    case Sup{m, x, y}:
      eli_sup(book, k, c, m, x, y, SUse{}, alloc(env, fh, nx, Sha{f}))
    case u:
      S{env, book, Sk{Cal{Use{f}, u}}, k, c, fh, nx}

# the branch the bit selects runs on the rest; the other is freed
def mat_bit(env: Array<Cell>, book: Array<Tpl>, k: Kont, +c: U32, +fh: U32, +nx: U32, f: Term, g: Term, y: Term, z: Bool) -> S:
  match z:
    case True{}:
      freed(book, Arg{y, k}, c, nx, Go{f}, free(env, g, fh))
    case False{}:
      freed(book, Arg{y, k}, c, nx, Go{g}, free(env, f, fh))

def mat_sup(book: Array<Tpl>, k: Kont, +c: U32, +m: U32, x: Term, y: Term, al: Al2) -> S:
  Al2{env, n, p, fh, nx} = al
  S{env, book, Kn{Sup{m, Cal{Mat{Co0{m, n}, Co0{m, p}}, x}, Cal{Mat{Co1{m, n}, Co1{m, p}}, y}}}, k, (c + 1 : U32), fh, nx}

def mat(env: Array<Cell>, book: Array<Tpl>, k: Kont, +c: U32, +fh: U32, +nx: U32, w: Term, f: Term, g: Term) -> S:
  match w:
    case Pak{b, t}:
      mat_bit(env, book, k, c, fh, nx, f, g, pak_pop(b, t), bit0(b))
    case Won{b}:
      mat_bit(env, book, k, c, fh, nx, f, g, won_pop(b), bit0(b))
    case Era{}:
      freed(book, k, c, nx, Kn{Era{}}, free(env, Mat{f, g}, fh))
    case Sup{m, x, y}:
      mat_sup(book, k, c, m, x, y, alloc2(env, fh, nx, Sha{f}, Sha{g}))
    case u:
      S{env, book, Sk{Cal{Mat{f, g}, u}}, k, c, fh, nx}

def get(env: Array<Cell>, book: Array<Tpl>, k: Kont, +c: U32, +fh: U32, +nx: U32, w: Term, f: Term) -> S:
  match w:
    case Tup{a, b}:
      S{env, book, Go{f}, Arg{a, Arg{b, k}}, (c + 1 : U32), fh, nx}
    case Era{}:
      freed(book, k, c, nx, Kn{Era{}}, free(env, f, fh))
    case Sup{m, x, y}:
      eli_sup(book, k, c, m, x, y, SGet{}, alloc(env, fh, nx, Sha{f}))
    case u:
      S{env, book, Sk{Cal{Get{f}, u}}, k, c, fh, nx}

# Duplication
# -----------

# a fires, the twin's copy b is freed with cell i
def settle_fin(book: Array<Tpl>, k: Kont, +c: U32, +nx: U32, +i: U32, a: Term, fr: Fr) -> S:
  Fr{env, fh} = fr
  S{subst(env, i, Num{fh}), book, Go{a}, k, (c + 1 : U32), i, nx}

def settle_ded(book: Array<Tpl>, k: Kont, +c: U32, +fh: U32, +nx: U32, +i: U32, a: Term, p: Array<Cell> & Cell) -> S:
  (env, s) = p
  match s:
    case Sub{b}:
      settle_fin(book, k, c, nx, i, a, free(env, b, fh))
    case _:
      S{env, book, Go{a}, k, (c + 1 : U32), fh, nx}

# b parked in cell i, unless the twin died meanwhile (Ded)
def settle_park(book: Array<Tpl>, k: Kont, +c: U32, +fh: U32, +nx: U32, +i: U32, a: Term, p: Array<Cell> & Cell) -> S:
  (env, s) = p
  match s:
    case Ded{}:
      settle_ded(book, k, c, fh, nx, i, a, Array.swap(Cell, env, i, Nul{}))
    case _:
      S{env, book, Go{a}, k, (c + 1 : U32), fh, nx}

def settle_go(env: Array<Cell>, book: Array<Tpl>, k: Kont, +c: U32, +fh: U32, +nx: U32, +i: U32, a: Term, b: Term, left: Bool, dead: Bool) -> S:
  match left dead:
    case True{} True{}:
      settle_fin(book, k, c, nx, i, a, free(env, b, fh))
    case True{} False{}:
      settle_park(book, k, c, fh, nx, i, a, Array.swap(Cell, env, i, Sub{b}))
    case False{} True{}:
      settle_fin(book, k, c, nx, i, b, free(env, a, fh))
    case False{} False{}:
      settle_park(book, k, c, fh, nx, i, b, Array.swap(Cell, env, i, Sub{a}))

# side sd fires with its copy; the twin's parks in cell i (fl: the
# twin is alive) or is freed with it
def settle(env: Array<Cell>, book: Array<Tpl>, k: Kont, +c: U32, +fh: U32, +nx: U32, +i: U32, +sd: U32, +fl: U32, a: Term, b: Term) -> S:
  settle_go(env, book, k, c, fh, nx, i, a, b, U32.is_eq(sd, 0), U32.is_eq(fl, 0))

def dup_sup(book: Array<Tpl>, k: Kont, +c: U32, +i: U32, +sd: U32, +fl: U32, +l: U32, +m: U32, al: Al2) -> S:
  Al2{env, n, p, fh, nx} = al
  settle(env, book, k, c, fh, nx, i, sd, fl, Sup{m, Co0{l, n}, Co0{l, p}}, Sup{m, Co1{l, n}, Co1{l, p}})

def dup_sup_if(env: Array<Cell>, book: Array<Tpl>, k: Kont, +c: U32, +fh: U32, +nx: U32, +i: U32, +sd: U32, +fl: U32, +l: U32, +m: U32, x: Term, y: Term, same: Bool) -> S:
  match same:
    case True{}:
      settle(env, book, k, c, fh, nx, i, sd, fl, x, y)
    case False{}:
      dup_sup(book, k, c, i, sd, fl, l, m, alloc2(env, fh, nx, Sha{x}, Sha{y}))

def dup_lam(book: Array<Tpl>, k: Kont, +c: U32, +i: U32, +sd: U32, +fl: U32, +l: U32, +j: U32, al: Al3) -> S:
  Al3{env, n, p, r, fh, nx} = al
  settle(subst(env, j, Sub{Sup{l, Var{p}, Var{r}}}), book, k, c, fh, nx, i, sd, fl, Lam{p, Co0{l, n}}, Lam{r, Co1{l, n}})

# a one-child node (shape sh) copied: the child parks in a fresh cell
def dup_one(book: Array<Tpl>, k: Kont, +c: U32, +i: U32, +sd: U32, +fl: U32, +l: U32, +sh: Sh1, al: Al) -> S:
  Al{env, n, fh, nx} = al
  settle(env, book, k, c, fh, nx, i, sd, fl, node1(sh, Co0{l, n}), node1(sh, Co1{l, n}))

# a two-child node (shape sh) copied: the children park in two cells
def dup_two(book: Array<Tpl>, k: Kont, +c: U32, +i: U32, +sd: U32, +fl: U32, +l: U32, +sh: Sh2, al: Al2) -> S:
  Al2{env, n, p, fh, nx} = al
  settle(env, book, k, c, fh, nx, i, sd, fl, node2(sh, Co0{l, n}, Co0{l, p}), node2(sh, Co1{l, n}, Co1{l, p}))

def dup_pak(book: Array<Tpl>, k: Kont, +c: U32, +i: U32, +sd: U32, +fl: U32, +l: U32, +p: U32, al: Al) -> S:
  Al{env, n, fh, nx} = al
  settle(env, book, k, ((c + (p >> 24n)) - 1 : U32), fh, nx, i, sd, fl, Pak{p, Co0{l, n}}, Pak{p, Co1{l, n}})

def dup(env: Array<Cell>, book: Array<Tpl>, k: Kont, +c: U32, +fh: U32, +nx: U32, +l: U32, +i: U32, +sd: U32, +fl: U32, w: Term) -> S:
  match w:
    case Era{}:
      settle(env, book, k, c, fh, nx, i, sd, fl, Era{}, Era{})
    case One{}:
      settle(env, book, k, c, fh, nx, i, sd, fl, One{}, One{})
    case Sup{m, x, y}:
      dup_sup_if(env, book, k, c, fh, nx, i, sd, fl, l, m, x, y, U32.is_eq(l, m))
    case Lam{j, f}:
      dup_lam(book, k, c, i, sd, fl, l, j, alloc3(env, fh, nx, Sha{f}, Nul{}, Nul{}))
    case Drp{f}:
      dup_one(book, k, c, i, sd, fl, l, SDrp{}, alloc(env, fh, nx, Sha{f}))
    case Use{f}:
      dup_one(book, k, c, i, sd, fl, l, SUse{}, alloc(env, fh, nx, Sha{f}))
    case Get{f}:
      dup_one(book, k, c, i, sd, fl, l, SGet{}, alloc(env, fh, nx, Sha{f}))
    case Pak{p, t}:
      match t:
        case One{}:
          settle(env, book, k, (c + (p >> 24n) : U32), fh, nx, i, sd, fl, Pak{p, One{}}, Pak{p, One{}})
        case u:
          dup_pak(book, k, c, i, sd, fl, l, p, alloc(env, fh, nx, Sha{u}))
    case Won{p}:
      settle(env, book, k, (c + (p >> 24n) : U32), fh, nx, i, sd, fl, Won{p}, Won{p})
    case Tup{a, b}:
      dup_two(book, k, c, i, sd, fl, l, STup{}, alloc2(env, fh, nx, Sha{a}, Sha{b}))
    case Mat{f, g}:
      dup_two(book, k, c, i, sd, fl, l, SMat{}, alloc2(env, fh, nx, Sha{f}, Sha{g}))
    case u:
      S{env, book, Sk{u}, Dpk{l, i, sd, fl, k}, c, fh, nx}

# Normalization
# -------------

def nf_lam(book: Array<Tpl>, k: Kont, +c: U32, +fh: U32, +nx: U32, +i: U32, f: Term, p: Array<Cell> & Cell) -> S:
  (env, q) = p
  +n = (num(q) + 1 : U32)
  S{subst(subst(env, 0, Num{n}), i, Sub{Nam{n}}), book, Go{f}, NfK{NAbs{n, k}}, c, fh, nx}

# the whnf under an NfK frame: children get normalized left to right
def nf(env: Array<Cell>, book: Array<Tpl>, k: Kont, +c: U32, +fh: U32, +nx: U32, w: Term) -> S:
  match w:
    case Sup{l, a, b}:
      S{env, book, Go{a}, NfK{NSupA{l, b, k}}, c, fh, nx}
    case Tup{a, b}:
      S{env, book, Go{a}, NfK{NTupA{b, k}}, c, fh, nx}
    case Mat{f, g}:
      S{env, book, Go{f}, NfK{NMatA{g, k}}, c, fh, nx}
    case Pak{p, t}:
      S{env, book, Go{t}, NfK{NPak{p, k}}, c, fh, nx}
    case Use{f}:
      S{env, book, Go{f}, NfK{NUse{k}}, c, fh, nx}
    case Get{f}:
      S{env, book, Go{f}, NfK{NGet{k}}, c, fh, nx}
    case Drp{f}:
      S{env, book, Go{f}, NfK{NDrp{k}}, c, fh, nx}
    case Lam{i, f}:
      nf_lam(book, k, c, fh, nx, i, f, Array.swap(Cell, env, 0, Nul{}))
    case u:
      S{env, book, Kn{u}, k, c, fh, nx}

# The loop
# --------

@unsafe
def run(s: S) -> Out:
  S{env, book, m, k, c, fh, nx} = s
  match m:
    case Go{t}:
      match t:
        case Cal{f, x}:
          run(S{env, book, Go{f}, Arg{x, k}, c, fh, nx})
        case Var{+i}:
          run(go_var(book, k, c, fh, nx, i, Array.swap(Cell, env, i, Num{fh})))
        case Co0{l, +i}:
          run(go_cov(book, k, c, fh, nx, l, i, 0, Array.swap(Cell, env, i, Nul{})))
        case Co1{l, +i}:
          run(go_cov(book, k, c, fh, nx, l, i, 1, Array.swap(Cell, env, i, Nul{})))
        case Ref{r}:
          Exp{env, book, k, c, fh, nx, r}
        case u:
          run(S{env, book, Kn{u}, k, c, fh, nx})
    case Sk{w}:
      match k:
        case Arg{x, q}:
          run(S{env, book, Sk{Cal{w, x}}, q, c, fh, nx})
        case Usk{f, q}:
          run(S{env, book, Sk{Cal{Use{f}, w}}, q, c, fh, nx})
        case Mtk{f, g, q}:
          run(S{env, book, Sk{Cal{Mat{f, g}, w}}, q, c, fh, nx})
        case Gtk{f, q}:
          run(S{env, book, Sk{Cal{Get{f}, w}}, q, c, fh, nx})
        case Dpk{l, i, sd, fl, q}:
          run(S{subst(env, i, park(fl, w)), book, Sk{cov(sd, l, i)}, q, c, fh, nx})
        case Rfk{r, q}:
          run(S{env, book, Sk{Cal{Ref{r}, w}}, q, c, fh, nx})
        case q:
          run(S{env, book, Kn{w}, q, c, fh, nx})
    case Kn{w}:
      match k:
        case Arg{x, q}:
          run(app(env, book, q, c, fh, nx, w, x))
        case Usk{f, q}:
          run(use(env, book, q, c, fh, nx, w, f))
        case Mtk{f, g, q}:
          run(mat(env, book, q, c, fh, nx, w, f, g))
        case Gtk{f, q}:
          run(get(env, book, q, c, fh, nx, w, f))
        case Dpk{l, i, sd, fl, q}:
          run(dup(env, book, q, c, fh, nx, l, i, sd, fl, w))
        case Rfk{r, q}:
          Dsp{env, book, q, c, fh, nx, r, w}
        case NfK{q}:
          run(nf(env, book, q, c, fh, nx, w))
        case NSupA{l, b, q}:
          run(S{env, book, Go{b}, NfK{NSupB{l, w, q}}, c, fh, nx})
        case NSupB{l, a, q}:
          run(S{env, book, Kn{Sup{l, a, w}}, q, c, fh, nx})
        case NTupA{b, q}:
          run(S{env, book, Go{b}, NfK{NTupB{w, q}}, c, fh, nx})
        case NTupB{a, q}:
          run(S{env, book, Kn{Tup{a, w}}, q, c, fh, nx})
        case NMatA{g, q}:
          run(S{env, book, Go{g}, NfK{NMatB{w, q}}, c, fh, nx})
        case NMatB{f, q}:
          run(S{env, book, Kn{Mat{f, w}}, q, c, fh, nx})
        case NPak{p, q}:
          run(S{env, book, Kn{Pak{p, w}}, q, c, fh, nx})
        case NUse{q}:
          run(S{env, book, Kn{Use{w}}, q, c, fh, nx})
        case NGet{q}:
          run(S{env, book, Kn{Get{w}}, q, c, fh, nx})
        case NDrp{q}:
          run(S{env, book, Kn{Drp{w}}, q, c, fh, nx})
        case NAbs{n, q}:
          run(S{env, book, Kn{Abs{n, w}}, q, c, fh, nx})
        case _:
          Fin{env, book, w, c}

# The driver
# ----------
#
# run is a flat loop; the copier is not (it recurses), so a reference
# comes back to the driver, which expands it and resumes the loop.

@unsafe
def drive(o: Out) -> Out:
  match o:
    case Exp{env, book, k, c, fh, nx, +r}:
      drive(run(go_ref(env, k, c, fh, nx, r, Array.swap(Tpl, book, r, TEra{}))))
    case Dsp{env, book, k, c, fh, nx, +r, w}:
      drive(run(dsp(env, k, c, fh, nx, r, w, Array.swap(Tpl, book, r, TEra{}))))
    case o2:
      o2

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

# Main
# ====

# the env: 2^16 cells, the free list keeps the live set small (cell 0
# holds the display-name counter)
def env_new() -> Array<Cell>:
  [Nul{} : Cell*65536n]

def out(o: Out) -> IO(Unit):
  match o:
    case Fin{env, book, w, c}:
      IO.print(term_show(w) ++ "\n- Itrs: " ++ U32.show(c) ++ " interactions")
    case _:
      IO.print("stuck")

# the depth of an array with room for n entries; f: the bits left to try
def book_depth(f: Nat, +n: U32, +d: Nat) -> Nat:
  match f:
    case 0n:
      d
    case 1n+p:
      pick(Nat, U32.is_le(n, (1 << d : U32)), d, book_depth(p, n, 1n+d))

# the definitions written into the book
def book_load(es: List<&2, Ent>, a: Array<Tpl>) -> Array<Tpl>:
  match es:
    case Ent{ix, t} <> r:
      book_load(r, book_put(a, ix, t))
    case Nil{}:
      a

def ents_has.go(eq: Bool, e: Ent, p: List<&2, Ent> & Bool) -> List<&2, Ent> & Bool:
  (r, b) = p
  (e <> r, eq || b)

# is definition ix among the parsed ones
def ents_has(es: List<&2, Ent>, +ix: U32) -> List<&2, Ent> & Bool:
  match es:
    case Ent{+i, t} <> r:
      ents_has.go(U32.is_eq(i, ix), Ent{i, t}, ents_has(r, ix))
    case Nil{}:
      (Nil{}, False{})

# @main normalized and printed; a book without it is an error
def book_run.fin(+ix: U32, +n: U32, +vc: U32, p: List<&2, Ent> & Bool) -> IO(Unit):
  (es, ok) = p
  match ok:
    case True{}:
      out(drive(run(S{env_new(), book_load(es, [TEra{} : Tpl^book_depth(32n, n, 0n)]),
        Go{Ref{ix}}, NfK{End{}}, 0, 0, vc})))
    case False{}:
      IO.print("undefined function @main")

def book_run.go(es: List<&2, Ent>, +vc: U32, p: Names & U32) -> IO(Unit):
  (Names{m, n}, +ix) = p
  book_run.fin(ix, n, vc, ents_has(es, ix))

# the parsed definitions run: binder ids end at vc, fresh ids follow
def book_run(es: List<&2, Ent>, s: St) -> IO(Unit):
  St{h, src, sc, vc, ns} = s
  book_run.go(es, vc, names_find(ns, "main"))

def main() -> IO(Unit):
  prog()(book_run, st_new(program(), Nil{}, 1, Names{Map.new(&2, U32), 0}))
