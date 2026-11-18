# the U32 bit roster an Array law on perfect trees needs (#2059): the
# lemmas that do not need Nat.sub or the Word.sub/cmp laws -- shifting up
# and back down clears the top bit (shr_shl, ctop_eq), the top of a shifted
# word is the top of its tail (top_shl), and 2^d is structural under shl
# (shl_p2), over ctop/top/init/zeros/p2. The proofs are adeerkhan's draft in
# #2059; this file adds the test wrapper. The Array law still needs the
# mask fact, the branch bit, and the subtraction bound, which need the
# missing word laws.
import Base

def ctop_p(+p: Nat, +b: Bool, +t: Word(p)) -> Word(1n+p):
  match p:
    case 0n:
      match t:
        case WNil{}:
          WCon{False{}, WNil{}}
    case 1n+q:
      match t:
        case WCon{b0, tq}:
          WCon{b, ctop_p(q, b0, tq)}

def ctop(n: Nat, w: Word(n)) -> Word(n):
  match n:
    case 0n:
      WNil{}
    case 1n+p:
      match w:
        case WCon{b, t}:
          ctop_p(p, b, t)

def top_p(+p: Nat, +b: Bool, +t: Word(p)) -> Bool:
  match p:
    case 0n:
      b
    case 1n+q:
      match t:
        case WCon{b0, tq}:
          top_p(q, b0, tq)

def top(n: Nat, w: Word(n)) -> Bool:
  match n:
    case 0n:
      False{}
    case 1n+p:
      match w:
        case WCon{b, t}:
          top_p(p, b, t)

# LEMMA A: shifting a word up and back down clears its top bit
def pad_put(+p: Nat, +b: Bool, +t: Word(p)) -> {Word.shr.pad(p, Word.shl.put(p, b, t)) == ctop_p(p, b, t) : Word(1n+p)}:
  match p:
    case 0n:
      match t:
        case WNil{}:
          {==}
    case 1n+q:
      match t:
        case WCon{b0, tq}:
          %pad_put(q, b0, tq) : {WCon{b, Word.shr.pad(q, Word.shl.put(q, b0, tq))} == WCon{b, _} : Word(1n+p)}
          {==}

law shr_shl:
  for +n: Nat
  for w: Word(n)
  {Word.shr(n, Word.shl(n, w)) == ctop(n, w) : Word(n)}

def shr_shl(n, w):
  match n:
    case 0n:
      {==}
    case 1n+p:
      match w:
        case WCon{b, t}:
          %pad_put(p, b, t) : {Word.shr.pad(p, Word.shl.put(p, b, t)) == _ : Word(1n+p)}
          {==}

# LEMMA B: a word whose top bit is False is its own top-cleared copy
def ctop_p_eq(+p: Nat, +b: Bool, +t: Word(p), h: {False{} == top_p(p, b, t) : Bool}) -> {ctop_p(p, b, t) == WCon{b, t} : Word(1n+p)}:
  match p:
    case 0n:
      match t:
        case WNil{}:
          Equal.sym(Word(1n), WCon{b, WNil{}}, WCon{False{}, WNil{}},
            Equal.cong(Bool, Word(1n), x => WCon{x, WNil{}}, b, False{}, Equal.sym(Bool, False{}, b, h)))
    case 1n+q:
      match t:
        case WCon{b0, tq}:
          Equal.cong(Word(1n+q), Word(1n+(1n+q)), x => WCon{b, x},
            ctop_p(q, b0, tq), WCon{b0, tq}, ctop_p_eq(q, b0, tq, h))

law ctop_eq:
  for +n: Nat
  for w: Word(n)
  for h: {False{} == top(n, w) : Bool}
  {ctop(n, w) == w : Word(n)}

def ctop_eq(n, w, h):
  match n:
    case 0n:
      match w:
        case WNil{}:
          {==}
    case 1n+p:
      match w:
        case WCon{b, t}:
          ctop_p_eq(p, b, t, h)

# drop the most significant bit
def init_p(+p: Nat, +b: Bool, +t: Word(p)) -> Word(p):
  match p:
    case 0n:
      WNil{}
    case 1n+q:
      match t:
        case WCon{b0, tq}:
          WCon{b, init_p(q, b0, tq)}

def init(+p: Nat, w: Word(1n+p)) -> Word(p):
  match w:
    case WCon{b, t}:
      init_p(p, b, t)

# the p-shape: init_p(p, b, shl.put(p, b0, t)) == shl.put(p, b, init_p(p, b0, t))
def init_put(+p: Nat, +b: Bool, +b0: Bool, +t: Word(p)) -> {init_p(p, b, Word.shl.put(p, b0, t)) == Word.shl.put(p, b, init_p(p, b0, t)) : Word(p)}:
  match p:
    case 0n:
      match t:
        case WNil{}:
          {==}
    case 1n+q:
      match t:
        case WCon{b1, tq}:
          %init_put(q, b0, b1, tq) : {WCon{b, init_p(q, b0, Word.shl.put(q, b1, tq))} == WCon{b, _} : Word(1n+q)}
          {==}

# shl(p, w) is shl.put(p, False, w): both are False at the head and the bits shifted in
def shl_put(+p: Nat, w: Word(p)) -> {Word.shl(p, w) == Word.shl.put(p, False{}, w) : Word(p)}:
  match p:
    case 0n:
      match w:
        case WNil{}:
          {==}
    case 1n+q:
      match w:
        case WCon{b, t}:
          {==}

# LEMMA C1: dropping the top bit commutes with shifting up (in shl.put form, which is
# what init_put gives; shl_put converts when shl itself is needed)
def init_shl(+p: Nat, w: Word(1n+p)) -> {init(p, Word.shl(1n+p, w)) == Word.shl.put(p, False{}, init(p, w)) : Word(p)}:
  match w:
    case WCon{b, t}:
      init_put(p, False{}, b, t)

# init_p and shl.put are the same recursion; only length 0 differs in the operands
def init_put_eq(+p: Nat, +b: Bool, +t: Word(p)) -> {init_p(p, b, t) == Word.shl.put(p, b, t) : Word(p)}:
  match p:
    case 0n:
      match t:
        case WNil{}:
          {==}
    case 1n+q:
      match t:
        case WCon{b0, tq}:
          %init_put_eq(q, b0, tq) : {WCon{b, init_p(q, b0, tq)} == WCon{b, _} : Word(1n+q)}
          {==}

# top of a word is top_p with an ignored head
def top_cons(+p: Nat, w: Word(p)) -> {top(p, w) == top_p(p, False{}, w) : Bool}:
  match p:
    case 0n:
      match w:
        case WNil{}:
          {==}
    case 1n+q:
      match w:
        case WCon{b, t}:
          {==}

# the top bit of shl.put and of init_p agree: they are the same recursion
def top_put(+p: Nat, +c: Bool, +b: Bool, +t: Word(p)) -> {top_p(p, c, Word.shl.put(p, b, t)) == top_p(p, c, init_p(p, b, t)) : Bool}:
  match p:
    case 0n:
      match t:
        case WNil{}:
          {==}
    case 1n+q:
      match t:
        case WCon{b1, tq}:
          %top_put(q, b, b1, tq) : {top_p(q, b, Word.shl.put(q, b1, tq)) == _ : Bool}
          {==}

law top_shl:
  for +p: Nat
  for w: Word(1n+p)
  {top(1n+p, Word.shl(1n+p, w)) == top(p, init(p, w)) : Bool}

def top_shl(p, w):
  match p:
    case 0n:
      match w:
        case WCon{b, t}:
          match t:
            case WNil{}:
              {==}
    case 1n+q:
      match w:
        case WCon{b, t}:
          match t:
            case WCon{b0, tq}:
              %top_put(q, b, b0, tq) : {top_p(q, b, Word.shl.put(q, b0, tq)) == _ : Bool}
              {==}


def zeros(+n: Nat) -> Word(n):
  match n:
    case 0n:
      WNil{}
    case 1n+p:
      WCon{False{}, zeros(p)}

# 2^d as a word of length n: d zeros, a one, then zeros
def p2(+d: Nat, +n: Nat) -> Word(n):
  match d:
    case 0n:
      match n:
        case 0n:
          WNil{}
        case 1n+q:
          WCon{True{}, zeros(q)}
    case 1n+p:
      match n:
        case 0n:
          WNil{}
        case 1n+q:
          WCon{False{}, p2(p, q)}

# shl.put(p, b, zeros(p)) is b followed by zeros
def shl_put_zeros(+p: Nat, +b: Bool) -> {Word.shl.put(1n+p, b, zeros(1n+p)) == WCon{b, zeros(p)} : Word(1n+p)}:
  match p:
    case 0n:
      {==}
    case 1n+q:
      %shl_put_zeros(q, False{}) : {WCon{b, Word.shl.put(1n+q, False{}, zeros(1n+q))} == WCon{b, _} : Word(1n+(1n+q))}
      {==}

law shl_p2:
  for +p: Nat
  for +n: Nat
  {Word.shl(n, p2(p, n)) == p2(1n+p, n) : Word(n)}

def shl_p2(p, n):
  match p:
    case 0n:
      match n:
        case 0n:
          {==}
        case 1n+q:
          match q:
            case 0n:
              {==}
            case 1n+r:
              Equal.cong(Word(1n+r), Word(1n+(1n+r)), x => WCon{False{}, x},
                Word.shl.put(1n+r, True{}, zeros(1n+r)), WCon{True{}, zeros(r)},
                shl_put_zeros(r, True{}))
    case 1n+r:
      match n:
        case 0n:
          {==}
        case 1n+q:
          Equal.cong(Word(q), Word(1n+q), x => WCon{False{}, x},
            Word.shl.put(q, False{}, p2(r, q)), p2(1n+r, q),
            Equal.trans(Word(q), Word.shl.put(q, False{}, p2(r, q)), Word.shl(q, p2(r, q)), p2(1n+r, q),
              Equal.sym(Word(q), Word.shl(q, p2(r, q)), Word.shl.put(q, False{}, p2(r, q)), shl_put(q, p2(r, q))),
              shl_p2(r, q)))

# the top of a nonempty all-zero word is False
def top_zeros(+p: Nat) -> {top(1n+p, zeros(1n+p)) == False{} : Bool}:
  match p:
    case 0n:
      {==}
    case 1n+q:
      top_zeros(q)

# C, in the form that needs no width: d zeros, a one, then 2+k zeros, so the top is False
law top_p2:
  for +j: Nat
  for +d: Nat
  {top(Nat.add(d, Nat.add(2n, j)), p2(d, Nat.add(d, Nat.add(2n, j)))) == False{} : Bool}

def top_p2(j, d):
  match d:
    case 0n:
      %top_zeros(1n+j) : {top(Nat.add(0n, Nat.add(2n, j)), p2(0n, Nat.add(0n, Nat.add(2n, j)))) == _ : Bool}
      {==}
    case 1n+r:
      Equal.trans(Bool,
        top_p(Nat.add(r, Nat.add(2n, j)), False{}, p2(r, Nat.add(r, Nat.add(2n, j)))),
        top(Nat.add(r, Nat.add(2n, j)), p2(r, Nat.add(r, Nat.add(2n, j)))),
        False{},
        Equal.sym(Bool, top(Nat.add(r, Nat.add(2n, j)), p2(r, Nat.add(r, Nat.add(2n, j)))),
          top_p(Nat.add(r, Nat.add(2n, j)), False{}, p2(r, Nat.add(r, Nat.add(2n, j)))),
          top_cons(Nat.add(r, Nat.add(2n, j)), p2(r, Nat.add(r, Nat.add(2n, j))))),
        top_p2(j, r))

law main:
  {Word.shl(8n, p2(0n, 8n)) == p2(1n, 8n) : Word(8n)}

def main(): shl_p2(0n, 8n)

#|{==}
