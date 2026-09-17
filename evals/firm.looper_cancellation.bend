# A street musician's live looper records toggle cues at natural timestamps.
# Adjacent copies of the same cue cancel; different cues do not commute.
# Return a reduced cue sequence with exactly the same action on every reduced
# suffix, and prove that this canonical representative is unique.
import Base

def same(a: Nat, b: Nat) -> Bool:
  match a b:
    case 0n 0n:
      True{}
    case 0n 1n+q:
      False{}
    case 1n+p 0n:
      False{}
    case 1n+p 1n+q:
      same(p, q)

def choose(x: Nat, h: Nat, t: +List<Nat>, b: Bool) -> +List<Nat>:
  match b:
    case True{}:
      t
    case False{}:
      x <> h <> t

def toggle(+x: Nat, xs: +List<Nat>) -> +List<Nat>:
  match xs:
    case Nil{}:
      [x]
    case Con{+h, t}:
      choose(x, h, t, same(x, h))

def action(xs: +List<Nat>, s: +List<Nat>) -> +List<Nat>:
  match xs:
    case Nil{}:
      s
    case Con{h, t}:
      toggle(h, action(t, s))

def Fresh(x: Nat, xs: +List<Nat>) -> Data:
  match xs:
    case Nil{}:
      Unit
    case Con{h, t}:
      {same(x, h) == False{} : Bool}

def Reduced(xs: +List<Nat>) -> Data:
  match xs:
    case Nil{}:
      Unit
    case Con{+h, +t}:
      Sigma<&2, &2, Fresh(h, t), u => Reduced(t)>

def Equivalent(+xs: +List<Nat>, +ys: +List<Nat>) -> Type:
  @+s: +List<Nat> -> Reduced(s) -> {action(xs, s) == action(ys, s) : +List<Nat>}

law canonical:
  for +xs: +List<Nat>
  exs ys: +List<Nat>
  Reduced(ys) & Equivalent(xs, ys)

law unique:
  for +xs: +List<Nat>
  for +ys: +List<Nat>
  for rx: Reduced(xs)
  for ry: Reduced(ys)
  for e: Equivalent(xs, ys)
  {xs == ys : +List<Nat>}

# solution

def false_type(b: Bool) -> Type:
  match b:
    case False{}: Unit
    case True{}: Empty

def clash(e: {False{} == True{} : Bool}) -> Empty:
  %e : false_type(_)
  Unit{}

def same_self(+x: Nat) -> {same(x, x) == True{} : Bool}:
  match x:
    case 0n: {==}
    case 1n+p: same_self(p)

def same_sound(+x: Nat, +y: Nat, e: {same(x, y) == True{} : Bool}) -> {x == y : Nat}:
  match x y:
    case 0n 0n: {==}
    case 0n 1n+q:
      Empty.absurd({0n == 1n+q : Nat}, clash(e))
    case 1n+p 0n:
      Empty.absurd({1n+p == 0n : Nat}, clash(e))
    case 1n+p 1n+q:
      %same_sound(p, q, e) : {1n+p == 1n+_ : Nat}
      {==}

def fresh_toggle(+x: Nat, +xs: +List<Nat>, r: Fresh(x, xs)) -> {toggle(x, xs) == x <> xs : +List<Nat>}:
  match xs:
    case Nil{}: {==}
    case Con{h, t}:
      %r : {choose(x, h, t, same(x, h)) == choose(x, h, t, _) : +List<Nat>}
      {==}

def toggle_reduced_case(+x: Nat, +h: Nat, +t: +List<Nat>, +r: Reduced(h <> t), b: Bool, e: {same(x, h) == b : Bool}) -> Reduced(choose(x, h, t, b)):
  (f, rt) = r
  match b:
    case False{}: (e, (f, rt))
    case True{}: rt

def toggle_reduced(+x: Nat, +xs: +List<Nat>, r: Reduced(xs)) -> Reduced(toggle(x, xs)):
  match xs:
    case Nil{}: (Unit{}, Unit{})
    case Con{h, t}: toggle_reduced_case(x, h, t, r, same(x, h), {==})

def action_reduced(+xs: +List<Nat>, +s: +List<Nat>, r: Reduced(s)) -> Reduced(action(xs, s)):
  match xs:
    case Nil{}: r
    case Con{h, t}: toggle_reduced(h, action(t, s), action_reduced(t, s, r))

def action_fixed(+xs: +List<Nat>, r: Reduced(xs)) -> {action(xs, []) == xs : +List<Nat>}:
  match xs:
    case Nil{}: {==}
    case Con{h, t}:
      (f, rt) = r
      %Equal.sym(+List<Nat>, action(t, []), t, action_fixed(t, rt)) : {toggle(h, _) == h <> t : +List<Nat>}
      fresh_toggle(h, t, f)

def choose_self(+x: Nat, +t: +List<Nat>) -> {choose(x, x, t, same(x, x)) == t : +List<Nat>}:
  Equal.cong(Bool, +List<Nat>, b => choose(x, x, t, b), same(x, x), True{}, same_self(x))

def toggle_twice_case(+x: Nat, +h: Nat, +t: +List<Nat>, +r: Reduced(h <> t), b: Bool, e: {same(x, h) == b : Bool}) -> {toggle(x, choose(x, h, t, b)) == h <> t : +List<Nat>}:
  (f, rt) = r
  match b:
    case False{}:
      choose_self(x, h <> t)
    case True{}:
      %Equal.sym(Nat, x, h, same_sound(x, h, e)) : {toggle(_, t) == h <> t : +List<Nat>}
      fresh_toggle(h, t, f)

def toggle_twice(+x: Nat, +xs: +List<Nat>, r: Reduced(xs)) -> {toggle(x, toggle(x, xs)) == xs : +List<Nat>}:
  match xs:
    case Nil{}:
      choose_self(x, [])
    case Con{h, t}: toggle_twice_case(x, h, t, r, same(x, h), {==})

def action_toggle_case(+x: Nat, +h: Nat, +t: +List<Nat>, +s: +List<Nat>, r: Reduced(s), b: Bool, e: {same(x, h) == b : Bool}) -> {action(choose(x, h, t, b), s) == toggle(x, action(h <> t, s)) : +List<Nat>}:
  match b:
    case False{}: {==}
    case True{}:
      +a = action(t, s)
      %Equal.sym(Nat, x, h, same_sound(x, h, e)) : {a == toggle(_, toggle(h, a)) : +List<Nat>}
      Equal.sym(+List<Nat>, toggle(h, toggle(h, a)), a, toggle_twice(h, a, action_reduced(t, s, r)))

def action_toggle(+x: Nat, +xs: +List<Nat>, +s: +List<Nat>, r: Reduced(s)) -> {action(toggle(x, xs), s) == toggle(x, action(xs, s)) : +List<Nat>}:
  match xs:
    case Nil{}: {==}
    case Con{h, t}: action_toggle_case(x, h, t, s, r, same(x, h), {==})

def action_normal(+xs: +List<Nat>, +s: +List<Nat>, +r: Reduced(s)) -> {action(action(xs, []), s) == action(xs, s) : +List<Nat>}:
  match xs:
    case Nil{}: {==}
    case Con{h, t}:
      %action_normal(t, s, r) : {action(toggle(h, action(t, [])), s) == toggle(h, _) : +List<Nat>}
      action_toggle(h, action(t, []), s, r)

def normal_equiv(+xs: +List<Nat>, +s: +List<Nat>, r: Reduced(s)) -> {action(xs, s) == action(action(xs, []), s) : +List<Nat>}:
  Equal.sym(+List<Nat>, action(action(xs, []), s), action(xs, s), action_normal(xs, s, r))

def canonical(xs):
  (action(xs, []), (action_reduced(xs, [], Unit{}), normal_equiv(xs)))

def unique(xs, ys, rx, ry, e):
  %action_fixed(xs, rx) : {_ == ys : +List<Nat>}
  %action_fixed(ys, ry) : {action(xs, []) == _ : +List<Nat>}
  e([], Unit{})
