# Keep an invalid binder marker distinct from a real variable

`+x` in term position is an unbound binder marker, even when a lexical x exists.
The frontend already represents this as FUnboundVar, but freshening converts it
to Var with a newly allocated positive ID. That avoids capture but invents a
binding identity; the pinned diagnostic correctly prints the unbound index -1.
Using a U32 sentinel would collide with real IDs or affect maximum-ID arithmetic.

Retain the existing invalid-only FUnboundVar through freshening instead. It never
becomes a valid checked term. In inference's existing unsupported-term fallback,
recognize that marker as the existing unbound-variable error. Render that error's
observed term explicitly as its name with ^-1. Ordinary Var handling, substitution,
lexical IDs and closed-template argument validation stay unchanged. The marker
cannot be mistaken for an in-scope Var, and no new type or term variant is added.
No comparison is added to the common inference branches.

Freeze the two corpus failures plus nearby same-name/shadowed/no-binding markers,
markers inside closed and open template lambdas, ordinary variable success,
ordinary reusable binder syntax and marked datatype success. Require exact paired
results where their producer is already precise; retain unrelated known parser
gaps explicitly. Check normal and expected-type inference and preserve marker
origin endpoints. Use a genuine checked build, focused validation, and the new
adjacent-checkpoint full gate. No invalid marker may reach successful emission.
This experiment leaves the broader template-checking chronology gap untouched.

The first paired candidate exposes a necessary display qualification: TypeScript
prints ^-1 only when that spelling also appears in the displayed context. An
otherwise unbound x prints simply x, including an outer name excluded from a
closed template argument's context. Source02 must reuse `dg_scope` and `kp_bound`
for exactly that decision, on the error path only. Its semantic invalid marker
remains distinct. The proposed +Nat positive was invalid: only a datatype with
leading quantity parameters supports +. Replace that boundary prospectively with
the already validated +Token fixture, retaining the original failed contract.
