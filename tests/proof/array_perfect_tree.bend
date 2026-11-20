# Array.get and Array.set on a perfect tree, proved (#2059, #1934): the U32 mask, halving shift,
# branch bit and right-half index of Array's descent, as Nat facts, and the leaf each slot reads.
# Self-contained: every lemma is proved here, over Base only.
import Base

# Nat
# ---

def le(a: Nat, b: Nat) -> Data:
  {Nat.is_le(a, b) == True{} : Bool}

def lt(a: Nat, b: Nat) -> Data:
  {Nat.is_lt(a, b) == True{} : Bool}

def efq(-G: Type, x: Empty) -> G:
  match x:

def bdisc(b: Bool) -> Type:
  match b:
    case False{}:
      Unit
    case True{}:
      Empty

def ndisc(n: Nat) -> Type:
  match n:
    case 0n:
      Empty
    case 1n+q:
      Unit

def ft(e: {False{} == True{} : Bool}) -> Empty:
  %e : bdisc(_)
  Unit{}

def sne(-q: Nat, e: {1n+q == 0n : Nat}) -> Empty:
  %e : ndisc(_)
  Unit{}

def pred(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+q:
      q

def succ_inj(-a: Nat, -b: Nat, e: {1n+a == 1n+b : Nat}) -> {a == b : Nat}:
  Equal.cong(Nat, Nat, n => pred(n), 1n+a, 1n+b, e)

def lt_zero(+n: Nat, +h: lt(n, 0n)) -> Empty:
  match n:
    case 0n:
      ft(h)
    case 1n+p:
      ft(h)

def add_zero(+a: Nat) -> {a == Nat.add(a, 0n) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n++p:
      %add_zero(p) : {1n+p == 1n+_ : Nat}
      {==}

def add_succ(+a: Nat, -b: Nat) -> {1n+Nat.add(a, b) == Nat.add(a, 1n+b) : Nat}:
  match a:
    case 0n:
      {==}
    case 1n++p:
      %add_succ(p, b) : {2n+Nat.add(p, b) == 1n+_ : Nat}
      {==}

def sub_zero(+n: Nat) -> {n == Nat.sub(n, 0n) : Nat}:
  match n:
    case 0n:
      {==}
    case 1n+p:
      {==}

def double_eq_add(+n: Nat) -> {Nat.double(n) == Nat.add(n, n) : Nat}:
  match n:
    case 0n:
      {==}
    case 1n++p:
      %add_succ(p, p) : {2n+Nat.double(p) == 1n+_ : Nat}
      %double_eq_add(p) : {2n+Nat.double(p) == 2n+_ : Nat}
      {==}

# 2^(e+1) is twice 2^e.
def tps(+e: Nat) -> {Nat.double(Nat.pow(2n, e)) == Nat.pow(2n, 1n+e) : Nat}:
  %add_zero(Nat.pow(2n, e)) : {Nat.double(Nat.pow(2n, e)) == Nat.add(Nat.pow(2n, e), _) : Nat}
  double_eq_add(Nat.pow(2n, e))

def le0(+c: Nat) -> le(0n, c):
  match c:
    case 0n:
      {==}
    case 1n+q:
      {==}

def le_add_right(+a: Nat, +b: Nat) -> le(a, Nat.add(a, b)):
  match a:
    case 0n:
      le0(b)
    case 1n++p:
      le_add_right(p, b)

def le_double(+n: Nat) -> le(n, Nat.double(n)):
  %Equal.sym(Nat, Nat.double(n), Nat.add(n, n), double_eq_add(n)) : le(n, _)
  le_add_right(n, n)

def le_trans(+a: Nat, +b: Nat, +c: Nat, +h1: le(a, b), +h2: le(b, c)) -> le(a, c):
  match a:
    case 0n:
      le0(c)
    case 1n++p:
      match b:
        case 0n:
          efq(le(1n+p, c), ft(h1))
        case 1n++q:
          match c:
            case 0n:
              efq(le(1n+p, 0n), ft(h2))
            case 1n++r:
              le_trans(p, q, r, h1, h2)

def lt_pred(+a: Nat, +b: Nat, +h: lt(1n+a, b)) -> lt(a, b):
  match a:
    case 0n:
      match b:
        case 0n:
          efq(lt(0n, 0n), ft(h))
        case 1n+q:
          {==}
    case 1n++p:
      match b:
        case 0n:
          efq(lt(1n+p, 0n), ft(h))
        case 1n++q:
          lt_pred(p, q, h)

def lt_le(+a: Nat, +b: Nat, +h: lt(a, 1n+b)) -> le(a, b):
  match a:
    case 0n:
      le0(b)
    case 1n++p:
      match b:
        case 0n:
          efq(le(1n+p, 0n), lt_zero(p, h))
        case 1n++q:
          lt_le(p, q, h)

def le_of_not_lt(+a: Nat, +b: Nat, +h: {Nat.is_lt(a, b) == False{} : Bool}) -> le(b, a):
  match a:
    case 0n:
      match b:
        case 0n:
          {==}
        case 1n+q:
          efq(le(1n+q, 0n), ft(Equal.sym(Bool, True{}, False{}, h)))
    case 1n++p:
      match b:
        case 0n:
          {==}
        case 1n++q:
          le_of_not_lt(p, q, h)

def add_sub(+a: Nat, +b: Nat, +h: le(a, b)) -> {Nat.add(a, Nat.sub(b, a)) == b : Nat}:
  match a:
    case 0n:
      Equal.sym(Nat, b, Nat.sub(b, 0n), sub_zero(b))
    case 1n++p:
      match b:
        case 0n:
          efq({Nat.add(1n+p, Nat.sub(0n, 1n+p)) == 0n : Nat}, ft(h))
        case 1n++q:
          %add_sub(p, q, h) : {1n+Nat.add(p, Nat.sub(q, p)) == 1n+_ : Nat}
          {==}

# A width below 1+n leaves room: d + 1 + (n - d) = 1 + n.
def kof(+n: Nat, +d: Nat, +h: lt(d, 1n+n)) -> {Nat.add(d, 1n+Nat.sub(n, d)) == 1n+n : Nat}:
  %add_succ(d, Nat.sub(n, d)) : {_ == 1n+n : Nat}
  %add_sub(d, n, lt_le(d, n, h)) : {1n+Nat.add(d, Nat.sub(n, d)) == 1n+_ : Nat}
  {==}

def lt1_zero(+i: Nat, +h: lt(i, 1n)) -> {0n == i : Nat}:
  match i:
    case 0n:
      {==}
    case 1n+p:
      efq({0n == 1n+p : Nat}, lt_zero(p, h))

def lt_dd(+a: Nat, +b: Nat, +h: lt(Nat.double(a), Nat.double(b))) -> lt(a, b):
  match a:
    case 0n:
      match b:
        case 0n:
          efq(lt(0n, 0n), ft(h))
        case 1n+q:
          {==}
    case 1n++p:
      match b:
        case 0n:
          efq(lt(1n+p, 0n), ft(h))
        case 1n++q:
          lt_dd(p, q, h)

def le_dd(+a: Nat, +b: Nat, +h: le(Nat.double(a), Nat.double(b))) -> le(a, b):
  match a:
    case 0n:
      le0(b)
    case 1n++p:
      match b:
        case 0n:
          efq(le(1n+p, 0n), ft(h))
        case 1n++q:
          le_dd(p, q, h)

# An even number at most an odd one: 2a <= 1 + 2b gives a <= b.
def le_dd1(+a: Nat, +b: Nat, +h: le(Nat.double(a), 1n+Nat.double(b))) -> le(a, b):
  match a:
    case 0n:
      le0(b)
    case 1n++p:
      match b:
        case 0n:
          efq(le(1n+p, 0n), ft(h))
        case 1n++q:
          le_dd1(p, q, h)

def double_inj(+a: Nat, +b: Nat, +e: {Nat.double(a) == Nat.double(b) : Nat}) -> {a == b : Nat}:
  match a:
    case 0n:
      match b:
        case 0n:
          {==}
        case 1n+q:
          efq({0n == 1n+q : Nat}, sne(1n+Nat.double(q), Equal.sym(Nat, 0n, 2n+Nat.double(q), e)))
    case 1n++p:
      match b:
        case 0n:
          efq({1n+p == 0n : Nat}, sne(1n+Nat.double(p), e))
        case 1n++q:
          %double_inj(p, q, succ_inj(Nat.double(p), Nat.double(q), succ_inj(1n+Nat.double(p), 1n+Nat.double(q), e))) : {1n+p == 1n+_ : Nat}
          {==}

def even_ne_odd(+a: Nat, +b: Nat, +e: {Nat.double(a) == 1n+Nat.double(b) : Nat}) -> Empty:
  match a:
    case 0n:
      sne(Nat.double(b), Equal.sym(Nat, 0n, 1n+Nat.double(b), e))
    case 1n++p:
      match b:
        case 0n:
          sne(Nat.double(p), succ_inj(1n+Nat.double(p), 0n, e))
        case 1n++q:
          even_ne_odd(p, q, succ_inj(Nat.double(p), 1n+Nat.double(q), succ_inj(1n+Nat.double(p), 2n+Nat.double(q), e)))

def one_le_pow(+e: Nat) -> le(1n, Nat.pow(2n, e)):
  match e:
    case 0n:
      {==}
    case 1n++f:
      %tps(f) : le(1n, _)
      le_trans(1n, Nat.pow(2n, f), Nat.double(Nat.pow(2n, f)), one_le_pow(f), le_double(Nat.pow(2n, f)))

def sub1dbl(+n: Nat, +hn: le(1n, n)) -> {Nat.sub(Nat.double(n), 1n) == 1n+Nat.double(Nat.sub(n, 1n)) : Nat}:
  match n:
    case 0n:
      efq({Nat.sub(Nat.double(0n), 1n) == 1n+Nat.double(Nat.sub(0n, 1n)) : Nat}, ft(hn))
    case 1n++q:
      %sub_zero(q) : {1n+Nat.double(q) == 1n+Nat.double(_) : Nat}
      {==}

# 2^(e+1) - 1 is 1 + 2*(2^e - 1).
def pm1(+e: Nat) -> {Nat.sub(Nat.pow(2n, 1n+e), 1n) == 1n+Nat.double(Nat.sub(Nat.pow(2n, e), 1n)) : Nat}:
  %tps(e) : {Nat.sub(_, 1n) == 1n+Nat.double(Nat.sub(Nat.pow(2n, e), 1n)) : Nat}
  sub1dbl(Nat.pow(2n, e), one_le_pow(e))

def lt_p2s(+v: Nat, +e: Nat, +h: lt(v, Nat.pow(2n, 1n+e))) -> lt(v, Nat.double(Nat.pow(2n, e))):
  %Equal.sym(Nat, Nat.double(Nat.pow(2n, e)), Nat.pow(2n, 1n+e), tps(e)) : lt(v, _)
  h

def le_p2s(+v: Nat, +e: Nat, +h: le(Nat.pow(2n, 1n+e), v)) -> le(Nat.double(Nat.pow(2n, e)), v):
  %Equal.sym(Nat, Nat.double(Nat.pow(2n, e)), Nat.pow(2n, 1n+e), tps(e)) : le(_, v)
  h

# Twice a difference: 2(x - p) = 2x - 2p and 1 + 2(x - p) = (1 + 2x) - 2p, for p <= x.
def dsub(+q: Nat, +x: Nat, +h: le(q, x)) -> {Nat.double(Nat.sub(x, q)) == Nat.sub(Nat.double(x), Nat.double(q)) : Nat}:
  match q:
    case 0n:
      %sub_zero(x) : {Nat.double(_) == Nat.sub(Nat.double(x), 0n) : Nat}
      sub_zero(Nat.double(x))
    case 1n++r:
      match x:
        case 0n:
          efq({Nat.double(Nat.sub(0n, 1n+r)) == Nat.sub(0n, Nat.double(1n+r)) : Nat}, ft(h))
        case 1n++y:
          dsub(r, y, h)

def dsub1(+q: Nat, +x: Nat, +h: le(q, x)) -> {1n+Nat.double(Nat.sub(x, q)) == Nat.sub(1n+Nat.double(x), Nat.double(q)) : Nat}:
  match q:
    case 0n:
      %sub_zero(x) : {1n+Nat.double(_) == Nat.sub(1n+Nat.double(x), 0n) : Nat}
      {==}
    case 1n++r:
      match x:
        case 0n:
          efq({1n+Nat.double(Nat.sub(0n, 1n+r)) == Nat.sub(1n, Nat.double(1n+r)) : Nat}, ft(h))
        case 1n++y:
          dsub1(r, y, h)

# The right half of a node: q <= i < 2q gives i - q < q.
def sublt(+q: Nat, +i: Nat, +c: Nat, +hle: le(q, i), +hlt: lt(i, Nat.add(q, c))) -> lt(Nat.sub(i, q), c):
  match q:
    case 0n:
      %sub_zero(i) : lt(_, c)
      hlt
    case 1n++r:
      match i:
        case 0n:
          efq(lt(Nat.sub(0n, 1n+r), c), ft(hle))
        case 1n++j:
          sublt(r, j, c, hle, hlt)

def lesub(+q: Nat, +c: Nat, +n: Nat, +h: le(Nat.add(q, c), n)) -> le(c, Nat.sub(n, q)):
  match q:
    case 0n:
      %sub_zero(n) : le(c, _)
      h
    case 1n++r:
      match n:
        case 0n:
          efq(le(c, Nat.sub(0n, 1n+r)), ft(h))
        case 1n++m:
          lesub(r, c, m, h)

# No even number lies in [1, 2).
def no1(+x: Nat, +h1: le(1n, Nat.double(x)), +h2: lt(Nat.double(x), 2n)) -> Empty:
  match x:
    case 0n:
      ft(h1)
    case 1n+q:
      lt_zero(Nat.double(q), h2)

def ltd1(+x: Nat, +h: lt(Nat.double(x), 1n)) -> lt(x, 1n):
  match x:
    case 0n:
      {==}
    case 1n+q:
      efq(lt(1n+q, 1n), lt_zero(1n+Nat.double(q), h))

# Words
# -----

def zw(+n: Nat) -> Word(n):
  match n:
    case 0n:
      WNil{}
    case 1n+p:
      WCon{False{}, zw(p)}

# 2^d in a word of n bits: d zeros, a one, then zeros.
def p2w(+d: Nat, +n: Nat) -> Word(n):
  match d:
    case 0n:
      match n:
        case 0n:
          WNil{}
        case 1n+q:
          WCon{True{}, zw(q)}
    case 1n+p:
      match n:
        case 0n:
          WNil{}
        case 1n+q:
          WCon{False{}, p2w(p, q)}

def w_zero(+n: Nat) -> {0n == Word.to_nat(n, zw(n)) : Nat}:
  match n:
    case 0n:
      {==}
    case 1n++p:
      %w_zero(p) : {0n == Nat.double(_) : Nat}
      {==}

# The value of 2^d in a word of d+1+k bits is 2^d.
def w_p2(+d: Nat, +k: Nat) -> {Nat.pow(2n, d) == Word.to_nat(Nat.add(d, 1n+k), p2w(d, Nat.add(d, 1n+k))) : Nat}:
  match d:
    case 0n:
      %w_zero(k) : {1n == 1n+Nat.double(_) : Nat}
      {==}
    case 1n++p:
      %w_p2(p, k) : {Nat.pow(2n, 1n+p) == Nat.double(_) : Nat}
      %tps(p) : {_ == Nat.double(Nat.pow(2n, p)) : Nat}
      {==}

def put_zw(+m: Nat) -> {zw(m) == Word.shl.put(m, False{}, zw(m)) : Word(m)}:
  match m:
    case 0n:
      {==}
    case 1n++r:
      %put_zw(r) : {zw(1n+r) == WCon{False{}, _} : Word(1n+r)}
      {==}

def put1_zw(+m: Nat) -> {p2w(0n, m) == Word.shl.put(m, True{}, zw(m)) : Word(m)}:
  match m:
    case 0n:
      {==}
    case 1n++r:
      %put_zw(r) : {p2w(0n, 1n+r) == WCon{True{}, _} : Word(1n+r)}
      {==}

def put0_p2(+q: Nat, +m: Nat) -> {p2w(1n+q, m) == Word.shl.put(m, False{}, p2w(q, m)) : Word(m)}:
  match q:
    case 0n:
      match m:
        case 0n:
          {==}
        case 1n++r:
          %put1_zw(r) : {p2w(1n, 1n+r) == WCon{False{}, _} : Word(1n+r)}
          {==}
    case 1n++s:
      match m:
        case 0n:
          {==}
        case 1n++r:
          %put0_p2(s, r) : {p2w(2n+s, 1n+r) == WCon{False{}, _} : Word(1n+r)}
          {==}

# Shifting 2^d up gives 2^(d+1).
def shl_p2(+d: Nat, +n: Nat) -> {p2w(1n+d, n) == Word.shl(n, p2w(d, n)) : Word(n)}:
  match d:
    case 0n:
      match n:
        case 0n:
          {==}
        case 1n++m:
          %put1_zw(m) : {p2w(1n, 1n+m) == WCon{False{}, _} : Word(1n+m)}
          {==}
    case 1n++q:
      match n:
        case 0n:
          {==}
        case 1n++m:
          %put0_p2(q, m) : {p2w(2n+q, 1n+m) == WCon{False{}, _} : Word(1n+m)}
          {==}

def sp_zw(+q: Nat) -> {zw(1n+q) == Word.shr.pad(q, zw(q)) : Word(1n+q)}:
  match q:
    case 0n:
      {==}
    case 1n++r:
      %sp_zw(r) : {zw(2n+r) == WCon{False{}, _} : Word(2n+r)}
      {==}

def sp_p2(+d: Nat, +k: Nat) -> {p2w(d, 1n+Nat.add(d, 1n+k)) == Word.shr.pad(Nat.add(d, 1n+k), p2w(d, Nat.add(d, 1n+k))) : Word(1n+Nat.add(d, 1n+k))}:
  match d:
    case 0n:
      %sp_zw(k) : {p2w(0n, 2n+k) == WCon{True{}, _} : Word(2n+k)}
      {==}
    case 1n++p:
      %sp_p2(p, k) : {p2w(1n+p, 1n+Nat.add(1n+p, 1n+k)) == WCon{False{}, _} : Word(1n+Nat.add(1n+p, 1n+k))}
      {==}

# Halving 2^(e+1) gives 2^e, in 32 bits.
def shr_p2(+e: Nat, +k: Nat, +hk: {Nat.add(e, 1n+k) == 31n : Nat}) -> {p2w(e, 32n) == Word.shr(32n, p2w(1n+e, 32n)) : Word(32n)}:
  %hk : {p2w(e, 1n+_) == Word.shr.pad(_, p2w(e, _)) : Word(1n+_)}
  sp_p2(e, k)

# Word arithmetic
# ---------------

# Subtracting zero with the carry in keeps a word: a + ~0 + 1 = a.
def adc0(+n: Nat, a: Word(n)) -> {a == Word.adc(n, a, zw(n), True{}, True{}) : Word(n)}:
  match n:
    case 0n:
      match a:
        case WNil{}:
          {==}
    case 1n++p:
      match a:
        case WCon{False{}, +t}:
          %adc0(p, t) : {WCon{False{}, t} == WCon{False{}, _} : Word(1n+p)}
          {==}
        case WCon{True{}, +t}:
          %adc0(p, t) : {WCon{True{}, t} == WCon{True{}, _} : Word(1n+p)}
          {==}

# q ones, then zeros.
def low(+q: Nat, +n: Nat) -> Word(n):
  match q:
    case 0n:
      zw(n)
    case 1n+r:
      match n:
        case 0n:
          WNil{}
        case 1n+m:
          WCon{True{}, low(r, m)}

# The borrow runs up to 2^q: 2^q + ~0 with no carry in is q ones.
def borrow(+q: Nat, +n: Nat) -> {low(q, n) == Word.adc(n, p2w(q, n), zw(n), True{}, False{}) : Word(n)}:
  match q:
    case 0n:
      match n:
        case 0n:
          {==}
        case 1n++m:
          %adc0(m, zw(m)) : {zw(1n+m) == WCon{False{}, _} : Word(1n+m)}
          {==}
    case 1n++r:
      match n:
        case 0n:
          {==}
        case 1n++m:
          %borrow(r, m) : {low(1n+r, 1n+m) == WCon{True{}, _} : Word(1n+m)}
          {==}

def w_low(+q: Nat, +k: Nat) -> {Nat.sub(Nat.pow(2n, q), 1n) == Word.to_nat(Nat.add(q, k), low(q, Nat.add(q, k))) : Nat}:
  match q:
    case 0n:
      w_zero(k)
    case 1n++r:
      %w_low(r, k) : {Nat.sub(Nat.pow(2n, 1n+r), 1n) == 1n+Nat.double(_) : Nat}
      pm1(r)

# 2^d - 1 in a word: the value of sub(2^d, 1).
def sub_one(+d: Nat, +m: Nat) -> {Word.to_nat(1n+Nat.add(d, m), low(d, 1n+Nat.add(d, m))) == Word.to_nat(1n+Nat.add(d, m), Word.sub(1n+Nat.add(d, m), p2w(d, 1n+Nat.add(d, m)), p2w(0n, 1n+Nat.add(d, m)))) : Nat}:
  match d:
    case 0n:
      %adc0(m, zw(m)) : {Nat.double(Word.to_nat(m, zw(m))) == Nat.double(Word.to_nat(m, _)) : Nat}
      {==}
    case 1n++e:
      %borrow(e, 1n+Nat.add(e, m)) : {1n+Nat.double(Word.to_nat(1n+Nat.add(e, m), low(e, 1n+Nat.add(e, m)))) == 1n+Nat.double(Word.to_nat(1n+Nat.add(e, m), _)) : Nat}
      {==}

# Subtracting 2^e from a value in [2^e, 2^(e+1)) clears bit e.
def sub_set(+e: Nat, +n: Nat, a: Word(n), +h1: le(Nat.pow(2n, e), Word.to_nat(n, a)), +h2: lt(Word.to_nat(n, a), Nat.pow(2n, 1n+e))) -> {Nat.sub(Word.to_nat(n, a), Nat.pow(2n, e)) == Word.to_nat(n, Word.sub(n, a, p2w(e, n))) : Nat}:
  match e:
    case 0n:
      match n:
        case 0n:
          match a:
            case WNil{}:
              efq({Nat.sub(0n, 1n) == 0n : Nat}, ft(h1))
        case 1n++k:
          match a:
            case WCon{True{}, +t}:
              %adc0(k, t) : {Nat.sub(1n+Nat.double(Word.to_nat(k, t)), 1n) == Nat.double(Word.to_nat(k, _)) : Nat}
              %sub_zero(Nat.double(Word.to_nat(k, t))) : {_ == Nat.double(Word.to_nat(k, t)) : Nat}
              {==}
            case WCon{False{}, +t}:
              efq({Nat.sub(Nat.double(Word.to_nat(k, t)), 1n) == Word.to_nat(1n+k, Word.sub(1n+k, WCon{False{}, t}, p2w(0n, 1n+k))) : Nat}, no1(Word.to_nat(k, t), h1, h2))
    case 1n++f:
      match n:
        case 0n:
          match a:
            case WNil{}:
              efq({Nat.sub(0n, Nat.pow(2n, 1n+f)) == 0n : Nat}, ft(le_trans(1n, Nat.pow(2n, 1n+f), 0n, one_le_pow(1n+f), h1)))
        case 1n++m:
          match a:
            case WCon{False{}, +t}:
              +x = Word.to_nat(m, t)
              +g1 = le_dd(Nat.pow(2n, f), x, le_p2s(Nat.double(x), f, h1))
              +g2 = lt_dd(x, Nat.pow(2n, 1n+f), lt_p2s(Nat.double(x), 1n+f, h2))
              %sub_set(f, m, t, g1, g2) : {Nat.sub(Nat.double(x), Nat.pow(2n, 1n+f)) == Nat.double(_) : Nat}
              %tps(f) : {Nat.sub(Nat.double(x), _) == Nat.double(Nat.sub(x, Nat.pow(2n, f))) : Nat}
              Equal.sym(Nat, Nat.double(Nat.sub(x, Nat.pow(2n, f))), Nat.sub(Nat.double(x), Nat.double(Nat.pow(2n, f))), dsub(Nat.pow(2n, f), x, g1))
            case WCon{True{}, +t}:
              +x = Word.to_nat(m, t)
              +g1 = le_dd1(Nat.pow(2n, f), x, le_p2s(1n+Nat.double(x), f, h1))
              +g2 = lt_dd(x, Nat.pow(2n, 1n+f), lt_pred(Nat.double(x), Nat.double(Nat.pow(2n, 1n+f)), lt_p2s(1n+Nat.double(x), 1n+f, h2)))
              %sub_set(f, m, t, g1, g2) : {Nat.sub(1n+Nat.double(x), Nat.pow(2n, 1n+f)) == 1n+Nat.double(_) : Nat}
              %tps(f) : {Nat.sub(1n+Nat.double(x), _) == 1n+Nat.double(Nat.sub(x, Nat.pow(2n, f))) : Nat}
              Equal.sym(Nat, 1n+Nat.double(Nat.sub(x, Nat.pow(2n, f))), Nat.sub(1n+Nat.double(x), Nat.double(Nat.pow(2n, f))), dsub1(Nat.pow(2n, f), x, g1))

# Word.cmp is the order of the values: one step per bit, low bit last.
def ncff(+a: Nat, +b: Nat) -> {Nat.cmp(Nat.double(a), Nat.double(b)) == Word.cmp.fin(False{}, False{}, Nat.cmp(a, b)) : Cmp}:
  match a:
    case 0n:
      match b:
        case 0n:
          {==}
        case 1n+q:
          {==}
    case 1n++p:
      match b:
        case 0n:
          {==}
        case 1n++q:
          ncff(p, q)

def ncft(+a: Nat, +b: Nat) -> {Nat.cmp(Nat.double(a), 1n+Nat.double(b)) == Word.cmp.fin(False{}, True{}, Nat.cmp(a, b)) : Cmp}:
  match a:
    case 0n:
      match b:
        case 0n:
          {==}
        case 1n+q:
          {==}
    case 1n++p:
      match b:
        case 0n:
          {==}
        case 1n++q:
          ncft(p, q)

def nctf(+a: Nat, +b: Nat) -> {Nat.cmp(1n+Nat.double(a), Nat.double(b)) == Word.cmp.fin(True{}, False{}, Nat.cmp(a, b)) : Cmp}:
  match a:
    case 0n:
      match b:
        case 0n:
          {==}
        case 1n+q:
          {==}
    case 1n++p:
      match b:
        case 0n:
          {==}
        case 1n++q:
          nctf(p, q)

def nctt(+a: Nat, +b: Nat) -> {Nat.cmp(1n+Nat.double(a), 1n+Nat.double(b)) == Word.cmp.fin(True{}, True{}, Nat.cmp(a, b)) : Cmp}:
  match a:
    case 0n:
      match b:
        case 0n:
          {==}
        case 1n+q:
          {==}
    case 1n++p:
      match b:
        case 0n:
          {==}
        case 1n++q:
          nctt(p, q)

def cmp_to_nat(+n: Nat, a: Word(n), b: Word(n)) -> {Nat.cmp(Word.to_nat(n, a), Word.to_nat(n, b)) == Word.cmp(n, a, b) : Cmp}:
  match n:
    case 0n:
      match a b:
        case WNil{} WNil{}:
          {==}
    case 1n++p:
      match a b:
        case WCon{False{}, +s} WCon{False{}, +t}:
          %cmp_to_nat(p, s, t) : {Nat.cmp(Nat.double(Word.to_nat(p, s)), Nat.double(Word.to_nat(p, t))) == Word.cmp.fin(False{}, False{}, _) : Cmp}
          ncff(Word.to_nat(p, s), Word.to_nat(p, t))
        case WCon{False{}, +s} WCon{True{}, +t}:
          %cmp_to_nat(p, s, t) : {Nat.cmp(Nat.double(Word.to_nat(p, s)), 1n+Nat.double(Word.to_nat(p, t))) == Word.cmp.fin(False{}, True{}, _) : Cmp}
          ncft(Word.to_nat(p, s), Word.to_nat(p, t))
        case WCon{True{}, +s} WCon{False{}, +t}:
          %cmp_to_nat(p, s, t) : {Nat.cmp(1n+Nat.double(Word.to_nat(p, s)), Nat.double(Word.to_nat(p, t))) == Word.cmp.fin(True{}, False{}, _) : Cmp}
          nctf(Word.to_nat(p, s), Word.to_nat(p, t))
        case WCon{True{}, +s} WCon{True{}, +t}:
          %cmp_to_nat(p, s, t) : {Nat.cmp(1n+Nat.double(Word.to_nat(p, s)), 1n+Nat.double(Word.to_nat(p, t))) == Word.cmp.fin(True{}, True{}, _) : Cmp}
          nctt(Word.to_nat(p, s), Word.to_nat(p, t))

# Masking a word below 2^d with a word worth 2^d - 1 keeps it.
def wmask(+n: Nat, +d: Nat, a: Word(n), m: Word(n), +hm: {Word.to_nat(n, m) == Nat.sub(Nat.pow(2n, d), 1n) : Nat}, +ha: lt(Word.to_nat(n, a), Nat.pow(2n, d))) -> {a == Word.and(n, a, m) : Word(n)}:
  match n:
    case 0n:
      match a m:
        case WNil{} WNil{}:
          {==}
    case 1n++p:
      match d:
        case 0n:
          match a m:
            case WCon{True{}, +at} WCon{+mb, +mt}:
              efq({WCon{True{}, at} == Word.and(1n+p, WCon{True{}, at}, WCon{mb, mt}) : Word(1n+p)}, lt_zero(Nat.double(Word.to_nat(p, at)), ha))
            case WCon{False{}, +at} WCon{True{}, +mt}:
              efq({WCon{False{}, at} == Word.and(1n+p, WCon{False{}, at}, WCon{True{}, mt}) : Word(1n+p)}, sne(Nat.double(Word.to_nat(p, mt)), hm))
            case WCon{False{}, +at} WCon{False{}, +mt}:
              +hm1 = double_inj(Word.to_nat(p, mt), 0n, hm)
              +ha1 = ltd1(Word.to_nat(p, at), ha)
              %wmask(p, 0n, at, mt, hm1, ha1) : {WCon{False{}, at} == WCon{False{}, _} : Word(1n+p)}
              {==}
        case 1n++e:
          match a m:
            case WCon{+ab, +at} WCon{False{}, +mt}:
              +hm2 = Equal.trans(Nat, Word.to_nat(1n+p, WCon{False{}, mt}), Nat.sub(Nat.pow(2n, 1n+e), 1n), 1n+Nat.double(Nat.sub(Nat.pow(2n, e), 1n)), hm, pm1(e))
              efq({WCon{ab, at} == Word.and(1n+p, WCon{ab, at}, WCon{False{}, mt}) : Word(1n+p)}, even_ne_odd(Word.to_nat(p, mt), Nat.sub(Nat.pow(2n, e), 1n), hm2))
            case WCon{False{}, +at} WCon{True{}, +mt}:
              +hm2 = Equal.trans(Nat, Word.to_nat(1n+p, WCon{True{}, mt}), Nat.sub(Nat.pow(2n, 1n+e), 1n), 1n+Nat.double(Nat.sub(Nat.pow(2n, e), 1n)), hm, pm1(e))
              +hm3 = double_inj(Word.to_nat(p, mt), Nat.sub(Nat.pow(2n, e), 1n), succ_inj(Nat.double(Word.to_nat(p, mt)), Nat.double(Nat.sub(Nat.pow(2n, e), 1n)), hm2))
              +ha2 = lt_p2s(Word.to_nat(1n+p, WCon{False{}, at}), e, ha)
              %wmask(p, e, at, mt, hm3, lt_dd(Word.to_nat(p, at), Nat.pow(2n, e), ha2)) : {WCon{False{}, at} == WCon{False{}, _} : Word(1n+p)}
              {==}
            case WCon{True{}, +at} WCon{True{}, +mt}:
              +hm2 = Equal.trans(Nat, Word.to_nat(1n+p, WCon{True{}, mt}), Nat.sub(Nat.pow(2n, 1n+e), 1n), 1n+Nat.double(Nat.sub(Nat.pow(2n, e), 1n)), hm, pm1(e))
              +hm3 = double_inj(Word.to_nat(p, mt), Nat.sub(Nat.pow(2n, e), 1n), succ_inj(Nat.double(Word.to_nat(p, mt)), Nat.double(Nat.sub(Nat.pow(2n, e), 1n)), hm2))
              +ha2 = lt_p2s(Word.to_nat(1n+p, WCon{True{}, at}), e, ha)
              %wmask(p, e, at, mt, hm3, lt_dd(Word.to_nat(p, at), Nat.pow(2n, e), lt_pred(Nat.double(Word.to_nat(p, at)), Nat.double(Nat.pow(2n, e)), ha2))) : {WCon{True{}, at} == WCon{True{}, _} : Word(1n+p)}
              {==}

# U32
# ---

def shln_p2(+d: Nat) -> {U32{p2w(d, 32n)} == U32.shln(1, d) : U32}:
  match d:
    case 0n:
      {==}
    case 1n++e:
      %shln_p2(e) : {U32{p2w(1n+e, 32n)} == U32.shl(_) : U32}
      %shl_p2(e, 32n) : {U32{p2w(1n+e, 32n)} == U32{_} : U32}
      {==}

def pw_val(+d: Nat, +h: lt(d, 32n)) -> {Nat.pow(2n, d) == Word.to_nat(32n, p2w(d, 32n)) : Nat}:
  %kof(31n, d, h) : {Nat.pow(2n, d) == Word.to_nat(_, p2w(d, _)) : Nat}
  w_p2(d, Nat.sub(31n, d))

def low_val(+d: Nat, +h: lt(d, 32n)) -> {Nat.sub(Nat.pow(2n, d), 1n) == Word.to_nat(32n, Word.sub(32n, p2w(d, 32n), p2w(0n, 32n))) : Nat}:
  %kof(31n, d, h) : {Nat.sub(Nat.pow(2n, d), 1n) == Word.to_nat(_, Word.sub(_, p2w(d, _), p2w(0n, _))) : Nat}
  %add_succ(d, Nat.sub(31n, d)) : {Nat.sub(Nat.pow(2n, d), 1n) == Word.to_nat(_, Word.sub(_, p2w(d, _), p2w(0n, _))) : Nat}
  %sub_one(d, Nat.sub(31n, d)) : {Nat.sub(Nat.pow(2n, d), 1n) == _ : Nat}
  %Equal.sym(Nat, 1n+Nat.add(d, Nat.sub(31n, d)), Nat.add(d, 1n+Nat.sub(31n, d)), add_succ(d, Nat.sub(31n, d))) : {Nat.sub(Nat.pow(2n, d), 1n) == Word.to_nat(_, low(d, _)) : Nat}
  w_low(d, 1n+Nat.sub(31n, d))

# The value of 1 shifted left d times is 2^d, for d < 32.
law u32_shln_one:
  for +d: Nat
  for +h: lt(d, 32n)
  {U32.to_nat(U32.shln(1, d)) == Nat.pow(2n, d) : Nat}

def u32_shln_one(d, h):
  %shln_p2(d) : {U32.to_nat(_) == Nat.pow(2n, d) : Nat}
  Equal.sym(Nat, Nat.pow(2n, d), Word.to_nat(32n, p2w(d, 32n)), pw_val(d, h))

def shr_shln_r(+e: Nat, +h: lt(1n+e, 32n)) -> {U32.shln(1, e) == U32.shr(U32.shln(1, 1n+e)) : U32}:
  %shln_p2(e) : {_ == U32.shr(U32.shln(1, 1n+e)) : U32}
  %shln_p2(1n+e) : {U32{p2w(e, 32n)} == U32.shr(_) : U32}
  Equal.cong(Word(32n), U32, w => U32{w}, p2w(e, 32n), Word.shr(32n, p2w(1n+e, 32n)), shr_p2(e, Nat.sub(30n, e), kof(30n, e, h)))

# Halving 1 shifted left e+1 times gives 1 shifted left e times, for e+1 < 32.
law u32_shr_shln_one:
  for +e: Nat
  for +h: lt(1n+e, 32n)
  {U32.shr(U32.shln(1, 1n+e)) == U32.shln(1, e) : U32}

def u32_shr_shln_one(e, h):
  Equal.sym(U32, U32.shln(1, e), U32.shr(U32.shln(1, 1n+e)), shr_shln_r(e, h))

def is_lt_r(x: U32, +e: Nat, +h: lt(e, 32n)) -> {Nat.is_lt(U32.to_nat(x), Nat.pow(2n, e)) == U32.is_lt(x, U32.shln(1, e)) : Bool}:
  match x:
    case U32{+w}:
      %shln_p2(e) : {Nat.is_lt(Word.to_nat(32n, w), Nat.pow(2n, e)) == U32.is_lt(U32{w}, _) : Bool}
      %cmp_to_nat(32n, w, p2w(e, 32n)) : {Nat.is_lt(Word.to_nat(32n, w), Nat.pow(2n, e)) == Cmp.is_lt(_) : Bool}
      %pw_val(e, h) : {Nat.is_lt(Word.to_nat(32n, w), Nat.pow(2n, e)) == Cmp.is_lt(Nat.cmp(Word.to_nat(32n, w), _)) : Bool}
      {==}

# Comparing with 1 shifted left e times compares the value with 2^e, for e < 32.
law u32_is_lt_shln_one:
  for +x: U32
  for +e: Nat
  for +h: lt(e, 32n)
  {U32.is_lt(x, U32.shln(1, e)) == Nat.is_lt(U32.to_nat(x), Nat.pow(2n, e)) : Bool}

def u32_is_lt_shln_one(x, e, h):
  Equal.sym(Bool, Nat.is_lt(U32.to_nat(x), Nat.pow(2n, e)), U32.is_lt(x, U32.shln(1, e)), is_lt_r(x, e, h))

def sub_r(x: U32, +e: Nat, +h1: le(Nat.pow(2n, e), U32.to_nat(x)), +h2: lt(U32.to_nat(x), Nat.pow(2n, 1n+e))) -> {Nat.sub(U32.to_nat(x), Nat.pow(2n, e)) == U32.to_nat(U32.sub(x, U32.shln(1, e))) : Nat}:
  match x:
    case U32{+w}:
      %shln_p2(e) : {Nat.sub(Word.to_nat(32n, w), Nat.pow(2n, e)) == U32.to_nat(U32.sub(U32{w}, _)) : Nat}
      sub_set(e, 32n, w, h1, h2)

# Subtracting 1 shifted left e times from a value in [2^e, 2^(e+1)) subtracts 2^e.
law u32_sub_shln_one:
  for +x: U32
  for +e: Nat
  for +h1: le(Nat.pow(2n, e), U32.to_nat(x))
  for +h2: lt(U32.to_nat(x), Nat.pow(2n, 1n+e))
  {U32.to_nat(U32.sub(x, U32.shln(1, e))) == Nat.sub(U32.to_nat(x), Nat.pow(2n, e)) : Nat}

def u32_sub_shln_one(x, e, h1, h2):
  Equal.sym(Nat, Nat.sub(U32.to_nat(x), Nat.pow(2n, e)), U32.to_nat(U32.sub(x, U32.shln(1, e))), sub_r(x, e, h1, h2))

def mask_r(x: U32, +d: Nat, +h: lt(d, 32n), +ha: lt(U32.to_nat(x), Nat.pow(2n, d))) -> {x == U32.and(x, U32.sub(U32.shln(1, d), 1)) : U32}:
  match x:
    case U32{+w}:
      %shln_p2(d) : {U32{w} == U32.and(U32{w}, U32.sub(_, 1)) : U32}
      Equal.cong(Word(32n), U32, v => U32{v}, w, Word.and(32n, w, Word.sub(32n, p2w(d, 32n), p2w(0n, 32n))), wmask(32n, d, w, Word.sub(32n, p2w(d, 32n), p2w(0n, 32n)), Equal.sym(Nat, Nat.sub(Nat.pow(2n, d), 1n), Word.to_nat(32n, Word.sub(32n, p2w(d, 32n), p2w(0n, 32n))), low_val(d, h)), ha))

# Masking with 1 shifted left d times, minus 1, keeps a value below 2^d, for d < 32.
law u32_and_low_mask:
  for +x: U32
  for +d: Nat
  for +h: lt(d, 32n)
  for +ha: lt(U32.to_nat(x), Nat.pow(2n, d))
  {U32.and(x, U32.sub(U32.shln(1, d), 1)) == x : U32}

def u32_and_low_mask(x, d, h, ha):
  Equal.sym(U32, x, U32.and(x, U32.sub(U32.shln(1, d), 1)), mask_r(x, d, h, ha))

# Lists
# -----

def nth(l: List<&2, Nat>, +i: Nat) -> Nat:
  match l:
    case Nil{}:
      0n
    case Con{h, t}:
      match i:
        case 0n:
          h
        case 1n+p:
          nth(t, p)

def upd(l: List<&2, Nat>, +i: Nat, v: Nat) -> List<&2, Nat>:
  match l:
    case Nil{}:
      Nil{}
    case Con{h, t}:
      match i:
        case 0n:
          Con{v, t}
        case 1n+p:
          Con{h, upd(t, p, v)}

def drop(+k: Nat, l: List<&2, Nat>) -> List<&2, Nat>:
  match k:
    case 0n:
      l
    case 1n+p:
      match l:
        case Nil{}:
          Nil{}
        case Con{h, t}:
          drop(p, t)

def len(l: List<&2, Nat>) -> Nat:
  match l:
    case Nil{}:
      0n
    case Con{h, t}:
      1n+len(t)

def nth_drop(+k: Nat, +l: List<&2, Nat>, +i: Nat, +h: le(k, i)) -> {nth(l, i) == nth(drop(k, l), Nat.sub(i, k)) : Nat}:
  match k:
    case 0n:
      %sub_zero(i) : {nth(l, i) == nth(l, _) : Nat}
      {==}
    case 1n++p:
      match l:
        case Nil{}:
          {==}
        case Con{+x, +t}:
          match i:
            case 0n:
              efq({nth(Con{x, t}, 0n) == nth(drop(1n+p, Con{x, t}), Nat.sub(0n, 1n+p)) : Nat}, ft(h))
            case 1n++j:
              nth_drop(p, t, j, h)

def nth_upd_same(l: List<&2, Nat>, +i: Nat, +v: Nat, +h: lt(i, len(l))) -> {v == nth(upd(l, i, v), i) : Nat}:
  match l:
    case Nil{}:
      efq({v == nth(upd(Nil{}, i, v), i) : Nat}, lt_zero(i, h))
    case Con{x, t}:
      match i:
        case 0n:
          {==}
        case 1n++j:
          nth_upd_same(t, j, v, h)

def drop_upd_lo(+k: Nat, +l: List<&2, Nat>, +i: Nat, +v: Nat, +h: lt(i, k)) -> {drop(k, l) == drop(k, upd(l, i, v)) : List<&2, Nat>}:
  match k:
    case 0n:
      efq({drop(0n, l) == drop(0n, upd(l, i, v)) : List<&2, Nat>}, lt_zero(i, h))
    case 1n++p:
      match l:
        case Nil{}:
          {==}
        case Con{+x, +t}:
          match i:
            case 0n:
              {==}
            case 1n++j:
              drop_upd_lo(p, t, j, v, h)

def drop_upd_hi(+k: Nat, +l: List<&2, Nat>, +i: Nat, +v: Nat, +h: le(k, i)) -> {upd(drop(k, l), Nat.sub(i, k), v) == drop(k, upd(l, i, v)) : List<&2, Nat>}:
  match k:
    case 0n:
      %sub_zero(i) : {upd(l, _, v) == upd(l, i, v) : List<&2, Nat>}
      {==}
    case 1n++p:
      match l:
        case Nil{}:
          {==}
        case Con{+x, +t}:
          match i:
            case 0n:
              efq({upd(drop(1n+p, Con{x, t}), Nat.sub(0n, 1n+p), v) == drop(1n+p, upd(Con{x, t}, 0n, v)) : List<&2, Nat>}, ft(h))
            case 1n++j:
              drop_upd_hi(p, t, j, v, h)

def nth0_upd(+l: List<&2, Nat>, +i: Nat, +v: Nat, +h: le(1n, i)) -> {nth(l, 0n) == nth(upd(l, i, v), 0n) : Nat}:
  match l:
    case Nil{}:
      {==}
    case Con{+x, +t}:
      match i:
        case 0n:
          efq({nth(Con{x, t}, 0n) == nth(upd(Con{x, t}, 0n, v), 0n) : Nat}, ft(h))
        case 1n+j:
          {==}

def len_drop(+k: Nat, +l: List<&2, Nat>) -> {Nat.sub(len(l), k) == len(drop(k, l)) : Nat}:
  match k:
    case 0n:
      Equal.sym(Nat, len(l), Nat.sub(len(l), 0n), sub_zero(len(l)))
    case 1n++p:
      match l:
        case Nil{}:
          {==}
        case Con{+x, +t}:
          len_drop(p, t)

# Perfect trees
# -------------

# The perfect tree of depth d over the first 2^d entries of l.
def build(+d: Nat, +l: List<&2, Nat>) -> Array<Nat>:
  match d:
    case 0n:
      ALeaf{nth(l, 0n)}
    case 1n+e:
      ANode{build(e, l), build(e, drop(Nat.pow(2n, e), l))}

def size_build(+d: Nat, +l: List<&2, Nat>) -> {(build(d, l), U32.shln(1, d)) == Array.size(Nat, build(d, l)) : Array<Nat> & U32}:
  match d:
    case 0n:
      {==}
    case 1n++e:
      %size_build(e, l) : {(build(1n+e, l), U32.shln(1, 1n+e)) == Array.size.node(Nat, build(e, drop(Nat.pow(2n, e), l)), _) : Array<Nat> & U32}
      {==}

def lesub2.h(+q: Nat, +n: Nat, +h: le(Nat.double(q), n)) -> le(Nat.add(q, q), n):
  %double_eq_add(q) : le(_, n)
  h

# A write at or above 2^e leaves the tree of depth e alone.
def build_upd_hi(+e: Nat, +l: List<&2, Nat>, +i: Nat, +v: Nat, +h: le(Nat.pow(2n, e), i)) -> {build(e, l) == build(e, upd(l, i, v)) : Array<Nat>}:
  match e:
    case 0n:
      %nth0_upd(l, i, v, h) : {build(0n, l) == ALeaf{_} : Array<Nat>}
      {==}
    case 1n++f:
      +hf = le_trans(Nat.pow(2n, f), Nat.double(Nat.pow(2n, f)), i, le_double(Nat.pow(2n, f)), le_p2s(i, f, h))
      +hr = lesub(Nat.pow(2n, f), Nat.pow(2n, f), i, lesub2.h(Nat.pow(2n, f), i, le_p2s(i, f, h)))
      %build_upd_hi(f, l, i, v, hf) : {build(1n+f, l) == ANode{_, build(f, drop(Nat.pow(2n, f), upd(l, i, v)))} : Array<Nat>}
      %drop_upd_hi(Nat.pow(2n, f), l, i, v, hf) : {build(1n+f, l) == ANode{build(f, l), build(f, _)} : Array<Nat>}
      %build_upd_hi(f, drop(Nat.pow(2n, f), l), Nat.sub(i, Nat.pow(2n, f)), v, hr) : {build(1n+f, l) == ANode{build(f, l), _} : Array<Nat>}
      {==}

def pre(d: Nat) -> Nat:
  match d:
    case 0n:
      0n
    case 1n+e:
      e

def lt0_le1(+n: Nat, +h: le(1n, n)) -> lt(0n, n):
  match n:
    case 0n:
      efq(lt(0n, 0n), ft(h))
    case 1n+q:
      {==}

def lt_add2(+v: Nat, +e: Nat, +h: lt(v, Nat.pow(2n, 1n+e))) -> lt(v, Nat.add(Nat.pow(2n, e), Nat.pow(2n, e))):
  %double_eq_add(Nat.pow(2n, e)) : lt(v, _)
  lt_p2s(v, e, h)

# The right half's index is below 2^e.
def hi_right(+x: U32, +e: Nat, +hle: le(Nat.pow(2n, e), U32.to_nat(x)), +hi: lt(U32.to_nat(x), Nat.pow(2n, 1n+e))) -> lt(U32.to_nat(U32.sub(x, U32.shln(1, e))), Nat.pow(2n, e)):
  %sub_r(x, e, hle, hi) : lt(_, Nat.pow(2n, e))
  sublt(Nat.pow(2n, e), U32.to_nat(x), Nat.pow(2n, e), hle, lt_add2(U32.to_nat(x), e, hi))

def hl_right(+e: Nat, +l: List<&2, Nat>, +hl: le(Nat.pow(2n, 1n+e), len(l))) -> le(Nat.pow(2n, e), len(drop(Nat.pow(2n, e), l))):
  %len_drop(Nat.pow(2n, e), l) : le(Nat.pow(2n, e), _)
  lesub(Nat.pow(2n, e), Nat.pow(2n, e), len(l), lesub2.h(Nat.pow(2n, e), len(l), le_p2s(len(l), e, hl)))

# get.go descends to leaf to_nat(x); b is the branch bit at the root.
def get_go(+d: Nat, +l: List<&2, Nat>, +x: U32, +h: lt(d, 32n), +hi: lt(U32.to_nat(x), Nat.pow(2n, d)), +b: Bool, +eb: {b == Nat.is_lt(U32.to_nat(x), Nat.pow(2n, pre(d))) : Bool}) -> {(build(d, l), nth(l, U32.to_nat(x))) == Array.get.go(Nat, build(d, l), U32.shln(1, d), x, U32.is_lt(x, U32.shr(U32.shln(1, d)))) : Array<Nat> & Nat}:
  match d:
    case 0n:
      %lt1_zero(U32.to_nat(x), hi) : {(build(0n, l), nth(l, _)) == (build(0n, l), nth(l, 0n)) : Array<Nat> & Nat}
      {==}
    case 1n++e:
      match b:
        case True{}:
          +hE = lt_pred(e, 32n, h)
          +hiL = Equal.sym(Bool, True{}, Nat.is_lt(U32.to_nat(x), Nat.pow(2n, e)), eb)
          %shr_shln_r(e, h) : {(build(1n+e, l), nth(l, U32.to_nat(x))) == Array.get.go(Nat, build(1n+e, l), U32.shln(1, 1n+e), x, U32.is_lt(x, _)) : Array<Nat> & Nat}
          %is_lt_r(x, e, hE) : {(build(1n+e, l), nth(l, U32.to_nat(x))) == Array.get.go(Nat, build(1n+e, l), U32.shln(1, 1n+e), x, _) : Array<Nat> & Nat}
          %eb : {(build(1n+e, l), nth(l, U32.to_nat(x))) == Array.get.go(Nat, build(1n+e, l), U32.shln(1, 1n+e), x, _) : Array<Nat> & Nat}
          %shr_shln_r(e, h) : {(build(1n+e, l), nth(l, U32.to_nat(x))) == Array.swap.lo(Nat, build(e, drop(Nat.pow(2n, e), l)), Array.get.go(Nat, build(e, l), _, x, U32.is_lt(x, U32.shr(_)))) : Array<Nat> & Nat}
          %get_go(e, l, x, hE, hiL, Nat.is_lt(U32.to_nat(x), Nat.pow(2n, pre(e))), {==}) : {(build(1n+e, l), nth(l, U32.to_nat(x))) == Array.swap.lo(Nat, build(e, drop(Nat.pow(2n, e), l)), _) : Array<Nat> & Nat}
          {==}
        case False{}:
          +hE = lt_pred(e, 32n, h)
          +hle = le_of_not_lt(U32.to_nat(x), Nat.pow(2n, e), Equal.sym(Bool, False{}, Nat.is_lt(U32.to_nat(x), Nat.pow(2n, e)), eb))
          %shr_shln_r(e, h) : {(build(1n+e, l), nth(l, U32.to_nat(x))) == Array.get.go(Nat, build(1n+e, l), U32.shln(1, 1n+e), x, U32.is_lt(x, _)) : Array<Nat> & Nat}
          %is_lt_r(x, e, hE) : {(build(1n+e, l), nth(l, U32.to_nat(x))) == Array.get.go(Nat, build(1n+e, l), U32.shln(1, 1n+e), x, _) : Array<Nat> & Nat}
          %eb : {(build(1n+e, l), nth(l, U32.to_nat(x))) == Array.get.go(Nat, build(1n+e, l), U32.shln(1, 1n+e), x, _) : Array<Nat> & Nat}
          %shr_shln_r(e, h) : {(build(1n+e, l), nth(l, U32.to_nat(x))) == Array.swap.hi(Nat, build(e, l), Array.get.go(Nat, build(e, drop(Nat.pow(2n, e), l)), _, U32.sub(x, _), U32.is_lt(U32.sub(x, _), U32.shr(_)))) : Array<Nat> & Nat}
          %get_go(e, drop(Nat.pow(2n, e), l), U32.sub(x, U32.shln(1, e)), hE, hi_right(x, e, hle, hi), Nat.is_lt(U32.to_nat(U32.sub(x, U32.shln(1, e))), Nat.pow(2n, pre(e))), {==}) : {(build(1n+e, l), nth(l, U32.to_nat(x))) == Array.swap.hi(Nat, build(e, l), _) : Array<Nat> & Nat}
          %sub_r(x, e, hle, hi) : {(build(1n+e, l), nth(l, U32.to_nat(x))) == (build(1n+e, l), nth(drop(Nat.pow(2n, e), l), _)) : Array<Nat> & Nat}
          %nth_drop(Nat.pow(2n, e), l, U32.to_nat(x), hle) : {(build(1n+e, l), nth(l, U32.to_nat(x))) == (build(1n+e, l), _) : Array<Nat> & Nat}
          {==}

def get_r(+d: Nat, +l: List<&2, Nat>, +x: U32, +h: lt(d, 32n), +hi: lt(U32.to_nat(x), Nat.pow(2n, d))) -> {(build(d, l), nth(l, U32.to_nat(x))) == Array.get(Nat, build(d, l), x) : Array<Nat> & Nat}:
  %size_build(d, l) : {(build(d, l), nth(l, U32.to_nat(x))) == Array.get.at(Nat, x, _) : Array<Nat> & Nat}
  %mask_r(x, d, h, hi) : {(build(d, l), nth(l, U32.to_nat(x))) == Array.get.go(Nat, build(d, l), U32.shln(1, d), _, U32.is_lt(_, U32.shr(U32.shln(1, d)))) : Array<Nat> & Nat}
  get_go(d, l, x, h, hi, Nat.is_lt(U32.to_nat(x), Nat.pow(2n, pre(d))), {==})

# Reading slot x of the perfect tree of depth d < 32 over l, for x < 2^d, keeps the tree and answers entry x of l.
law array_get_perfect:
  for +d: Nat
  for +l: List<&2, Nat>
  for +x: U32
  for +h: lt(d, 32n)
  for +hi: lt(U32.to_nat(x), Nat.pow(2n, d))
  {Array.get(Nat, build(d, l), x) == (build(d, l), nth(l, U32.to_nat(x))) : Array<Nat> & Nat}

def array_get_perfect(d, l, x, h, hi):
  Equal.sym(Array<Nat> & Nat, (build(d, l), nth(l, U32.to_nat(x))), Array.get(Nat, build(d, l), x), get_r(d, l, x, h, hi))

# swap.go replaces leaf to_nat(x); b is the branch bit at the root.
def set_go(+d: Nat, +l: List<&2, Nat>, +x: U32, +v: Nat, +h: lt(d, 32n), +hi: lt(U32.to_nat(x), Nat.pow(2n, d)), +hl: le(Nat.pow(2n, d), len(l)), +b: Bool, +eb: {b == Nat.is_lt(U32.to_nat(x), Nat.pow(2n, pre(d))) : Bool}) -> {(build(d, upd(l, U32.to_nat(x), v)), nth(l, U32.to_nat(x))) == Array.swap.go(Nat, build(d, l), U32.shln(1, d), x, v, U32.is_lt(x, U32.shr(U32.shln(1, d)))) : Array<Nat> & Nat}:
  match d:
    case 0n:
      %lt1_zero(U32.to_nat(x), hi) : {(ALeaf{nth(upd(l, _, v), 0n)}, nth(l, _)) == (ALeaf{v}, nth(l, 0n)) : Array<Nat> & Nat}
      %nth_upd_same(l, 0n, v, lt0_le1(len(l), hl)) : {(ALeaf{_}, nth(l, 0n)) == (ALeaf{v}, nth(l, 0n)) : Array<Nat> & Nat}
      {==}
    case 1n++e:
      match b:
        case True{}:
          +hE = lt_pred(e, 32n, h)
          +hiL = Equal.sym(Bool, True{}, Nat.is_lt(U32.to_nat(x), Nat.pow(2n, e)), eb)
          +hlL = le_trans(Nat.pow(2n, e), Nat.double(Nat.pow(2n, e)), len(l), le_double(Nat.pow(2n, e)), le_p2s(len(l), e, hl))
          %shr_shln_r(e, h) : {(build(1n+e, upd(l, U32.to_nat(x), v)), nth(l, U32.to_nat(x))) == Array.swap.go(Nat, build(1n+e, l), U32.shln(1, 1n+e), x, v, U32.is_lt(x, _)) : Array<Nat> & Nat}
          %is_lt_r(x, e, hE) : {(build(1n+e, upd(l, U32.to_nat(x), v)), nth(l, U32.to_nat(x))) == Array.swap.go(Nat, build(1n+e, l), U32.shln(1, 1n+e), x, v, _) : Array<Nat> & Nat}
          %eb : {(build(1n+e, upd(l, U32.to_nat(x), v)), nth(l, U32.to_nat(x))) == Array.swap.go(Nat, build(1n+e, l), U32.shln(1, 1n+e), x, v, _) : Array<Nat> & Nat}
          %shr_shln_r(e, h) : {(build(1n+e, upd(l, U32.to_nat(x), v)), nth(l, U32.to_nat(x))) == Array.swap.lo(Nat, build(e, drop(Nat.pow(2n, e), l)), Array.swap.go(Nat, build(e, l), _, x, v, U32.is_lt(x, U32.shr(_)))) : Array<Nat> & Nat}
          %set_go(e, l, x, v, hE, hiL, hlL, Nat.is_lt(U32.to_nat(x), Nat.pow(2n, pre(e))), {==}) : {(build(1n+e, upd(l, U32.to_nat(x), v)), nth(l, U32.to_nat(x))) == Array.swap.lo(Nat, build(e, drop(Nat.pow(2n, e), l)), _) : Array<Nat> & Nat}
          %drop_upd_lo(Nat.pow(2n, e), l, U32.to_nat(x), v, hiL) : {(ANode{build(e, upd(l, U32.to_nat(x), v)), build(e, _)}, nth(l, U32.to_nat(x))) == (ANode{build(e, upd(l, U32.to_nat(x), v)), build(e, drop(Nat.pow(2n, e), l))}, nth(l, U32.to_nat(x))) : Array<Nat> & Nat}
          {==}
        case False{}:
          +hE = lt_pred(e, 32n, h)
          +hle = le_of_not_lt(U32.to_nat(x), Nat.pow(2n, e), Equal.sym(Bool, False{}, Nat.is_lt(U32.to_nat(x), Nat.pow(2n, e)), eb))
          %shr_shln_r(e, h) : {(build(1n+e, upd(l, U32.to_nat(x), v)), nth(l, U32.to_nat(x))) == Array.swap.go(Nat, build(1n+e, l), U32.shln(1, 1n+e), x, v, U32.is_lt(x, _)) : Array<Nat> & Nat}
          %is_lt_r(x, e, hE) : {(build(1n+e, upd(l, U32.to_nat(x), v)), nth(l, U32.to_nat(x))) == Array.swap.go(Nat, build(1n+e, l), U32.shln(1, 1n+e), x, v, _) : Array<Nat> & Nat}
          %eb : {(build(1n+e, upd(l, U32.to_nat(x), v)), nth(l, U32.to_nat(x))) == Array.swap.go(Nat, build(1n+e, l), U32.shln(1, 1n+e), x, v, _) : Array<Nat> & Nat}
          %shr_shln_r(e, h) : {(build(1n+e, upd(l, U32.to_nat(x), v)), nth(l, U32.to_nat(x))) == Array.swap.hi(Nat, build(e, l), Array.swap.go(Nat, build(e, drop(Nat.pow(2n, e), l)), _, U32.sub(x, _), v, U32.is_lt(U32.sub(x, _), U32.shr(_)))) : Array<Nat> & Nat}
          %set_go(e, drop(Nat.pow(2n, e), l), U32.sub(x, U32.shln(1, e)), v, hE, hi_right(x, e, hle, hi), hl_right(e, l, hl), Nat.is_lt(U32.to_nat(U32.sub(x, U32.shln(1, e))), Nat.pow(2n, pre(e))), {==}) : {(build(1n+e, upd(l, U32.to_nat(x), v)), nth(l, U32.to_nat(x))) == Array.swap.hi(Nat, build(e, l), _) : Array<Nat> & Nat}
          %sub_r(x, e, hle, hi) : {(build(1n+e, upd(l, U32.to_nat(x), v)), nth(l, U32.to_nat(x))) == (ANode{build(e, l), build(e, upd(drop(Nat.pow(2n, e), l), _, v))}, nth(drop(Nat.pow(2n, e), l), _)) : Array<Nat> & Nat}
          %build_upd_hi(e, l, U32.to_nat(x), v, hle) : {(ANode{_, build(e, drop(Nat.pow(2n, e), upd(l, U32.to_nat(x), v)))}, nth(l, U32.to_nat(x))) == (ANode{build(e, l), build(e, upd(drop(Nat.pow(2n, e), l), Nat.sub(U32.to_nat(x), Nat.pow(2n, e)), v))}, nth(drop(Nat.pow(2n, e), l), Nat.sub(U32.to_nat(x), Nat.pow(2n, e)))) : Array<Nat> & Nat}
          %drop_upd_hi(Nat.pow(2n, e), l, U32.to_nat(x), v, hle) : {(ANode{build(e, l), build(e, _)}, nth(l, U32.to_nat(x))) == (ANode{build(e, l), build(e, upd(drop(Nat.pow(2n, e), l), Nat.sub(U32.to_nat(x), Nat.pow(2n, e)), v))}, nth(drop(Nat.pow(2n, e), l), Nat.sub(U32.to_nat(x), Nat.pow(2n, e)))) : Array<Nat> & Nat}
          %nth_drop(Nat.pow(2n, e), l, U32.to_nat(x), hle) : {(ANode{build(e, l), build(e, upd(drop(Nat.pow(2n, e), l), Nat.sub(U32.to_nat(x), Nat.pow(2n, e)), v))}, nth(l, U32.to_nat(x))) == (ANode{build(e, l), build(e, upd(drop(Nat.pow(2n, e), l), Nat.sub(U32.to_nat(x), Nat.pow(2n, e)), v))}, _) : Array<Nat> & Nat}
          {==}

def set_r(+d: Nat, +l: List<&2, Nat>, +x: U32, +v: Nat, +h: lt(d, 32n), +hi: lt(U32.to_nat(x), Nat.pow(2n, d)), +hl: le(Nat.pow(2n, d), len(l))) -> {build(d, upd(l, U32.to_nat(x), v)) == Array.set(Nat, build(d, l), x, v) : Array<Nat>}:
  %size_build(d, l) : {build(d, upd(l, U32.to_nat(x), v)) == Array.set.fin(Nat, Array.swap.at(Nat, x, v, _)) : Array<Nat>}
  %mask_r(x, d, h, hi) : {build(d, upd(l, U32.to_nat(x), v)) == Array.set.fin(Nat, Array.swap.go(Nat, build(d, l), U32.shln(1, d), _, v, U32.is_lt(_, U32.shr(U32.shln(1, d))))) : Array<Nat>}
  %set_go(d, l, x, v, h, hi, hl, Nat.is_lt(U32.to_nat(x), Nat.pow(2n, pre(d))), {==}) : {build(d, upd(l, U32.to_nat(x), v)) == Array.set.fin(Nat, _) : Array<Nat>}
  {==}

# Writing slot x of the perfect tree of depth d < 32 over l, for x < 2^d and 2^d entries, builds over l with entry x replaced.
law array_set_perfect:
  for +d: Nat
  for +l: List<&2, Nat>
  for +x: U32
  for +v: Nat
  for +h: lt(d, 32n)
  for +hi: lt(U32.to_nat(x), Nat.pow(2n, d))
  for +hl: le(Nat.pow(2n, d), len(l))
  {Array.set(Nat, build(d, l), x, v) == build(d, upd(l, U32.to_nat(x), v)) : Array<Nat>}

def array_set_perfect(d, l, x, v, h, hi, hl):
  Equal.sym(Array<Nat>, build(d, upd(l, U32.to_nat(x), v)), Array.set(Nat, build(d, l), x, v), set_r(d, l, x, v, h, hi, hl))

def sample() -> List<&2, Nat>:
  [10n, 20n, 30n, 40n]

# Slot 2 of the 4-slot tree over [10, 20, 30, 40] reads 30.
law main:
  {Array.get(Nat, build(2n, sample()), 2) == (build(2n, sample()), 30n) : Array<Nat> & Nat}

def main():
  array_get_perfect(2n, sample(), 2, {==}, {==})

#|{==}
