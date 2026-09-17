# A URL router matches a path (a list of Nat codes) against a glob:
# One{k} takes one code of class k, Many{k} takes any run of codes of
# class k. bt is the backtracking matcher; nfa runs the glob as an NFA,
# stepping a deduplicated set of live states; norm squashes a run of a
# run. Match is the spec, a type: the path fits the glob. LAWS: bt is
# sound and complete for Match, nfa and norm agree with bt, the live
# set is a set, and fitting a glob is decidable.

import Base

# a class of codes: any code, or the codes from lo to hi
type Cls is Data:
  Any{}
  Rng{lo: Nat, hi: Nat}

type Pat is Data:
  Fin{}
  One{k: Cls, p: Pat}
  Many{k: Cls, p: Pat}

def app(-A: Data, xs: List<&2, A>, ys: List<&2, A>) -> List<&2, A>:
  match xs:
    case Nil{}:
      ys
    case h <> t:
      h <> app(A, t, ys)

def hit(k: Cls, +c: Nat) -> Bool:
  match k:
    case Any{}:
      True{}
    case Rng{lo, hi}:
      Bool.and(Cmp.is_le(Nat.cmp(lo, c)), Cmp.is_le(Nat.cmp(c, hi)))

# the backtracking matcher
def bt(+p: Pat, +s: List<&2, Nat>) -> Bool:
  match p s:
    case Fin{} Nil{}:
      True{}
    case Fin{} c <> t:
      False{}
    case One{k, q} Nil{}:
      False{}
    case One{k, q} c <> t:
      Bool.and(hit(k, c), bt(q, t))
    case Many{k, q} Nil{}:
      bt(q, Nil{})
    case Many{k, q} c <> t:
      Bool.or(bt(q, c <> t), Bool.and(hit(k, c), bt(Many{k, q}, t)))

# the NFA: a state is a glob suffix; step moves one state on a code
def keep(b: Bool, p: Pat) -> List<&2, Pat>:
  match b:
    case True{}:
      [p]
    case False{}:
      Nil{}

def step(+p: Pat, +c: Nat) -> List<&2, Pat>:
  match p:
    case Fin{}:
      Nil{}
    case One{k, q}:
      keep(hit(k, c), q)
    case Many{k, q}:
      app(Pat, keep(hit(k, c), Many{k, q}), step(q, c))

def Cls.eq(a: Cls, b: Cls) -> Bool:
  match a b:
    case Any{} Any{}:
      True{}
    case Any{} Rng{c, d}:
      False{}
    case Rng{a, b} Any{}:
      False{}
    case Rng{a, b} Rng{c, d}:
      Bool.and(Cmp.is_eq(Nat.cmp(a, c)), Cmp.is_eq(Nat.cmp(b, d)))

def Pat.eq(a: Pat, b: Pat) -> Bool:
  match a b:
    case Fin{} Fin{}:
      True{}
    case Fin{} One{k, q}:
      False{}
    case Fin{} Many{k, q}:
      False{}
    case One{k, q} Fin{}:
      False{}
    case One{k, q} One{k2, q2}:
      Bool.and(Cls.eq(k, k2), Pat.eq(q, q2))
    case One{k, q} Many{k2, q2}:
      False{}
    case Many{k, q} Fin{}:
      False{}
    case Many{k, q} One{k2, q2}:
      False{}
    case Many{k, q} Many{k2, q2}:
      Bool.and(Cls.eq(k, k2), Pat.eq(q, q2))

def mem(+p: Pat, ps: List<&2, Pat>) -> Bool:
  match ps:
    case Nil{}:
      False{}
    case h <> t:
      Bool.or(Pat.eq(p, h), mem(p, t))

def pick(b: Bool, p: Pat, ps: List<&2, Pat>) -> List<&2, Pat>:
  match b:
    case True{}:
      ps
    case False{}:
      p <> ps

# the live set is a set: a state already present is dropped
def dedup(ps: List<&2, Pat>) -> List<&2, Pat>:
  match ps:
    case Nil{}:
      Nil{}
    case +p <> +r:
      pick(mem(p, r), p, dedup(r))

def nullable(p: Pat) -> Bool:
  match p:
    case Fin{}:
      True{}
    case One{k, q}:
      False{}
    case Many{k, q}:
      nullable(q)

def nulls(ps: List<&2, Pat>) -> Bool:
  match ps:
    case Nil{}:
      False{}
    case p <> r:
      Bool.or(nullable(p), nulls(r))

def moves(ps: List<&2, Pat>, +c: Nat) -> List<&2, Pat>:
  match ps:
    case Nil{}:
      Nil{}
    case p <> r:
      app(Pat, step(p, c), moves(r, c))

def sim(s: List<&2, Nat>, ps: List<&2, Pat>) -> Bool:
  match s:
    case Nil{}:
      nulls(ps)
    case c <> t:
      sim(t, dedup(moves(ps, c)))

def nfa(p: Pat, s: List<&2, Nat>) -> Bool:
  sim(s, [p])

# LE(a, b): a <= b, as a type
def LE(a: Nat, b: Nat) -> Data:
  match a b:
    case 0n b:
      Unit
    case 1n+a 0n:
      Empty
    case 1n+a 1n+b:
      LE(a, b)

# In(k, c): the code c belongs to the class k
def In(k: Cls, c: Nat) -> Type:
  match k:
    case Any{}:
      Unit
    case Rng{lo, hi}:
      LE(lo, c) & LE(c, hi)

# All(k, u): every code of u belongs to k
def All(k: Cls, u: List<&2, Nat>) -> Type:
  match u:
    case Nil{}:
      Unit
    case c <> t:
      In(k, c) & All(k, t)

# Match(p, s): the path s fits the glob p; Many{k, q} takes a run u of
# class k, then q takes the rest v
def Match(+p: Pat, +s: List<&2, Nat>) -> Type:
  match p s:
    case Fin{} Nil{}:
      Unit
    case Fin{} c <> t:
      Empty
    case One{k, q} Nil{}:
      Empty
    case One{k, q} c <> t:
      In(k, c) & Match(q, t)
    case Many{k, q} s:
      Exists(List<&2, Nat>, u => Exists(List<&2, Nat>, v => {s == app(Nat, u, v) : List<&2, Nat>} & All(k, u) & Match(q, v)))

# LAW: when bt says True, the path fits the glob
law bt_sound:
  for +p: Pat
  for +s: List<&2, Nat>
  for e: {True{} == bt(p, s) : Bool}
  Match(p, s)

# LAW: when the path fits the glob, bt says True
law bt_complete:
  for +p: Pat
  for +s: List<&2, Nat>
  for m: Match(p, s)
  {True{} == bt(p, s) : Bool}

# LAW: the NFA simulation agrees with the backtracking matcher
law nfa_bt:
  for +p: Pat
  for +s: List<&2, Nat>
  {nfa(p, s) == bt(p, s) : Bool}

# the normalizer: two runs of one class in a row are one run
def merge(b: Bool, k: Cls, k2: Cls, q: Pat) -> Pat:
  match b:
    case True{}:
      Many{k2, q}
    case False{}:
      Many{k, Many{k2, q}}

def squash(+k: Cls, +p: Pat) -> Pat:
  match p:
    case Fin{}:
      Many{k, Fin{}}
    case One{k2, q}:
      Many{k, One{k2, q}}
    case Many{k2, q}:
      merge(Cls.eq(k, k2), k, k2, q)

def norm(p: Pat) -> Pat:
  match p:
    case Fin{}:
      Fin{}
    case One{k, q}:
      One{k, norm(q)}
    case Many{k, q}:
      squash(k, norm(q))

# LAW: the normalizer keeps the language
law norm_bt:
  for +p: Pat
  for +s: List<&2, Nat>
  {bt(norm(p), s) == bt(p, s) : Bool}

# Nodup(ps): no state appears twice
def Nodup(ps: List<&2, Pat>) -> Type:
  match ps:
    case Nil{}:
      Unit
    case +p <> +r:
      {False{} == mem(p, r) : Bool} & Nodup(r)

# LAW: the live set is a set: dedup drops every repeated state
law dedup_nodup:
  for +ps: List<&2, Pat>
  Nodup(dedup(ps))

# LAW: dedup is idempotent
law dedup_idem:
  for +ps: List<&2, Pat>
  {dedup(dedup(ps)) == dedup(ps) : List<&2, Pat>}

# LAW: fitting a glob is decidable
law match_dec:
  for +p: Pat
  for +s: List<&2, Nat>
  Or(Match(p, s), Match(p, s) -> Empty)

# LAW: a state finds itself in a set that holds it
law mem_self:
  for +p: Pat
  for +ps: List<&2, Pat>
  {True{} == mem(p, p <> ps) : Bool}

# LAW: a live set accepts what any of its states accepts
law sim_mem:
  for +ps: List<&2, Pat>
  for +p: Pat
  for +s: List<&2, Nat>
  for e: {True{} == mem(p, ps) : Bool}
  for b: {True{} == bt(p, s) : Bool}
  {True{} == sim(s, ps) : Bool}

# LAW: so the NFA is sound and complete for the spec too
law nfa_sound:
  for +p: Pat
  for +s: List<&2, Nat>
  for e: {True{} == nfa(p, s) : Bool}
  Match(p, s)

law nfa_complete:
  for +p: Pat
  for +s: List<&2, Nat>
  for m: Match(p, s)
  {True{} == nfa(p, s) : Bool}

# solution

# Bool
# ----

# True == False proves anything: the rewrite turns the goal into Unit
def clash.at(A: Type, b: Bool) -> Type:
  match b:
    case True{}:
      Unit
    case False{}:
      A

def clash(-A: Type, e: {True{} == False{} : Bool}) -> A:
  %e : clash.at(A, _)
  Unit{}

def and_l(a: Bool, -b: Bool, e: {True{} == Bool.and(a, b) : Bool}) -> {True{} == a : Bool}:
  match a:
    case True{}:
      {==}
    case False{}:
      e

def and_r(a: Bool, b: Bool, e: {True{} == Bool.and(a, b) : Bool}) -> {True{} == b : Bool}:
  match a:
    case True{}:
      e
    case False{}:
      clash({True{} == b : Bool}, e)

def or_true_l(a: Bool, -b: Bool, e: {True{} == a : Bool}) -> {True{} == Bool.or(a, b) : Bool}:
  %e : {True{} == Bool.or(_, b) : Bool}
  {==}

def or_false(a: Bool) -> {Bool.or(a, False{}) == a : Bool}:
  match a:
    case True{}:
      {==}
    case False{}:
      {==}

def or_comm(a: Bool, b: Bool) -> {Bool.or(a, b) == Bool.or(b, a) : Bool}:
  match a b:
    case True{} True{}:
      {==}
    case True{} False{}:
      {==}
    case False{} True{}:
      {==}
    case False{} False{}:
      {==}

def or_assoc(a: Bool, -b: Bool, -c: Bool) -> {Bool.or(Bool.or(a, b), c) == Bool.or(a, Bool.or(b, c)) : Bool}:
  match a:
    case True{}:
      {==}
    case False{}:
      {==}

def or_absorb(a: Bool, -b: Bool) -> {Bool.or(a, Bool.or(a, b)) == Bool.or(a, b) : Bool}:
  match a:
    case True{}:
      {==}
    case False{}:
      {==}

def or_cong(a: Bool, a2: Bool, b: Bool, b2: Bool, ea: {a == a2 : Bool}, eb: {b == b2 : Bool}) -> {Bool.or(a, b) == Bool.or(a2, b2) : Bool}:
  %ea : {Bool.or(a, b) == Bool.or(_, b2) : Bool}
  %eb : {Bool.or(a, b) == Bool.or(a, _) : Bool}
  {==}

def or_cong_c(a: Bool, a2: Bool, b: Bool, b2: Bool, ea: {a == b2 : Bool}, eb: {b == a2 : Bool}) -> {Bool.or(a, b) == Bool.or(a2, b2) : Bool}:
  %ea : {Bool.or(a, b) == Bool.or(a2, _) : Bool}
  %eb : {Bool.or(a, b) == Bool.or(_, a) : Bool}
  or_comm(a, b)

def or_swap(a: Bool, b: Bool, -c: Bool) -> {Bool.or(a, Bool.or(b, c)) == Bool.or(b, Bool.or(a, c)) : Bool}:
  match a b:
    case True{} True{}:
      {==}
    case True{} False{}:
      {==}
    case False{} True{}:
      {==}
    case False{} False{}:
      {==}

# Classes
# -------

def cmp_eq(x: Nat, c: Nat, e: {True{} == Cmp.is_eq(Nat.cmp(x, c)) : Bool}) -> {c == x : Nat}:
  match x c:
    case 0n 0n:
      {==}
    case 0n 1n+b:
      clash({1n+b == 0n : Nat}, e)
    case 1n+a 0n:
      clash({0n == 1n+a : Nat}, e)
    case 1n+a 1n+b:
      %cmp_eq(a, b, e) : {1n+b == 1n+_ : Nat}
      {==}

def le_sound(a: Nat, b: Nat, e: {True{} == Cmp.is_le(Nat.cmp(a, b)) : Bool}) -> LE(a, b):
  match a b:
    case 0n b:
      Unit{}
    case 1n+a 0n:
      clash(Empty, e)
    case 1n+a 1n+b:
      le_sound(a, b, e)

def le_complete(a: Nat, b: Nat, l: LE(a, b)) -> {True{} == Cmp.is_le(Nat.cmp(a, b)) : Bool}:
  match a b:
    case 0n 0n:
      {==}
    case 0n 1n+b:
      {==}
    case 1n+a 0n:
      match l:
    case 1n+a 1n+b:
      le_complete(a, b, l)

def hit_in(+k: Cls, +c: Nat, +e: {True{} == hit(k, c) : Bool}) -> In(k, c):
  match k:
    case Any{}:
      Unit{}
    case Rng{lo, hi}:
      (le_sound(lo, c, and_l(Cmp.is_le(Nat.cmp(lo, c)), Cmp.is_le(Nat.cmp(c, hi)), e)), le_sound(c, hi, and_r(Cmp.is_le(Nat.cmp(lo, c)), Cmp.is_le(Nat.cmp(c, hi)), e)))

def in_hit(+k: Cls, +c: Nat, i: In(k, c)) -> {True{} == hit(k, c) : Bool}:
  match k:
    case Any{}:
      {==}
    case Rng{lo, hi}:
      (l1, l2) = i
      %le_complete(lo, c, l1) : {True{} == Bool.and(_, Cmp.is_le(Nat.cmp(c, hi))) : Bool}
      %le_complete(c, hi, l2) : {True{} == Bool.and(True{}, _) : Bool}
      {==}

# Soundness
# ---------

# a run u of class k grows by the code c
def bt_sound.push(k: Cls, c: Nat, -q: Pat, -t: List<&2, Nat>, i: In(k, c), m: Match(Many{k, q}, t)) -> Match(Many{k, q}, c <> t):
  (u, m1) = m
  (v, m2) = m1
  (eq, m3) = m2
  (al, mq) = m3
  (c <> u, (v, (Equal.cong(List<&2, Nat>, List<&2, Nat>, x => c <> x, t, app(Nat, u, v), eq), ((i, al), mq))))

def bt_sound.many(+k: Cls, +c: Nat, +q: Pat, +t: List<&2, Nat>, b: Bool, eb: {b == bt(q, c <> t) : Bool}, +e: {True{} == Bool.or(b, Bool.and(hit(k, c), bt(Many{k, q}, t))) : Bool}, rq: {True{} == bt(q, c <> t) : Bool} -> Match(q, c <> t), rm: {True{} == bt(Many{k, q}, t) : Bool} -> Match(Many{k, q}, t)) -> Match(Many{k, q}, c <> t):
  match b:
    case True{}:
      (Nil{}, (c <> t, ({==}, (Unit{}, rq(eb)))))
    case False{}:
      bt_sound.push(k, c, q, t, hit_in(k, c, and_l(hit(k, c), bt(Many{k, q}, t), e)), rm(and_r(hit(k, c), bt(Many{k, q}, t), e)))

def bt_sound(p, s, e):
  match p s:
    case Fin{} Nil{}:
      Unit{}
    case Fin{} c <> t:
      clash(Empty, e)
    case One{k, q} Nil{}:
      clash(Empty, e)
    case One{k, q} c <> t:
      +e2 = e
      (hit_in(k, c, and_l(hit(k, c), bt(q, t), e2)), bt_sound(q, t, and_r(hit(k, c), bt(q, t), e2)))
    case Many{k, q} Nil{}:
      (Nil{}, (Nil{}, ({==}, (Unit{}, bt_sound(q, Nil{}, e)))))
    case Many{k, q} c <> t:
      bt_sound.many(k, c, q, t, bt(q, c <> t), {==}, e, bt_sound(q, c <> t), bt_sound(Many{k, q}, t))

# Completeness
# ------------

# q takes v: Many{k, q} takes v with an empty run
def bt_complete.rest(+k: Cls, +q: Pat, v: List<&2, Nat>, r: {True{} == bt(q, v) : Bool}) -> {True{} == bt(Many{k, q}, v) : Bool}:
  match v:
    case Nil{}:
      r
    case c <> t:
      or_true_l(bt(q, c <> t), Bool.and(hit(k, c), bt(Many{k, q}, t)), r)

def or_and_intro(a: Bool, h: Bool, -b: Bool, eh: {True{} == h : Bool}, eb: {True{} == b : Bool}) -> {True{} == Bool.or(a, Bool.and(h, b)) : Bool}:
  match a:
    case True{}:
      {==}
    case False{}:
      %eh : {True{} == Bool.and(_, b) : Bool}
      eb

# a run u of class k followed by v is taken by Many{k, q}
def bt_complete.run(+k: Cls, +q: Pat, +u: List<&2, Nat>, +v: List<&2, Nat>, al: All(k, u), r: {True{} == bt(q, v) : Bool}) -> {True{} == bt(Many{k, q}, app(Nat, u, v)) : Bool}:
  match u:
    case Nil{}:
      bt_complete.rest(k, q, v, r)
    case c <> t:
      (i, at) = al
      or_and_intro(bt(q, c <> app(Nat, t, v)), hit(k, c), bt(Many{k, q}, app(Nat, t, v)), in_hit(k, c, i), bt_complete.run(k, q, t, v, at, r))

def bt_complete(p, s, m):
  match p s:
    case Fin{} Nil{}:
      {==}
    case Fin{} c <> t:
      match m:
    case One{k, q} Nil{}:
      match m:
    case One{k, q} c <> t:
      (i, mq) = m
      %in_hit(k, c, i) : {True{} == Bool.and(_, bt(q, t)) : Bool}
      %bt_complete(q, t, mq) : {True{} == Bool.and(True{}, _) : Bool}
      {==}
    case Many{k, q} s:
      (+u, m1) = m
      (+v, m2) = m1
      (eq, m3) = m2
      (al, mq) = m3
      %Equal.sym(List<&2, Nat>, s, app(Nat, u, v), eq) : {True{} == bt(Many{k, q}, _) : Bool}
      bt_complete.run(k, q, u, v, al, bt_complete(q, v, mq))

# NFA simulation
# --------------

# anybt(ps, s): some live state takes s by backtracking
def anybt(ps: List<&2, Pat>, +s: List<&2, Nat>) -> Bool:
  match ps:
    case Nil{}:
      False{}
    case p <> r:
      Bool.or(bt(p, s), anybt(r, s))

def bt_nil(p: Pat) -> {bt(p, Nil{}) == nullable(p) : Bool}:
  match p:
    case Fin{}:
      {==}
    case One{k, q}:
      {==}
    case Many{k, q}:
      bt_nil(q)

def anybt_nil(ps: List<&2, Pat>) -> {anybt(ps, Nil{}) == nulls(ps) : Bool}:
  match ps:
    case Nil{}:
      {==}
    case +p <> +r:
      or_cong(bt(p, Nil{}), nullable(p), anybt(r, Nil{}), nulls(r), bt_nil(p), anybt_nil(r))

def anybt_app(xs: List<&2, Pat>, +ys: List<&2, Pat>, +s: List<&2, Nat>) -> {Bool.or(anybt(xs, s), anybt(ys, s)) == anybt(app(Pat, xs, ys), s) : Bool}:
  match xs:
    case Nil{}:
      {==}
    case p <> r:
      %anybt_app(r, ys, s) : {Bool.or(Bool.or(bt(p, s), anybt(r, s)), anybt(ys, s)) == Bool.or(bt(p, s), _) : Bool}
      or_assoc(bt(p, s), anybt(r, s), anybt(ys, s))

def keep_bt(b: Bool, +p: Pat, +t: List<&2, Nat>) -> {anybt(keep(b, p), t) == Bool.and(b, bt(p, t)) : Bool}:
  match b:
    case True{}:
      or_false(bt(p, t))
    case False{}:
      {==}

# one NFA step on c, then t, is bt on c <> t
def bt_step(+p: Pat, +c: Nat, +t: List<&2, Nat>) -> {anybt(step(p, c), t) == bt(p, c <> t) : Bool}:
  match p:
    case Fin{}:
      {==}
    case One{k, q}:
      keep_bt(hit(k, c), q, t)
    case Many{k, q}:
      %anybt_app(keep(hit(k, c), Many{k, q}), step(q, c), t) : {_ == Bool.or(bt(q, c <> t), Bool.and(hit(k, c), bt(Many{k, q}, t))) : Bool}
      or_cong_c(anybt(keep(hit(k, c), Many{k, q}), t), bt(q, c <> t), anybt(step(q, c), t), Bool.and(hit(k, c), bt(Many{k, q}, t)), keep_bt(hit(k, c), Many{k, q}, t), bt_step(q, c, t))

def anybt_step(+ps: List<&2, Pat>, +c: Nat, +t: List<&2, Nat>) -> {anybt(moves(ps, c), t) == anybt(ps, c <> t) : Bool}:
  match ps:
    case Nil{}:
      {==}
    case p <> r:
      %anybt_app(step(p, c), moves(r, c), t) : {_ == Bool.or(bt(p, c <> t), anybt(r, c <> t)) : Bool}
      or_cong(anybt(step(p, c), t), bt(p, c <> t), anybt(moves(r, c), t), anybt(r, c <> t), bt_step(p, c, t), anybt_step(r, c, t))

# Equality of states
# ------------------

def cls_sound(+a: Cls, +b: Cls, +e: {True{} == Cls.eq(a, b) : Bool}) -> {b == a : Cls}:
  match a b:
    case Any{} Any{}:
      {==}
    case Any{} Rng{c, d}:
      clash({Rng{c, d} == Any{} : Cls}, e)
    case Rng{a, b} Any{}:
      clash({Any{} == Rng{a, b} : Cls}, e)
    case Rng{a, b} Rng{c, d}:
      %cmp_eq(a, c, and_l(Cmp.is_eq(Nat.cmp(a, c)), Cmp.is_eq(Nat.cmp(b, d)), e)) : {Rng{c, d} == Rng{_, b} : Cls}
      %cmp_eq(b, d, and_r(Cmp.is_eq(Nat.cmp(a, c)), Cmp.is_eq(Nat.cmp(b, d)), e)) : {Rng{c, d} == Rng{c, _} : Cls}
      {==}

def eq_sound(+a: Pat, +b: Pat, +e: {True{} == Pat.eq(a, b) : Bool}) -> {b == a : Pat}:
  match a b:
    case Fin{} Fin{}:
      {==}
    case Fin{} One{k, q}:
      clash({One{k, q} == Fin{} : Pat}, e)
    case Fin{} Many{k, q}:
      clash({Many{k, q} == Fin{} : Pat}, e)
    case One{k, q} Fin{}:
      clash({Fin{} == One{k, q} : Pat}, e)
    case One{k, q} One{k2, q2}:
      %cls_sound(k, k2, and_l(Cls.eq(k, k2), Pat.eq(q, q2), e)) : {One{k2, q2} == One{_, q} : Pat}
      %eq_sound(q, q2, and_r(Cls.eq(k, k2), Pat.eq(q, q2), e)) : {One{k2, q2} == One{k2, _} : Pat}
      {==}
    case One{k, q} Many{k2, q2}:
      clash({Many{k2, q2} == One{k, q} : Pat}, e)
    case Many{k, q} Fin{}:
      clash({Fin{} == Many{k, q} : Pat}, e)
    case Many{k, q} One{k2, q2}:
      clash({One{k2, q2} == Many{k, q} : Pat}, e)
    case Many{k, q} Many{k2, q2}:
      %cls_sound(k, k2, and_l(Cls.eq(k, k2), Pat.eq(q, q2), e)) : {Many{k2, q2} == Many{_, q} : Pat}
      %eq_sound(q, q2, and_r(Cls.eq(k, k2), Pat.eq(q, q2), e)) : {Many{k2, q2} == Many{k2, _} : Pat}
      {==}

def cmp_refl(x: Nat) -> {True{} == Cmp.is_eq(Nat.cmp(x, x)) : Bool}:
  match x:
    case 0n:
      {==}
    case 1n+a:
      cmp_refl(a)

def cls_refl(k: Cls) -> {True{} == Cls.eq(k, k) : Bool}:
  match k:
    case Any{}:
      {==}
    case Rng{+a, +b}:
      %cmp_refl(a) : {True{} == Bool.and(_, Cmp.is_eq(Nat.cmp(b, b))) : Bool}
      cmp_refl(b)

def eq_refl(p: Pat) -> {True{} == Pat.eq(p, p) : Bool}:
  match p:
    case Fin{}:
      {==}
    case One{+k, +q}:
      %cls_refl(k) : {True{} == Bool.and(_, Pat.eq(q, q)) : Bool}
      eq_refl(q)
    case Many{+k, +q}:
      %cls_refl(k) : {True{} == Bool.and(_, Pat.eq(q, q)) : Bool}
      eq_refl(q)

def mem_self(p, ps):
  or_true_l(Pat.eq(p, p), mem(p, ps), eq_refl(p))

# Dedup
# -----

# a state already in the set adds nothing to anybt
def mem_bt.go(+p: Pat, +h: Pat, +t: List<&2, Pat>, +s: List<&2, Nat>, b: Bool, eb: {b == Pat.eq(p, h) : Bool}, e: {True{} == Bool.or(b, mem(p, t)) : Bool}, rec: {True{} == mem(p, t) : Bool} -> {Bool.or(bt(p, s), anybt(t, s)) == anybt(t, s) : Bool}) -> {Bool.or(bt(p, s), Bool.or(bt(h, s), anybt(t, s))) == Bool.or(bt(h, s), anybt(t, s)) : Bool}:
  match b:
    case True{}:
      %eq_sound(p, h, eb) : {Bool.or(bt(_, s), Bool.or(bt(h, s), anybt(t, s))) == Bool.or(bt(h, s), anybt(t, s)) : Bool}
      or_absorb(bt(h, s), anybt(t, s))
    case False{}:
      %rec(e) : {Bool.or(bt(p, s), Bool.or(bt(h, s), anybt(t, s))) == Bool.or(bt(h, s), _) : Bool}
      or_swap(bt(p, s), bt(h, s), anybt(t, s))

def mem_bt(+p: Pat, ps: List<&2, Pat>, +s: List<&2, Nat>, e: {True{} == mem(p, ps) : Bool}) -> {Bool.or(bt(p, s), anybt(ps, s)) == anybt(ps, s) : Bool}:
  match ps:
    case Nil{}:
      clash({Bool.or(bt(p, s), False{}) == False{} : Bool}, e)
    case +h <> +t:
      mem_bt.go(p, h, t, s, Pat.eq(p, h), {==}, e, mem_bt(p, t, s))

def anybt_dedup.go(b: Bool, +p: Pat, +r: List<&2, Pat>, +s: List<&2, Nat>, e: {b == mem(p, r) : Bool}, rec: {anybt(r, s) == anybt(dedup(r), s) : Bool}) -> {Bool.or(bt(p, s), anybt(r, s)) == anybt(pick(b, p, dedup(r)), s) : Bool}:
  match b:
    case True{}:
      %rec : {Bool.or(bt(p, s), anybt(r, s)) == _ : Bool}
      mem_bt(p, r, s, e)
    case False{}:
      %rec : {Bool.or(bt(p, s), anybt(r, s)) == Bool.or(bt(p, s), _) : Bool}
      {==}

def anybt_dedup(ps: List<&2, Pat>, +s: List<&2, Nat>) -> {anybt(ps, s) == anybt(dedup(ps), s) : Bool}:
  match ps:
    case Nil{}:
      {==}
    case +p <> +r:
      anybt_dedup.go(mem(p, r), p, r, s, {==}, anybt_dedup(r, s))

# dedup keeps membership: p is in dedup(r) exactly when p is in r
def mem_dedup.go(b: Bool, c: Bool, +p: Pat, +h: Pat, +t: List<&2, Pat>, e: {b == mem(h, t) : Bool}, ec: {c == Pat.eq(p, h) : Bool}, rec: {mem(p, t) == mem(p, dedup(t)) : Bool}) -> {Bool.or(c, mem(p, t)) == mem(p, pick(b, h, dedup(t))) : Bool}:
  match b c:
    case True{} True{}:
      %rec : {True{} == _ : Bool}
      %eq_sound(p, h, ec) : {True{} == mem(_, t) : Bool}
      e
    case True{} False{}:
      rec
    case False{} c:
      or_cong(c, Pat.eq(p, h), mem(p, t), mem(p, dedup(t)), ec, rec)

def mem_dedup(+p: Pat, r: List<&2, Pat>) -> {mem(p, r) == mem(p, dedup(r)) : Bool}:
  match r:
    case Nil{}:
      {==}
    case +h <> +t:
      mem_dedup.go(mem(h, t), Pat.eq(p, h), p, h, t, {==}, {==}, mem_dedup(p, t))

def dedup_nodup.go(b: Bool, +p: Pat, +r: List<&2, Pat>, e: {b == mem(p, r) : Bool}, rec: Nodup(dedup(r))) -> Nodup(pick(b, p, dedup(r))):
  match b:
    case True{}:
      rec
    case False{}:
      %mem_dedup(p, r) : {False{} == _ : Bool} & Nodup(dedup(r))
      (e, rec)

def dedup_nodup(ps):
  match ps:
    case Nil{}:
      Unit{}
    case +p <> +r:
      dedup_nodup.go(mem(p, r), p, r, {==}, dedup_nodup(r))

# Normalizer
# ----------

def or_absorb_r(a: Bool, b: Bool) -> {Bool.or(Bool.or(a, b), b) == Bool.or(a, b) : Bool}:
  match a b:
    case True{} True{}:
      {==}
    case True{} False{}:
      {==}
    case False{} True{}:
      {==}
    case False{} False{}:
      {==}

def star_step(a: Bool, h: Bool, y: Bool, y2: Bool, e: {y == y2 : Bool}) -> {Bool.or(Bool.or(a, Bool.and(h, y2)), Bool.and(h, y)) == Bool.or(a, Bool.and(h, y2)) : Bool}:
  %e : {Bool.or(Bool.or(a, Bool.and(h, _)), Bool.and(h, y)) == Bool.or(a, Bool.and(h, _)) : Bool}
  or_absorb_r(a, Bool.and(h, y))

# a run of a run is one run, by induction on s
def star_star(+k: Cls, +q: Pat, +s: List<&2, Nat>) -> {bt(Many{k, Many{k, q}}, s) == bt(Many{k, q}, s) : Bool}:
  match s:
    case Nil{}:
      {==}
    case c <> t:
      star_step(bt(q, c <> t), hit(k, c), bt(Many{k, Many{k, q}}, t), bt(Many{k, q}, t), star_star(k, q, t))

def squash_bt.go(b: Bool, +k: Cls, +k2: Cls, +q: Pat, +s: List<&2, Nat>, e: {b == Cls.eq(k, k2) : Bool}) -> {bt(Many{k, Many{k2, q}}, s) == bt(merge(b, k, k2, q), s) : Bool}:
  match b:
    case True{}:
      %cls_sound(k, k2, e) : {bt(Many{_, Many{k2, q}}, s) == bt(Many{k2, q}, s) : Bool}
      star_star(k2, q, s)
    case False{}:
      {==}

def squash_bt(+k: Cls, p: Pat, +s: List<&2, Nat>) -> {bt(Many{k, p}, s) == bt(squash(k, p), s) : Bool}:
  match p:
    case Fin{}:
      {==}
    case One{k2, q}:
      {==}
    case Many{+k2, +q}:
      squash_bt.go(Cls.eq(k, k2), k, k2, q, s, {==})

def or_and_cong(a: Bool, a2: Bool, h: Bool, b: Bool, b2: Bool, ea: {a == a2 : Bool}, eb: {b == b2 : Bool}) -> {Bool.or(a, Bool.and(h, b)) == Bool.or(a2, Bool.and(h, b2)) : Bool}:
  %ea : {Bool.or(a, Bool.and(h, b)) == Bool.or(_, Bool.and(h, b2)) : Bool}
  %eb : {Bool.or(a, Bool.and(h, b)) == Bool.or(a, Bool.and(h, _)) : Bool}
  {==}

def norm_many(+k: Cls, +q: Pat, +t: List<&2, Nat>, e: {bt(squash(k, norm(q)), t) == bt(Many{k, q}, t) : Bool}) -> {bt(Many{k, norm(q)}, t) == bt(Many{k, q}, t) : Bool}:
  %e : {bt(Many{k, norm(q)}, t) == _ : Bool}
  squash_bt(k, norm(q), t)

def norm_bt(p, s):
  match p s:
    case Fin{} s:
      {==}
    case One{k, q} Nil{}:
      {==}
    case One{k, q} c <> t:
      %norm_bt(q, t) : {Bool.and(hit(k, c), bt(norm(q), t)) == Bool.and(hit(k, c), _) : Bool}
      {==}
    case Many{k, q} Nil{}:
      %squash_bt(k, norm(q), Nil{}) : {_ == bt(Many{k, q}, Nil{}) : Bool}
      norm_bt(q, Nil{})
    case Many{k, q} c <> t:
      %squash_bt(k, norm(q), c <> t) : {_ == bt(Many{k, q}, c <> t) : Bool}
      or_and_cong(bt(norm(q), c <> t), bt(q, c <> t), hit(k, c), bt(Many{k, norm(q)}, t), bt(Many{k, q}, t), norm_bt(q, c <> t), norm_many(k, q, t, norm_bt(Many{k, q}, t)))

# a set with no repeats is fixed by dedup
def nodup_fixed(ps: List<&2, Pat>, n: Nodup(ps)) -> {dedup(ps) == ps : List<&2, Pat>}:
  match ps:
    case Nil{}:
      {==}
    case +p <> +r:
      (e, nr) = n
      %e : {pick(_, p, dedup(r)) == p <> r : List<&2, Pat>}
      %nodup_fixed(r, nr) : {p <> dedup(r) == p <> _ : List<&2, Pat>}
      {==}

def dedup_idem(ps):
  nodup_fixed(dedup(ps), dedup_nodup(ps))

def match_dec.go(+p: Pat, +s: List<&2, Nat>, b: Bool, e: {b == bt(p, s) : Bool}) -> Or(Match(p, s), Match(p, s) -> Empty):
  match b:
    case True{}:
      Inl{bt_sound(p, s, e)}
    case False{}:
      Inr{m => clash(Empty, Equal.trans(Bool, True{}, bt(p, s), False{}, bt_complete(p, s, m), Equal.sym(Bool, False{}, bt(p, s), e)))}

def match_dec(p, s):
  match_dec.go(p, s, bt(p, s), {==})

# the simulation from any live set agrees with anybt, by induction on s
def sim_any(+s: List<&2, Nat>, +ps: List<&2, Pat>) -> {anybt(ps, s) == sim(s, ps) : Bool}:
  match s:
    case Nil{}:
      anybt_nil(ps)
    case c <> t:
      %anybt_step(ps, c, t) : {_ == sim(t, dedup(moves(ps, c))) : Bool}
      %sim_any(t, dedup(moves(ps, c))) : {anybt(moves(ps, c), t) == _ : Bool}
      anybt_dedup(moves(ps, c), t)

def nfa_bt(p, s):
  %sim_any(s, [p]) : {_ == bt(p, s) : Bool}
  or_false(bt(p, s))

def nfa_sound(p, s, e):
  bt_sound(p, s, Equal.trans(Bool, True{}, nfa(p, s), bt(p, s), e, nfa_bt(p, s)))

def nfa_complete(p, s, m):
  %sim_any(s, [p]) : {True{} == _ : Bool}
  or_true_l(bt(p, s), False{}, bt_complete(p, s, m))

def sim_mem(ps, p, s, e, b):
  %sim_any(s, ps) : {True{} == _ : Bool}
  %mem_bt(p, ps, s, e) : {True{} == _ : Bool}
  or_true_l(bt(p, s), anybt(ps, s), b)
