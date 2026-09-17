# proof_typed_eval: the laws. The human states them; PROOF.bend must
# prove them.

import Base
import ./main.bend as TE

# LAW: the optimizer keeps the meaning of every program: at every
# object type t, opt(e) evaluates to what e evaluates to
law opt_sound:
  for  t: TE.Ty
  for  e: TE.Expr<t>
  {TE.eval(t, TE.opt(t, e)) == TE.eval(t, e) : TE.Val(t)}

# LAW: the optimizer computes every program: a program has no
# variables, so opt(e) is the literal of the value of e
law opt_complete:
  for -t: TE.Ty
  for  e: TE.Expr<t>
  {TE.lit(t, TE.eval(t, e)) == TE.opt(t, e) : TE.Expr<t>}
