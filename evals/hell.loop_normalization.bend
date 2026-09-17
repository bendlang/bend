# A robot planner uses regular plans with unit-cost actions and free control flow.
# Remove empty loop iterations while preserving every exact feasible budget.
# Fail, done, action, choice, sequence, and repetition are the regular operations.
import Base

type Plan is Data:
  Dead{}
  Rest{}
  Act{}
  Pick{left: Plan, right: Plan}
  Seq{left: Plan, right: Plan}
  Loop{body: Plan}

type Trace is Data:
  Quiet{}
  Moved{}
  TakeL{run: Trace}
  TakeR{run: Trace}
  Join{first: Trace, second: Trace}
  Finish{}
  Again{first: Trace, rest: Trace}

def cost(d: Trace) -> Nat:
  match d:
    case Quiet{}: 0n
    case Moved{}: 1n
    case TakeL{x}: cost(x)
    case TakeR{x}: cost(x)
    case Join{x, y}: Nat.add(cost(x), cost(y))
    case Finish{}: 0n
    case Again{x, y}: Nat.add(cost(x), cost(y))

def Valid(p: Plan, +d: Trace) -> Type:
  match p, d:
    case Rest{}, Quiet{}: Unit
    case Act{}, Moved{}: Unit
    case Pick{a, b}, TakeL{x}: Valid(a, x)
    case Pick{a, b}, TakeR{x}: Valid(b, x)
    case Seq{a, b}, Join{x, y}: Valid(a, x) & Valid(b, y)
    case Loop{a}, Finish{}: Unit
    case Loop{a}, Again{x, y}: Valid(a, x) & Valid(Loop{a}, y)
    case _, _: Empty

def Runs(+p: Plan, +n: Nat) -> Type:
  &d: Trace -> Valid(p, d) & {cost(d) == n : Nat}

def nullable(p: Plan) -> Bool:
  match p:
    case Dead{}: False{}
    case Rest{}: True{}
    case Act{}: False{}
    case Pick{a, b}: Bool.or(nullable(a), nullable(b))
    case Seq{a, b}: Bool.and(nullable(a), nullable(b))
    case Loop{a}: True{}

def optional(b: Bool, p: Plan) -> Plan:
  match b:
    case False{}: Dead{}
    case True{}: p

# clean(p, False) preserves p; clean(p, True) additionally removes its empty run.
def clean(+p: Plan, +positive: Bool) -> Plan:
  match p:
    case Dead{}: Dead{}
    case Rest{}:
      match positive:
        case False{}: Rest{}
        case True{}: Dead{}
    case Act{}: Act{}
    case Pick{a, b}: Pick{clean(a, positive), clean(b, positive)}
    case Seq{+a, b}:
      match positive:
        case False{}: Seq{clean(a, False{}), clean(b, False{})}
        case True{}: Pick{Seq{clean(a, True{}), clean(b, False{})}, optional(nullable(a), clean(b, True{}))}
    case Loop{+a}:
      match positive:
        case False{}: Loop{clean(a, True{})}
        case True{}: Seq{clean(a, True{}), Loop{clean(a, True{})}}

def Proper(p: Plan) -> Type:
  match p:
    case Dead{}: Unit
    case Rest{}: Unit
    case Act{}: Unit
    case Pick{a, b}: Proper(a) & Proper(b)
    case Seq{a, b}: Proper(a) & Proper(b)
    case Loop{+a}: Proper(a) & {nullable(a) == False{} : Bool}

law normalize:
  for +p: Plan
  Proper(clean(p, False{})) & (@n: Nat -> (Runs(clean(p, False{}), n) -> Runs(p, n)) & (Runs(p, n) -> Runs(clean(p, False{}), n)))

# solution

def no_optional(+b: Bool, +p: Plan, e: {nullable(p) == False{} : Bool}) -> {nullable(optional(b, p)) == False{} : Bool}:
  match b:
    case False{}:
      {==}
    case True{}:
      e

def proper_optional(+b: Bool, +p: Plan, e: Proper(p)) -> Proper(optional(b, p)):
  match b:
    case False{}:
      Unit{}
    case True{}:
      e

def add_eq(-a: Nat, -b: Nat, -c: Nat, -d: Nat, e: {a == b : Nat}, f: {c == d : Nat}) -> {Nat.add(a, c) == Nat.add(b, d) : Nat}:
  %e : {Nat.add(a, c) == Nat.add(_, d) : Nat}
  %f : {Nat.add(a, c) == Nat.add(a, _) : Nat}
  {==}

def runs_elim(-p: Plan, -n: Nat, -R: Type, r: Runs(p, n), f: @d: Trace -> Valid(p, d) -> {cost(d) == n : Nat} -> R) -> R:
  match r:
    case (d, (v, e)): f(d, v, e)

def join_runs(+a: Plan, +b: Plan, +m: Nat, +k: Nat, x: Runs(a, m), y: Runs(b, k)) -> Runs(Seq{a, b}, Nat.add(m, k)):
  match x y:
    case Tuple{u, Tuple{vu, eu}} Tuple{w, Tuple{vw, ew}}:
      (Join{u, w}, (vu, vw), add_eq(cost(u), m, cost(w), k, eu, ew))

def loop_runs(+a: Plan, +m: Nat, +k: Nat, x: Runs(a, m), y: Runs(Loop{a}, k)) -> Runs(Loop{a}, Nat.add(m, k)):
  match x y:
    case Tuple{u, Tuple{vu, eu}} Tuple{w, Tuple{vw, ew}}:
      (Again{u, w}, (vu, vw), add_eq(cost(u), m, cost(w), k, eu, ew))

def left_runs(+a: Plan, +b: Plan, +n: Nat, x: Runs(a, n)) -> Runs(Pick{a, b}, n):
  match x:
    case (d, (v, e)):
      (TakeL{d}, v, e)

def right_runs(+a: Plan, +b: Plan, +n: Nat, x: Runs(b, n)) -> Runs(Pick{a, b}, n):
  match x:
    case (d, (v, e)):
      (TakeR{d}, v, e)

def FalseType(b: Bool) -> Type:
  match b:
    case False{}:
      Unit
    case True{}:
      Empty

def false_true(e: {False{} == True{} : Bool}) -> Empty:
  %e : FalseType(_)
  Unit{}

def SuccType(n: Nat) -> Data:
  match n:
    case 0n:
      Empty
    case 1n+k:
      Unit

def succ_zero(-n: Nat, e: {1n+n == 0n : Nat}) -> Empty:
  %e : SuccType(_)
  Unit{}

def sum_zero(+m: Nat, +k: Nat, e: {Nat.add(m, k) == 0n : Nat}) -> {m == 0n : Nat} & {k == 0n : Nat}:
  match m:
    case 0n:
      ({==}, e)
    case 1n+j:
      Empty.absurd({1n+j == 0n : Nat} & {k == 0n : Nat}, succ_zero(Nat.add(j, k), e))

def and_left(+a: Bool, +b: Bool, e: {Bool.and(a, b) == True{} : Bool}) -> {a == True{} : Bool}:
  match a:
    case False{}:
      Empty.absurd({False{} == True{} : Bool}, false_true(e))
    case True{}:
      {==}

def and_right(+a: Bool, +b: Bool, e: {Bool.and(a, b) == True{} : Bool}) -> {b == True{} : Bool}:
  match a:
    case False{}:
      Empty.absurd({b == True{} : Bool}, false_true(e))
    case True{}:
      e

def or_direct(+a: Bool, +b: Bool, -R: Type, fa: {a == True{} : Bool} -> R, fb: {b == True{} : Bool} -> R, e: {Bool.or(a, b) == True{} : Bool}) -> R:
  match a:
    case False{}:
      fb(e)
    case True{}:
      fa({==})

def PlanFacts(+p: Plan) -> Type:
  {nullable(clean(p, True{})) == False{} : Bool} & Proper(clean(p, False{})) & Proper(clean(p, True{})) & ({nullable(p) == True{} : Bool} -> Runs(p, 0n))

def empty_fact(-p: Plan, fs: PlanFacts(p)) -> {nullable(clean(p, True{})) == False{} : Bool}:
  match fs:
    case (e, r): e

def proper_n_fact(-p: Plan, fs: PlanFacts(p)) -> Proper(clean(p, False{})):
  match fs:
    case (e, (n, r)): n

def proper_p_fact(-p: Plan, fs: PlanFacts(p)) -> Proper(clean(p, True{})):
  match fs:
    case (e, (n, (p, z))): p

def zero_fact(-p: Plan, e: {nullable(p) == True{} : Bool}, fs: PlanFacts(p)) -> Runs(p, 0n):
  match fs:
    case (ne, (n, (p, z))): z(e)

def empty_pick(+a: Plan, +b: Plan, ea: {nullable(clean(a, True{})) == False{} : Bool}, eb: {nullable(clean(b, True{})) == False{} : Bool}) -> {nullable(clean(Pick{a, b}, True{})) == False{} : Bool}:
  %Equal.sym(Bool, nullable(clean(a, True{})), False{}, ea) : {Bool.or(_, nullable(clean(b, True{}))) == False{} : Bool}
  eb

def empty_seq(+a: Plan, +b: Plan, ea: {nullable(clean(a, True{})) == False{} : Bool}, eb: {nullable(clean(b, True{})) == False{} : Bool}) -> {nullable(clean(Seq{a, b}, True{})) == False{} : Bool}:
  %Equal.sym(Bool, nullable(clean(a, True{})), False{}, ea) : {Bool.or(Bool.and(_, nullable(clean(b, False{}))), nullable(optional(nullable(a), clean(b, True{})))) == False{} : Bool}
  no_optional(nullable(a), clean(b, True{}), eb)

def empty_loop(+a: Plan, ea: {nullable(clean(a, True{})) == False{} : Bool}) -> {nullable(clean(Loop{a}, True{})) == False{} : Bool}:
  %Equal.sym(Bool, nullable(clean(a, True{})), False{}, ea) : {Bool.and(_, True{}) == False{} : Bool}
  {==}

def zero_seq_build(+a: Plan, +b: Plan, +e: {Bool.and(nullable(a), nullable(b)) == True{} : Bool}, fa: {nullable(a) == True{} : Bool} -> Runs(a, 0n), fb: {nullable(b) == True{} : Bool} -> Runs(b, 0n)) -> Runs(Seq{a, b}, 0n):
  join_runs(a, b, 0n, 0n, fa(and_left(nullable(a), nullable(b), e)), fb(and_right(nullable(a), nullable(b), e)))

def plan_facts(+p: Plan) -> PlanFacts(p):
  match p:
    case Dead{}: ({==}, Unit{}, Unit{}, (e => Empty.absurd(Runs(Dead{}, 0n), false_true(e))))
    case Rest{}: ({==}, Unit{}, Unit{}, (e => (Quiet{}, Unit{}, {==})))
    case Act{}: ({==}, Unit{}, Unit{}, (e => Empty.absurd(Runs(Act{}, 0n), false_true(e))))
    case Pick{a, b}:
      (empty_pick(a, b, empty_fact(a, plan_facts(a)), empty_fact(b, plan_facts(b))),
       (proper_n_fact(a, plan_facts(a)), proper_n_fact(b, plan_facts(b))),
       (proper_p_fact(a, plan_facts(a)), proper_p_fact(b, plan_facts(b))),
       (e => or_direct(nullable(a), nullable(b), Runs(Pick{a, b}, 0n), x => left_runs(a, b, 0n, zero_fact(a, x, plan_facts(a))), x => right_runs(a, b, 0n, zero_fact(b, x, plan_facts(b))), e)))
    case Seq{a, b}:
      (empty_seq(a, b, empty_fact(a, plan_facts(a)), empty_fact(b, plan_facts(b))),
       (proper_n_fact(a, plan_facts(a)), proper_n_fact(b, plan_facts(b))),
       ((proper_p_fact(a, plan_facts(a)), proper_n_fact(b, plan_facts(b))), proper_optional(nullable(a), clean(b, True{}), proper_p_fact(b, plan_facts(b)))),
       (e => zero_seq_build(a, b, e, x => zero_fact(a, x, plan_facts(a)), x => zero_fact(b, x, plan_facts(b)))))
    case Loop{a}:
      (empty_loop(a, empty_fact(a, plan_facts(a))),
       (proper_p_fact(a, plan_facts(a)), empty_fact(a, plan_facts(a))),
       (proper_p_fact(a, plan_facts(a)), (proper_p_fact(a, plan_facts(a)), empty_fact(a, plan_facts(a)))),
       (e => (Finish{}, Unit{}, {==})))

def proper_clean(+p: Plan, +positive: Bool) -> Proper(clean(p, positive)):
  match positive:
    case False{}:
      proper_n_fact(p, plan_facts(p))
    case True{}:
      proper_p_fact(p, plan_facts(p))

def or_left(+a: Bool, +b: Bool, e: {a == True{} : Bool}) -> {Bool.or(a, b) == True{} : Bool}:
  %e : {Bool.or(a, b) == Bool.or(_, b) : Bool}
  {==}

def or_right(+a: Bool, +b: Bool, e: {b == True{} : Bool}) -> {Bool.or(a, b) == True{} : Bool}:
  match a:
    case False{}:
      e
    case True{}:
      {==}

def and_true(+a: Bool, +b: Bool, ea: {a == True{} : Bool}, eb: {b == True{} : Bool}) -> {Bool.and(a, b) == True{} : Bool}:
  %eb : {Bool.and(a, b) == _ : Bool}
  %ea : {Bool.and(a, b) == Bool.and(_, b) : Bool}
  {==}

def optional_sound(+a: Plan, +b: Plan, +x: Trace, +z: Bool, ez: {nullable(a) == z : Bool}, v: Valid(optional(z, clean(b, True{})), x), f: Valid(clean(b, True{}), x) -> Runs(b, cost(x))) -> Runs(Seq{a, b}, cost(x)):
  match z:
    case False{}:
      Empty.absurd(Runs(Seq{a, b}, cost(x)), v)
    case True{}:
      join_runs(a, b, 0n, cost(x), zero_fact(a, ez, plan_facts(a)), f(v))

def sound_quiet_rest(+positive: Bool) -> Valid(clean(Rest{}, positive), Quiet{}) -> Runs(Rest{}, cost(Quiet{})):
  match positive:
    case False{}:
      (v => (Quiet{}, Unit{}, {==}))
    case True{}:
      (v => Empty.absurd(Runs(Rest{}, cost(Quiet{})), v))

def sound_quiet_seq(+a: Plan, +b: Plan, +positive: Bool) -> Valid(clean(Seq{a, b}, positive), Quiet{}) -> Runs(Seq{a, b}, cost(Quiet{})):
  match positive:
    case False{}:
      (v => Empty.absurd(Runs(Seq{a, b}, cost(Quiet{})), v))
    case True{}:
      (v => Empty.absurd(Runs(Seq{a, b}, cost(Quiet{})), v))

def sound_quiet_loop(+a: Plan, +positive: Bool) -> Valid(clean(Loop{a}, positive), Quiet{}) -> Runs(Loop{a}, cost(Quiet{})):
  match positive:
    case False{}:
      (v => Empty.absurd(Runs(Loop{a}, cost(Quiet{})), v))
    case True{}:
      (v => Empty.absurd(Runs(Loop{a}, cost(Quiet{})), v))

def sound_quiet(+p: Plan, +positive: Bool, v: Valid(clean(p, positive), Quiet{})) -> Runs(p, cost(Quiet{})):
  match p:
    case Dead{}:
      ((v => Empty.absurd(Runs(Dead{}, cost(Quiet{})), v)))(v)
    case Rest{}:
      (sound_quiet_rest(positive))(v)
    case Act{}:
      ((v => Empty.absurd(Runs(Act{}, cost(Quiet{})), v)))(v)
    case Pick{a, b}:
      ((v => Empty.absurd(Runs(Pick{a, b}, cost(Quiet{})), v)))(v)
    case Seq{a, b}:
      (sound_quiet_seq(a, b, positive))(v)
    case Loop{a}:
      (sound_quiet_loop(a, positive))(v)

def sound_moved_rest(+positive: Bool) -> Valid(clean(Rest{}, positive), Moved{}) -> Runs(Rest{}, cost(Moved{})):
  match positive:
    case False{}:
      (v => Empty.absurd(Runs(Rest{}, cost(Moved{})), v))
    case True{}:
      (v => Empty.absurd(Runs(Rest{}, cost(Moved{})), v))

def sound_moved_act(+positive: Bool, v: Valid(clean(Act{}, positive), Moved{})) -> Runs(Act{}, cost(Moved{})):
  (Moved{}, Unit{}, {==})

def sound_moved_seq(+a: Plan, +b: Plan, +positive: Bool) -> Valid(clean(Seq{a, b}, positive), Moved{}) -> Runs(Seq{a, b}, cost(Moved{})):
  match positive:
    case False{}:
      (v => Empty.absurd(Runs(Seq{a, b}, cost(Moved{})), v))
    case True{}:
      (v => Empty.absurd(Runs(Seq{a, b}, cost(Moved{})), v))

def sound_moved_loop(+a: Plan, +positive: Bool) -> Valid(clean(Loop{a}, positive), Moved{}) -> Runs(Loop{a}, cost(Moved{})):
  match positive:
    case False{}:
      (v => Empty.absurd(Runs(Loop{a}, cost(Moved{})), v))
    case True{}:
      (v => Empty.absurd(Runs(Loop{a}, cost(Moved{})), v))

def sound_moved(+p: Plan, +positive: Bool, v: Valid(clean(p, positive), Moved{})) -> Runs(p, cost(Moved{})):
  match p:
    case Dead{}:
      ((v => Empty.absurd(Runs(Dead{}, cost(Moved{})), v)))(v)
    case Rest{}:
      (sound_moved_rest(positive))(v)
    case Act{}:
      (sound_moved_act(positive))(v)
    case Pick{a, b}:
      ((v => Empty.absurd(Runs(Pick{a, b}, cost(Moved{})), v)))(v)
    case Seq{a, b}:
      (sound_moved_seq(a, b, positive))(v)
    case Loop{a}:
      (sound_moved_loop(a, positive))(v)

def sound_finish_rest(+positive: Bool) -> Valid(clean(Rest{}, positive), Finish{}) -> Runs(Rest{}, cost(Finish{})):
  match positive:
    case False{}:
      (v => Empty.absurd(Runs(Rest{}, cost(Finish{})), v))
    case True{}:
      (v => Empty.absurd(Runs(Rest{}, cost(Finish{})), v))

def sound_finish_seq(+a: Plan, +b: Plan, +positive: Bool) -> Valid(clean(Seq{a, b}, positive), Finish{}) -> Runs(Seq{a, b}, cost(Finish{})):
  match positive:
    case False{}:
      (v => Empty.absurd(Runs(Seq{a, b}, cost(Finish{})), v))
    case True{}:
      (v => Empty.absurd(Runs(Seq{a, b}, cost(Finish{})), v))

def sound_finish_loop(+a: Plan, +positive: Bool) -> Valid(clean(Loop{a}, positive), Finish{}) -> Runs(Loop{a}, cost(Finish{})):
  match positive:
    case False{}:
      (v => (Finish{}, Unit{}, {==}))
    case True{}:
      (v => Empty.absurd(Runs(Loop{a}, cost(Finish{})), v))

def sound_finish(+p: Plan, +positive: Bool, v: Valid(clean(p, positive), Finish{})) -> Runs(p, cost(Finish{})):
  match p:
    case Dead{}:
      ((v => Empty.absurd(Runs(Dead{}, cost(Finish{})), v)))(v)
    case Rest{}:
      (sound_finish_rest(positive))(v)
    case Act{}:
      ((v => Empty.absurd(Runs(Act{}, cost(Finish{})), v)))(v)
    case Pick{a, b}:
      ((v => Empty.absurd(Runs(Pick{a, b}, cost(Finish{})), v)))(v)
    case Seq{a, b}:
      (sound_finish_seq(a, b, positive))(v)
    case Loop{a}:
      (sound_finish_loop(a, positive))(v)

def sound_right_dead(+positive: Bool, +x: Trace, v: Valid(clean(Dead{}, positive), TakeR{x}), fx: (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x)))) -> Runs(Dead{}, cost(TakeR{x})):
  Empty.absurd(Runs(Dead{}, cost(TakeR{x})), v)

def sound_right_rest(+positive: Bool, +x: Trace) -> Valid(clean(Rest{}, positive), TakeR{x}) -> (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x))) -> Runs(Rest{}, cost(TakeR{x})):
  match positive:
    case False{}:
      (v => fx => Empty.absurd(Runs(Rest{}, cost(TakeR{x})), v))
    case True{}:
      (v => fx => Empty.absurd(Runs(Rest{}, cost(TakeR{x})), v))

def sound_right_act(+positive: Bool, +x: Trace, v: Valid(clean(Act{}, positive), TakeR{x}), fx: (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x)))) -> Runs(Act{}, cost(TakeR{x})):
  Empty.absurd(Runs(Act{}, cost(TakeR{x})), v)

def sound_right_pick(+a: Plan, +b: Plan, +positive: Bool, +x: Trace, v: Valid(clean(Pick{a, b}, positive), TakeR{x}), fx: (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x)))) -> Runs(Pick{a, b}, cost(TakeR{x})):
  right_runs(a, b, cost(x), fx(b, positive, v))

def sound_right_seq(+a: Plan, +b: Plan, +positive: Bool, +x: Trace) -> Valid(clean(Seq{a, b}, positive), TakeR{x}) -> (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x))) -> Runs(Seq{a, b}, cost(TakeR{x})):
  match positive:
    case False{}:
      (v => fx => Empty.absurd(Runs(Seq{a, b}, cost(TakeR{x})), v))
    case True{}:
      (v => fx => optional_sound(a, b, x, nullable(a), {==}, v, vx => fx(b, True{}, vx)))

def sound_right_loop(+a: Plan, +positive: Bool, +x: Trace) -> Valid(clean(Loop{a}, positive), TakeR{x}) -> (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x))) -> Runs(Loop{a}, cost(TakeR{x})):
  match positive:
    case False{}:
      (v => fx => Empty.absurd(Runs(Loop{a}, cost(TakeR{x})), v))
    case True{}:
      (v => fx => Empty.absurd(Runs(Loop{a}, cost(TakeR{x})), v))

def sound_right(+p: Plan, +positive: Bool, +x: Trace, v: Valid(clean(p, positive), TakeR{x}), fx: @a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x))) -> Runs(p, cost(TakeR{x})):
  match p:
    case Dead{}:
      ((sound_right_dead(positive, x))(v))(fx)
    case Rest{}:
      ((sound_right_rest(positive, x))(v))(fx)
    case Act{}:
      ((sound_right_act(positive, x))(v))(fx)
    case Pick{a, b}:
      ((sound_right_pick(a, b, positive, x))(v))(fx)
    case Seq{a, b}:
      ((sound_right_seq(a, b, positive, x))(v))(fx)
    case Loop{a}:
      ((sound_right_loop(a, positive, x))(v))(fx)

def sound_join_dead(+positive: Bool, +x: Trace, +y: Trace, v: Valid(clean(Dead{}, positive), Join{x, y}), fx: (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x))), fy: (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), y) -> Runs(a, cost(y)))) -> Runs(Dead{}, cost(Join{x, y})):
  Empty.absurd(Runs(Dead{}, cost(Join{x, y})), v)

def sound_join_rest(+positive: Bool, +x: Trace, +y: Trace) -> Valid(clean(Rest{}, positive), Join{x, y}) -> (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x))) -> (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), y) -> Runs(a, cost(y))) -> Runs(Rest{}, cost(Join{x, y})):
  match positive:
    case False{}:
      (v => fx => fy => Empty.absurd(Runs(Rest{}, cost(Join{x, y})), v))
    case True{}:
      (v => fx => fy => Empty.absurd(Runs(Rest{}, cost(Join{x, y})), v))

def sound_join_act(+positive: Bool, +x: Trace, +y: Trace, v: Valid(clean(Act{}, positive), Join{x, y}), fx: (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x))), fy: (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), y) -> Runs(a, cost(y)))) -> Runs(Act{}, cost(Join{x, y})):
  Empty.absurd(Runs(Act{}, cost(Join{x, y})), v)

def sound_join_pick(+a: Plan, +b: Plan, +positive: Bool, +x: Trace, +y: Trace, v: Valid(clean(Pick{a, b}, positive), Join{x, y}), fx: (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x))), fy: (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), y) -> Runs(a, cost(y)))) -> Runs(Pick{a, b}, cost(Join{x, y})):
  Empty.absurd(Runs(Pick{a, b}, cost(Join{x, y})), v)

def sound_join_seq(+a: Plan, +b: Plan, +positive: Bool, +x: Trace, +y: Trace, v: Valid(clean(Seq{a, b}, positive), Join{x, y}), fx: @a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x)), fy: @a: Plan -> @positive: Bool -> Valid(clean(a, positive), y) -> Runs(a, cost(y))) -> Runs(Seq{a, b}, cost(Join{x, y})):
  match positive v:
    case False{} Tuple{vx, vy}: join_runs(a, b, cost(x), cost(y), fx(a, False{}, vx), fy(b, False{}, vy))
    case True{} v: Empty.absurd(Runs(Seq{a, b}, cost(Join{x, y})), v)

def sound_join_loop(+a: Plan, +positive: Bool, +x: Trace, +y: Trace, v: Valid(clean(Loop{a}, positive), Join{x, y}), fx: @a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x)), fy: @a: Plan -> @positive: Bool -> Valid(clean(a, positive), y) -> Runs(a, cost(y))) -> Runs(Loop{a}, cost(Join{x, y})):
  match positive v:
    case False{} v: Empty.absurd(Runs(Loop{a}, cost(Join{x, y})), v)
    case True{} Tuple{vx, vy}: loop_runs(a, cost(x), cost(y), fx(a, True{}, vx), fy(Loop{a}, False{}, vy))

def sound_join(+p: Plan, +positive: Bool, +x: Trace, +y: Trace, v: Valid(clean(p, positive), Join{x, y}), fx: @a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x)), fy: @a: Plan -> @positive: Bool -> Valid(clean(a, positive), y) -> Runs(a, cost(y))) -> Runs(p, cost(Join{x, y})):
  match p:
    case Dead{}:
      (((sound_join_dead(positive, x, y))(v))(fx))(fy)
    case Rest{}:
      (((sound_join_rest(positive, x, y))(v))(fx))(fy)
    case Act{}:
      (((sound_join_act(positive, x, y))(v))(fx))(fy)
    case Pick{a, b}:
      (((sound_join_pick(a, b, positive, x, y))(v))(fx))(fy)
    case Seq{a, b}:
      (((sound_join_seq(a, b, positive, x, y))(v))(fx))(fy)
    case Loop{a}:
      (((sound_join_loop(a, positive, x, y))(v))(fx))(fy)

def sound_again_dead(+positive: Bool, +x: Trace, +y: Trace, v: Valid(clean(Dead{}, positive), Again{x, y}), fx: (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x))), fy: (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), y) -> Runs(a, cost(y)))) -> Runs(Dead{}, cost(Again{x, y})):
  Empty.absurd(Runs(Dead{}, cost(Again{x, y})), v)

def sound_again_rest(+positive: Bool, +x: Trace, +y: Trace) -> Valid(clean(Rest{}, positive), Again{x, y}) -> (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x))) -> (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), y) -> Runs(a, cost(y))) -> Runs(Rest{}, cost(Again{x, y})):
  match positive:
    case False{}:
      (v => fx => fy => Empty.absurd(Runs(Rest{}, cost(Again{x, y})), v))
    case True{}:
      (v => fx => fy => Empty.absurd(Runs(Rest{}, cost(Again{x, y})), v))

def sound_again_act(+positive: Bool, +x: Trace, +y: Trace, v: Valid(clean(Act{}, positive), Again{x, y}), fx: (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x))), fy: (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), y) -> Runs(a, cost(y)))) -> Runs(Act{}, cost(Again{x, y})):
  Empty.absurd(Runs(Act{}, cost(Again{x, y})), v)

def sound_again_pick(+a: Plan, +b: Plan, +positive: Bool, +x: Trace, +y: Trace, v: Valid(clean(Pick{a, b}, positive), Again{x, y}), fx: (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x))), fy: (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), y) -> Runs(a, cost(y)))) -> Runs(Pick{a, b}, cost(Again{x, y})):
  Empty.absurd(Runs(Pick{a, b}, cost(Again{x, y})), v)

def sound_again_seq(+a: Plan, +b: Plan, +positive: Bool, +x: Trace, +y: Trace) -> Valid(clean(Seq{a, b}, positive), Again{x, y}) -> (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x))) -> (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), y) -> Runs(a, cost(y))) -> Runs(Seq{a, b}, cost(Again{x, y})):
  match positive:
    case False{}:
      (v => fx => fy => Empty.absurd(Runs(Seq{a, b}, cost(Again{x, y})), v))
    case True{}:
      (v => fx => fy => Empty.absurd(Runs(Seq{a, b}, cost(Again{x, y})), v))

def sound_again_loop(+a: Plan, +positive: Bool, +x: Trace, +y: Trace, v: Valid(clean(Loop{a}, positive), Again{x, y}), fx: @a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x)), fy: @a: Plan -> @positive: Bool -> Valid(clean(a, positive), y) -> Runs(a, cost(y))) -> Runs(Loop{a}, cost(Again{x, y})):
  match positive v:
    case False{} Tuple{vx, vy}: loop_runs(a, cost(x), cost(y), fx(a, True{}, vx), fy(Loop{a}, False{}, vy))
    case True{} v: Empty.absurd(Runs(Loop{a}, cost(Again{x, y})), v)

def sound_again(+p: Plan, +positive: Bool, +x: Trace, +y: Trace, v: Valid(clean(p, positive), Again{x, y}), fx: @a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x)), fy: @a: Plan -> @positive: Bool -> Valid(clean(a, positive), y) -> Runs(a, cost(y))) -> Runs(p, cost(Again{x, y})):
  match p:
    case Dead{}:
      (((sound_again_dead(positive, x, y))(v))(fx))(fy)
    case Rest{}:
      (((sound_again_rest(positive, x, y))(v))(fx))(fy)
    case Act{}:
      (((sound_again_act(positive, x, y))(v))(fx))(fy)
    case Pick{a, b}:
      (((sound_again_pick(a, b, positive, x, y))(v))(fx))(fy)
    case Seq{a, b}:
      (((sound_again_seq(a, b, positive, x, y))(v))(fx))(fy)
    case Loop{a}:
      (((sound_again_loop(a, positive, x, y))(v))(fx))(fy)

def sound_left_dead(+positive: Bool, +x: Trace, v: Valid(clean(Dead{}, positive), TakeL{x}), fx: (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x))), fj: (@a: Plan -> @b: Plan -> Valid(Seq{clean(a, True{}), clean(b, False{})}, x) -> Runs(Seq{a, b}, cost(x)))) -> Runs(Dead{}, cost(TakeL{x})):
  Empty.absurd(Runs(Dead{}, cost(x)), v)

def sound_left_rest(+positive: Bool, +x: Trace) -> Valid(clean(Rest{}, positive), TakeL{x}) -> (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x))) -> (@a: Plan -> @b: Plan -> Valid(Seq{clean(a, True{}), clean(b, False{})}, x) -> Runs(Seq{a, b}, cost(x))) -> Runs(Rest{}, cost(TakeL{x})):
  match positive:
    case False{}:
      (v => fx => fj => Empty.absurd(Runs(Rest{}, cost(x)), v))
    case True{}:
      (v => fx => fj => Empty.absurd(Runs(Rest{}, cost(x)), v))

def sound_left_act(+positive: Bool, +x: Trace, v: Valid(clean(Act{}, positive), TakeL{x}), fx: (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x))), fj: (@a: Plan -> @b: Plan -> Valid(Seq{clean(a, True{}), clean(b, False{})}, x) -> Runs(Seq{a, b}, cost(x)))) -> Runs(Act{}, cost(TakeL{x})):
  Empty.absurd(Runs(Act{}, cost(x)), v)

def sound_left_pick(+a: Plan, +b: Plan, +positive: Bool, +x: Trace, v: Valid(clean(Pick{a, b}, positive), TakeL{x}), fx: (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x))), fj: (@a: Plan -> @b: Plan -> Valid(Seq{clean(a, True{}), clean(b, False{})}, x) -> Runs(Seq{a, b}, cost(x)))) -> Runs(Pick{a, b}, cost(TakeL{x})):
  left_runs(a, b, cost(x), fx(a, positive, v))

def sound_left_seq(+a: Plan, +b: Plan, +positive: Bool, +x: Trace) -> Valid(clean(Seq{a, b}, positive), TakeL{x}) -> (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x))) -> (@a: Plan -> @b: Plan -> Valid(Seq{clean(a, True{}), clean(b, False{})}, x) -> Runs(Seq{a, b}, cost(x))) -> Runs(Seq{a, b}, cost(TakeL{x})):
  match positive:
    case False{}:
      (v => fx => fj => Empty.absurd(Runs(Seq{a, b}, cost(x)), v))
    case True{}:
      (v => fx => fj => fj(a, b, v))

def sound_left_loop(+a: Plan, +positive: Bool, +x: Trace) -> Valid(clean(Loop{a}, positive), TakeL{x}) -> (@a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x))) -> (@a: Plan -> @b: Plan -> Valid(Seq{clean(a, True{}), clean(b, False{})}, x) -> Runs(Seq{a, b}, cost(x))) -> Runs(Loop{a}, cost(TakeL{x})):
  match positive:
    case False{}:
      (v => fx => fj => Empty.absurd(Runs(Loop{a}, cost(x)), v))
    case True{}:
      (v => fx => fj => Empty.absurd(Runs(Loop{a}, cost(x)), v))

def sound_left(+p: Plan, +positive: Bool, +x: Trace, v: Valid(clean(p, positive), TakeL{x}), fx: @a: Plan -> @positive: Bool -> Valid(clean(a, positive), x) -> Runs(a, cost(x)), fj: @a: Plan -> @b: Plan -> Valid(Seq{clean(a, True{}), clean(b, False{})}, x) -> Runs(Seq{a, b}, cost(x))) -> Runs(p, cost(x)):
  match p:
    case Dead{}:
      (((sound_left_dead(positive, x))(v))(fx))(fj)
    case Rest{}:
      (((sound_left_rest(positive, x))(v))(fx))(fj)
    case Act{}:
      (((sound_left_act(positive, x))(v))(fx))(fj)
    case Pick{a, b}:
      (((sound_left_pick(a, b, positive, x))(v))(fx))(fj)
    case Seq{a, b}:
      (((sound_left_seq(a, b, positive, x))(v))(fx))(fj)
    case Loop{a}:
      (((sound_left_loop(a, positive, x))(v))(fx))(fj)

def sound_join_pair(+a: Plan, +b: Plan, +x: Trace, +y: Trace, v: Valid(clean(a, True{}), x) & Valid(clean(b, False{}), y), fx: @c: Plan -> Valid(clean(c, True{}), x) -> Runs(c, cost(x)), fy: @c: Plan -> Valid(clean(c, False{}), y) -> Runs(c, cost(y))) -> Runs(Seq{a, b}, Nat.add(cost(x), cost(y))):
  match v:
    case (vx, vy):
      join_runs(a, b, cost(x), cost(y), fx(a, vx), fy(b, vy))

def and_zero(+a: Bool, +b: Bool, -m: Nat, -k: Nat, z: {m == 0n : Nat} & {k == 0n : Nat}, fa: {m == 0n : Nat} -> {a == True{} : Bool}, fb: {k == 0n : Nat} -> {b == True{} : Bool}) -> {Bool.and(a, b) == True{} : Bool}:
  match z:
    case (em, ek):
      and_true(a, b, fa(em), fb(ek))

def valid_quiet(+p: Plan, -R: Plan -> Type, v: Valid(p, Quiet{}), f: R(Rest{})) -> R(p):
  match p:
    case Dead{}:
      Empty.absurd(R(Dead{}), v)
    case Rest{}:
      f
    case Act{}:
      Empty.absurd(R(Act{}), v)
    case Pick{a, b}:
      Empty.absurd(R(Pick{a, b}), v)
    case Seq{a, b}:
      Empty.absurd(R(Seq{a, b}), v)
    case Loop{a}:
      Empty.absurd(R(Loop{a}), v)

def valid_moved(+p: Plan, -R: Plan -> Type, v: Valid(p, Moved{}), f: R(Act{})) -> R(p):
  match p:
    case Dead{}:
      Empty.absurd(R(Dead{}), v)
    case Rest{}:
      Empty.absurd(R(Rest{}), v)
    case Act{}:
      f
    case Pick{a, b}:
      Empty.absurd(R(Pick{a, b}), v)
    case Seq{a, b}:
      Empty.absurd(R(Seq{a, b}), v)
    case Loop{a}:
      Empty.absurd(R(Loop{a}), v)

def valid_left(+p: Plan, +x: Trace, -R: Plan -> Type, v: Valid(p, TakeL{x}), f: @a: Plan -> @b: Plan -> Valid(a, x) -> R(Pick{a, b})) -> R(p):
  match p:
    case Dead{}:
      Empty.absurd(R(Dead{}), v)
    case Rest{}:
      Empty.absurd(R(Rest{}), v)
    case Act{}:
      Empty.absurd(R(Act{}), v)
    case Pick{a, b}:
      f(a, b, v)
    case Seq{a, b}:
      Empty.absurd(R(Seq{a, b}), v)
    case Loop{a}:
      Empty.absurd(R(Loop{a}), v)

def valid_right(+p: Plan, +x: Trace, -R: Plan -> Type, v: Valid(p, TakeR{x}), f: @a: Plan -> @b: Plan -> Valid(b, x) -> R(Pick{a, b})) -> R(p):
  match p:
    case Dead{}:
      Empty.absurd(R(Dead{}), v)
    case Rest{}:
      Empty.absurd(R(Rest{}), v)
    case Act{}:
      Empty.absurd(R(Act{}), v)
    case Pick{a, b}:
      f(a, b, v)
    case Seq{a, b}:
      Empty.absurd(R(Seq{a, b}), v)
    case Loop{a}:
      Empty.absurd(R(Loop{a}), v)

def valid_join(+p: Plan, +x: Trace, +y: Trace, -R: Plan -> Type, v: Valid(p, Join{x, y}), f: @a: Plan -> @b: Plan -> (Valid(a, x) & Valid(b, y)) -> R(Seq{a, b})) -> R(p):
  match p:
    case Dead{}:
      Empty.absurd(R(Dead{}), v)
    case Rest{}:
      Empty.absurd(R(Rest{}), v)
    case Act{}:
      Empty.absurd(R(Act{}), v)
    case Pick{a, b}:
      Empty.absurd(R(Pick{a, b}), v)
    case Seq{a, b}:
      f(a, b, v)
    case Loop{a}:
      Empty.absurd(R(Loop{a}), v)

def valid_finish(+p: Plan, -R: Plan -> Type, v: Valid(p, Finish{}), f: @a: Plan -> R(Loop{a})) -> R(p):
  match p:
    case Dead{}:
      Empty.absurd(R(Dead{}), v)
    case Rest{}:
      Empty.absurd(R(Rest{}), v)
    case Act{}:
      Empty.absurd(R(Act{}), v)
    case Pick{a, b}:
      Empty.absurd(R(Pick{a, b}), v)
    case Seq{a, b}:
      Empty.absurd(R(Seq{a, b}), v)
    case Loop{a}:
      f(a)

def valid_again(+p: Plan, +x: Trace, +y: Trace, -R: Plan -> Type, v: Valid(p, Again{x, y}), f: @a: Plan -> (Valid(a, x) & Valid(Loop{a}, y)) -> R(Loop{a})) -> R(p):
  match p:
    case Dead{}:
      Empty.absurd(R(Dead{}), v)
    case Rest{}:
      Empty.absurd(R(Rest{}), v)
    case Act{}:
      Empty.absurd(R(Act{}), v)
    case Pick{a, b}:
      Empty.absurd(R(Pick{a, b}), v)
    case Seq{a, b}:
      Empty.absurd(R(Seq{a, b}), v)
    case Loop{a}:
      f(a, v)

def zero_join(+a: Plan, +b: Plan, +x: Trace, +y: Trace, v: Valid(a, x) & Valid(b, y), eq: {Nat.add(cost(x), cost(y)) == 0n : Nat}, fx: @a: Plan -> Valid(a, x) -> {cost(x) == 0n : Nat} -> {nullable(a) == True{} : Bool}, fy: @b: Plan -> Valid(b, y) -> {cost(y) == 0n : Nat} -> {nullable(b) == True{} : Bool}) -> {nullable(Seq{a, b}) == True{} : Bool}:
  match v:
    case (vx, vy):
      and_zero(nullable(a), nullable(b), cost(x), cost(y), sum_zero(cost(x), cost(y), eq), ex => fx(a, vx, ex), ey => fy(b, vy, ey))

def zero_left(+a: Plan, +b: Plan, +x: Trace, v: Valid(a, x), f: @a: Plan -> Valid(a, x) -> {nullable(a) == True{} : Bool}) -> {nullable(Pick{a, b}) == True{} : Bool}:
  or_left(nullable(a), nullable(b), f(a, v))

def zero_right(+a: Plan, +b: Plan, +x: Trace, v: Valid(b, x), f: @b: Plan -> Valid(b, x) -> {nullable(b) == True{} : Bool}) -> {nullable(Pick{a, b}) == True{} : Bool}:
  or_right(nullable(a), nullable(b), f(b, v))

def Positive(n: Nat) -> Data:
  SuccType(n)

def Need(positive: Bool, n: Nat) -> Data:
  match positive:
    case False{}:
      Unit
    case True{}:
      Positive(n)

def split_cost(-A: Type, -R: Type, +n: Nat, v: A, fz: {n == 0n : Nat} -> A -> R, fs: Positive(n) -> A -> R) -> R:
  match n:
    case 0n:
      fz({==}, v)
    case 1n+k:
      fs(Unit{}, v)

def tail_positive(-m: Nat, -k: Nat, eq: {m == 0n : Nat}, pos: Positive(Nat.add(m, k))) -> Positive(k):
  %eq : Positive(Nat.add(_, k))
  pos

def cast_runs(+p: Plan, -m: Nat, -n: Nat, eq: {m == n : Nat}, r: Runs(p, m)) -> Runs(p, n):
  match r:
    case (d, (v, e)):
      (d, v, Equal.trans(Nat, cost(d), m, n, e, eq))

def optional_runs(+b: Bool, +p: Plan, +n: Nat, e: {b == True{} : Bool}, r: Runs(p, n)) -> Runs(optional(b, p), n):
  %Equal.sym(Bool, b, True{}, e) : Runs(optional(_, p), n)
  r

def seq_zero(+a: Plan, +b: Plan, +x: Trace, +y: Trace, v: Valid(a, x) & Valid(b, y), +eq: {cost(x) == 0n : Nat}, fz: (@p: Plan -> Valid(p, x) -> {cost(x) == 0n : Nat} -> {nullable(p) == True{} : Bool}), f: Valid(b, y) -> Runs(clean(b, True{}), cost(y))) -> Runs(clean(Seq{a, b}, True{}), Nat.add(cost(x), cost(y))):
  match v:
    case (vx, vy):
      cast_runs(clean(Seq{a, b}, True{}), cost(y), Nat.add(cost(x), cost(y)), Equal.sym(Nat, Nat.add(cost(x), cost(y)), cost(y), add_eq(cost(x), 0n, cost(y), cost(y), eq, {==})), right_runs(Seq{clean(a, True{}), clean(b, False{})}, optional(nullable(a), clean(b, True{})), cost(y), optional_runs(nullable(a), clean(b, True{}), cost(y), fz(a, vx, eq), f(vy))))

def seq_positive(+a: Plan, +b: Plan, +x: Trace, +y: Trace, v: Valid(a, x) & Valid(b, y), fx: Valid(a, x) -> Runs(clean(a, True{}), cost(x)), fy: Valid(b, y) -> Runs(clean(b, False{}), cost(y))) -> Runs(clean(Seq{a, b}, True{}), Nat.add(cost(x), cost(y))):
  match v:
    case (vx, vy):
      left_runs(Seq{clean(a, True{}), clean(b, False{})}, optional(nullable(a), clean(b, True{})), Nat.add(cost(x), cost(y)), join_runs(clean(a, True{}), clean(b, False{}), cost(x), cost(y), fx(vx), fy(vy)))

def need_tail(+positive: Bool, -m: Nat, -k: Nat, eq: {m == 0n : Nat}, nz: Need(positive, Nat.add(m, k))) -> Need(positive, k):
  match positive:
    case False{}:
      Unit{}
    case True{}:
      tail_positive(m, k, eq, nz)

def loop_zero(+a: Plan, +x: Trace, +y: Trace, +positive: Bool, v: Valid(a, x) & Valid(Loop{a}, y), eq: {cost(x) == 0n : Nat}, f: Valid(Loop{a}, y) -> Runs(clean(Loop{a}, positive), cost(y))) -> Runs(clean(Loop{a}, positive), Nat.add(cost(x), cost(y))):
  match v:
    case (vx, vy):
      cast_runs(clean(Loop{a}, positive), cost(y), Nat.add(cost(x), cost(y)), Equal.sym(Nat, Nat.add(cost(x), cost(y)), cost(y), add_eq(cost(x), 0n, cost(y), cost(y), eq, {==})), f(vy))

def loop_positive(+positive: Bool, +a: Plan, +x: Trace, +y: Trace, v: Valid(a, x) & Valid(Loop{a}, y), fx: Valid(a, x) -> Runs(clean(a, True{}), cost(x)), fy: Valid(Loop{a}, y) -> Runs(Loop{clean(a, True{})}, cost(y))) -> Runs(clean(Loop{a}, positive), Nat.add(cost(x), cost(y))):
  match positive v:
    case False{} Tuple{vx, vy}:
      loop_runs(clean(a, True{}), cost(x), cost(y), fx(vx), fy(vy))
    case True{} Tuple{vx, vy}:
      join_runs(clean(a, True{}), Loop{clean(a, True{})}, cost(x), cost(y), fx(vx), fy(vy))

def complete_rest(+positive: Bool, nz: Need(positive, 0n)) -> Runs(clean(Rest{}, positive), 0n):
  match positive:
    case False{}:
      (Quiet{}, Unit{}, {==})
    case True{}:
      Empty.absurd(Runs(Dead{}, 0n), nz)

def complete_finish(+positive: Bool, +a: Plan, nz: Need(positive, 0n)) -> Runs(clean(Loop{a}, positive), 0n):
  match positive:
    case False{}:
      (Finish{}, Unit{}, {==})
    case True{}:
      Empty.absurd(Runs(clean(Loop{a}, True{}), 0n), nz)

def complete_left(+a: Plan, +b: Plan, +positive: Bool, +x: Trace, v: Valid(a, x), nz: Need(positive, cost(x)), f: (@a: Plan -> @q: Bool -> Valid(a, x) -> Need(q, cost(x)) -> Runs(clean(a, q), cost(x)))) -> Runs(clean(Pick{a, b}, positive), cost(x)):
  left_runs(clean(a, positive), clean(b, positive), cost(x), f(a, positive, v, nz))

def complete_right(+a: Plan, +b: Plan, +positive: Bool, +x: Trace, v: Valid(b, x), nz: Need(positive, cost(x)), f: (@a: Plan -> @q: Bool -> Valid(a, x) -> Need(q, cost(x)) -> Runs(clean(a, q), cost(x)))) -> Runs(clean(Pick{a, b}, positive), cost(x)):
  right_runs(clean(a, positive), clean(b, positive), cost(x), f(b, positive, v, nz))

def complete_join(+positive: Bool, +a: Plan, +b: Plan, +x: Trace, +y: Trace, v: Valid(a, x) & Valid(b, y), +nz: Need(positive, Nat.add(cost(x), cost(y)))) -> (@p: Plan -> Valid(p, x) -> {cost(x) == 0n : Nat} -> {nullable(p) == True{} : Bool}) -> (@a: Plan -> @q: Bool -> Valid(a, x) -> Need(q, cost(x)) -> Runs(clean(a, q), cost(x))) -> (@a: Plan -> @q: Bool -> Valid(a, y) -> Need(q, cost(y)) -> Runs(clean(a, q), cost(y))) -> Runs(clean(Seq{a, b}, positive), Nat.add(cost(x), cost(y))):
  match positive v:
    case False{} Tuple{vx, vy}:
      fz => fx => fy => join_runs(clean(a, False{}), clean(b, False{}), cost(x), cost(y), fx(a, False{}, vx, Unit{}), fy(b, False{}, vy, Unit{}))
    case True{} v:
      split_cost(Valid(a, x) & Valid(b, y), (@p: Plan -> Valid(p, x) -> {cost(x) == 0n : Nat} -> {nullable(p) == True{} : Bool}) -> (@a: Plan -> @q: Bool -> Valid(a, x) -> Need(q, cost(x)) -> Runs(clean(a, q), cost(x))) -> (@a: Plan -> @q: Bool -> Valid(a, y) -> Need(q, cost(y)) -> Runs(clean(a, q), cost(y))) -> Runs(clean(Seq{a, b}, True{}), Nat.add(cost(x), cost(y))), cost(x), v,
            +eq => w => fz => fx => fy => seq_zero(a, b, x, y, w, eq, fz, vy => fy(b, True{}, vy, tail_positive(cost(x), cost(y), eq, nz))),
            px => w => fz => fx => fy => seq_positive(a, b, x, y, w, vx => fx(a, True{}, vx, px), vy => fy(b, False{}, vy, Unit{})))

def complete_again(+a: Plan, +positive: Bool, +x: Trace, +y: Trace, v: Valid(a, x) & Valid(Loop{a}, y), +nz: Need(positive, Nat.add(cost(x), cost(y)))) -> (@a: Plan -> @q: Bool -> Valid(a, x) -> Need(q, cost(x)) -> Runs(clean(a, q), cost(x))) -> (@a: Plan -> @q: Bool -> Valid(a, y) -> Need(q, cost(y)) -> Runs(clean(a, q), cost(y))) -> Runs(clean(Loop{a}, positive), Nat.add(cost(x), cost(y))):
  split_cost(Valid(a, x) & Valid(Loop{a}, y), (@a: Plan -> @q: Bool -> Valid(a, x) -> Need(q, cost(x)) -> Runs(clean(a, q), cost(x))) -> (@a: Plan -> @q: Bool -> Valid(a, y) -> Need(q, cost(y)) -> Runs(clean(a, q), cost(y))) -> Runs(clean(Loop{a}, positive), Nat.add(cost(x), cost(y))), cost(x), v,
    +eq => w => fx => fy => loop_zero(a, x, y, positive, w, eq, vy => fy(Loop{a}, positive, vy, need_tail(positive, cost(x), cost(y), eq, nz))),
    px => w => fx => fy => loop_positive(positive, a, x, y, w, vx => fx(a, True{}, vx, px), vy => fy(Loop{a}, False{}, vy, Unit{})))

def TraceFacts(+d: Trace) -> Type:
  (@p: Plan -> @positive: Bool -> Valid(clean(p, positive), d) -> Runs(p, cost(d))) & (@a: Plan -> @b: Plan -> Valid(Seq{clean(a, True{}), clean(b, False{})}, d) -> Runs(Seq{a, b}, cost(d)))

def sound_part(-d: Trace, +p: Plan, +positive: Bool, v: Valid(clean(p, positive), d), fs: TraceFacts(d)) -> Runs(p, cost(d)):
  match fs:
    case (f, tail): f(p, positive, v)

def join_part(-d: Trace, +a: Plan, +b: Plan, v: Valid(Seq{clean(a, True{}), clean(b, False{})}, d), fs: TraceFacts(d)) -> Runs(Seq{a, b}, cost(d)):
  match fs:
    case (unused, f): f(a, b, v)

def trace_facts(+d: Trace) -> TraceFacts(d):
  match d:
    case Quiet{}:
      ((p => q => v => sound_quiet(p, q, v)), (a => b => v => Empty.absurd(Runs(Seq{a, b}, cost(Quiet{})), v)))
    case Moved{}:
      ((p => q => v => sound_moved(p, q, v)), (a => b => v => Empty.absurd(Runs(Seq{a, b}, cost(Moved{})), v)))
    case Finish{}:
      ((p => q => v => sound_finish(p, q, v)), (a => b => v => Empty.absurd(Runs(Seq{a, b}, cost(Finish{})), v)))
    case TakeR{x}:
      ((p => q => v => sound_right(p, q, x, v, a => c => e => sound_part(x, a, c, e, trace_facts(x)))), (a => b => v => Empty.absurd(Runs(Seq{a, b}, cost(TakeR{x})), v)))
    case Join{x, y}:
      ((p => q => v => sound_join(p, q, x, y, v, a => c => e => sound_part(x, a, c, e, trace_facts(x)), a => c => e => sound_part(y, a, c, e, trace_facts(y)))), (a => b => v => sound_join_pair(a, b, x, y, v, c => vx => sound_part(x, c, True{}, vx, trace_facts(x)), c => vy => sound_part(y, c, False{}, vy, trace_facts(y)))))
    case Again{x, y}:
      ((p => q => v => sound_again(p, q, x, y, v, a => c => e => sound_part(x, a, c, e, trace_facts(x)), a => c => e => sound_part(y, a, c, e, trace_facts(y)))), (a => b => v => Empty.absurd(Runs(Seq{a, b}, cost(Again{x, y})), v)))
    case TakeL{x}:
      ((p => q => v => sound_left(p, q, x, v, a => c => e => sound_part(x, a, c, e, trace_facts(x)), a => b => e => join_part(x, a, b, e, trace_facts(x)))), (a => b => v => Empty.absurd(Runs(Seq{a, b}, cost(TakeL{x})), v)))

def zero_nullable(+d: Trace, +p: Plan, v: Valid(p, d), eq: {cost(d) == 0n : Nat}) -> {nullable(p) == True{} : Bool}:
  match d:
    case Quiet{}:
      valid_quiet(p, p => {nullable(p) == True{} : Bool}, v, {==})
    case Moved{}:
      Empty.absurd({nullable(p) == True{} : Bool}, succ_zero(0n, eq))
    case Finish{}:
      valid_finish(p, p => {nullable(p) == True{} : Bool}, v, a => {==})
    case TakeR{x}:
      valid_right(p, x, p => {nullable(p) == True{} : Bool}, v, a => b => vx => zero_right(a, b, x, vx, c => e => zero_nullable(x, c, e, eq)))
    case Join{x, y}:
      valid_join(p, x, y, p => {nullable(p) == True{} : Bool}, v, a => b => w => zero_join(a, b, x, y, w, eq, c => vc => ec => zero_nullable(x, c, vc, ec), c => vc => ec => zero_nullable(y, c, vc, ec)))
    case Again{x, y}:
      valid_again(p, x, y, p => {nullable(p) == True{} : Bool}, v, a => w => {==})
    case TakeL{x}:
      valid_left(p, x, p => {nullable(p) == True{} : Bool}, v, a => b => vx => zero_left(a, b, x, vx, c => e => zero_nullable(x, c, e, eq)))

def complete(+d: Trace, +p: Plan, +positive: Bool, v: Valid(p, d), nz: Need(positive, cost(d))) -> Runs(clean(p, positive), cost(d)):
  match d:
    case Quiet{}:
      valid_quiet(p, p => Runs(clean(p, positive), 0n), v, complete_rest(positive, nz))
    case Moved{}:
      valid_moved(p, p => Runs(clean(p, positive), 1n), v, (Moved{}, Unit{}, {==}))
    case Finish{}:
      valid_finish(p, p => Runs(clean(p, positive), 0n), v, a => complete_finish(positive, a, nz))
    case TakeR{x}:
      valid_right(p, x, p => Runs(clean(p, positive), cost(x)), v, a => b => vx => complete_right(a, b, positive, x, vx, nz, c => q => vc => nc => complete(x, c, q, vc, nc)))
    case Join{x, y}:
      valid_join(p, x, y, p => Runs(clean(p, positive), cost(d)), v, a => b => w => complete_join(positive, a, b, x, y, w, nz, c => vc => eq => zero_nullable(x, c, vc, eq), c => q => vc => nc => complete(x, c, q, vc, nc), c => q => vc => nc => complete(y, c, q, vc, nc)))
    case Again{x, y}:
      valid_again(p, x, y, p => Runs(clean(p, positive), cost(d)), v, a => w => complete_again(a, positive, x, y, w, nz, c => q => vc => nc => complete(x, c, q, vc, nc), c => q => vc => nc => complete(y, c, q, vc, nc)))
    case TakeL{x}:
      valid_left(p, x, p => Runs(clean(p, positive), cost(x)), v, a => b => vx => complete_left(a, b, positive, x, vx, nz, c => q => vc => nc => complete(x, c, q, vc, nc)))

def normalize(p):
  (proper_clean(p, False{}), (n => ((r => runs_elim(clean(p, False{}), n, Runs(p, n), r, d => v => e => cast_runs(p, cost(d), n, e, sound_part(d, p, False{}, v, trace_facts(d))))), (r => runs_elim(p, n, Runs(clean(p, False{}), n), r, d => v => e => cast_runs(clean(p, False{}), cost(d), n, e, complete(d, p, False{}, v, Unit{})))))))
