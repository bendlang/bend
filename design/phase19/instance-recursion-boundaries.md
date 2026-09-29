# Same-key recursion boundaries

Freeze paired controls for a template calling itself with the same closed key and
unchanged runtime argument (safe refusal), its `@unsafe` type-accepted counterpart
(with proof-trust refusal retained), the existing decreasing same-key case, and
an unsafe cross-instance cycle derived from the pinned cycle witness. The latter
must still refuse: unsafe changes decreasing self-call policy, not active
cross-instance memo ownership. These supplement the original22, which already
retain both growth refusals and the safe active cross-cycle. All strict error
text, phase, acceptance and trust axes remain compared; no execution of the
nonterminating unsafe body is requested.
