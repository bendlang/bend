# proof_typed_eval: the proofs. opt_complete is an induction over the
# program: each compound case rewrites the Ford equation so the folder
# and the evaluator compute, then rewrites its subterms' opt into
# literals through the induction hypotheses. opt_sound follows from
# it, since the literal of a value evaluates to that value.

import Base
import ./main.bend as TE
import ./LAWS.bend as Laws

# Completeness
# ------------

# a fold_if on a literal condition is the literal of the branch pick
# chooses
def lit_pick(-t: TE.Ty, v: Bool, -x: TE.Val(t), -y: TE.Val(t)) -> {TE.lit(t, TE.pick(t, v, x, y)) == TE.fold_if(t, TE.Bit{v, {==}}, TE.lit(t, x), TE.lit(t, y)) : TE.Expr<t>}:
  match v:
    case True{}:
      {==}
    case False{}:
      {==}

def Laws.opt_complete(t, e):
  match e:
    case TE.Num{n, eq}:
      %E@eq : {TE.lit(_, TE.eval(_, TE.Num{n, E})) == TE.opt(_, TE.Num{n, E}) : TE.Expr<_>}
      {==}
    case TE.Bit{b, eq}:
      %E@eq : {TE.lit(_, TE.eval(_, TE.Bit{b, E})) == TE.opt(_, TE.Bit{b, E}) : TE.Expr<_>}
      {==}
    case TE.Add{+a, +b, eq}:
      %E@eq : {TE.lit(_, TE.eval(_, TE.Add{a, b, E})) == TE.opt(_, TE.Add{a, b, E}) : TE.Expr<_>}
      %Laws.opt_complete(TE.TNum{}, a) : {TE.Num{Nat.add(TE.eval(TE.TNum{}, a), TE.eval(TE.TNum{}, b)), {==}} == TE.fold_add(_, TE.opt(TE.TNum{}, b)) : TE.Expr<TE.TNum{}>}
      %Laws.opt_complete(TE.TNum{}, b) : {TE.Num{Nat.add(TE.eval(TE.TNum{}, a), TE.eval(TE.TNum{}, b)), {==}} == TE.fold_add(TE.Num{TE.eval(TE.TNum{}, a), {==}}, _) : TE.Expr<TE.TNum{}>}
      {==}
    case TE.IsZero{+a, eq}:
      %E@eq : {TE.lit(_, TE.eval(_, TE.IsZero{a, E})) == TE.opt(_, TE.IsZero{a, E}) : TE.Expr<_>}
      %Laws.opt_complete(TE.TNum{}, a) : {TE.Bit{TE.is_zero(TE.eval(TE.TNum{}, a)), {==}} == TE.fold_zero(_) : TE.Expr<TE.TBool{}>}
      {==}
    case TE.If{+c, +a, +b}:
      %Laws.opt_complete(TE.TBool{}, c) : {TE.lit(t, TE.pick(t, TE.eval(TE.TBool{}, c), TE.eval(t, a), TE.eval(t, b))) == TE.fold_if(t, _, TE.opt(t, a), TE.opt(t, b)) : TE.Expr<t>}
      %Laws.opt_complete(t, a) : {TE.lit(t, TE.pick(t, TE.eval(TE.TBool{}, c), TE.eval(t, a), TE.eval(t, b))) == TE.fold_if(t, TE.Bit{TE.eval(TE.TBool{}, c), {==}}, _, TE.opt(t, b)) : TE.Expr<t>}
      %Laws.opt_complete(t, b) : {TE.lit(t, TE.pick(t, TE.eval(TE.TBool{}, c), TE.eval(t, a), TE.eval(t, b))) == TE.fold_if(t, TE.Bit{TE.eval(TE.TBool{}, c), {==}}, TE.lit(t, TE.eval(t, a)), _) : TE.Expr<t>}
      lit_pick(t, TE.eval(TE.TBool{}, c), TE.eval(t, a), TE.eval(t, b))

# Soundness
# ---------

# the literal of a value evaluates to that value
def eval_lit(t: TE.Ty, -v: TE.Val(t)) -> {TE.eval(t, TE.lit(t, v)) == v : TE.Val(t)}:
  match t:
    case TE.TNum{}:
      {==}
    case TE.TBool{}:
      {==}

def Laws.opt_sound(t, e):
  %Laws.opt_complete(t, e) : {TE.eval(t, _) == TE.eval(t, e) : TE.Val(t)}
  eval_lit(t, TE.eval(t, e))
