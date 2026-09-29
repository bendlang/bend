# Phase16: exact template keys and growth accounting

The canonical encoder closes the compact literal prototype's memo boundary:
61 direct observations, 29 actual source-instance sets, and both saved growth
refusals agree exactly with the pinned TypeScript compiler. Its checked build
also passes the maintained 36-case gate, with the same two inherited strict
text differences. The production handoff is prepared for root integration;
these scoped results do not claim complete conformance or installation.

The previous key format retained incidental reference token IDs, so repeated
`F32.neg(0.0)` calls created two instances where upstream creates one. It also
measured a shorter custom serialization in scalar characters. Ten of twenty
frozen string-size controls disagreed with upstream's 32768 UTF16-unit JSON
limit. Earlier work had already shown why changing this limit accidentally is
wrong: a shorter encoding moved the `grow_double` refusal from `grow~9` to
`grow~10`.

The replacement emits the exact field order and JSON quoting used by pinned
`term_key(term_lower(argument))`. The same string serves as the memo key and
input to a tail-safe UTF16 length walk. Multiple arguments retain upstream's
newline separators. There is one semantic term visitor, using the existing
binder environment to turn globally fresh variable IDs into lexical indices
and binder names. It ignores source intervals and reference token IDs, preserves
annotations and literal syntax identity, forces variable value cells, and uses
the existing substitution operation. It introduces no new normalization or
checker. Binder spelling remains significant, as it is upstream; arbitrary
alpha-renaming is not silently equated.

The literal representation is necessary to distinguish a U32 literal from its
written constructor tree. The representation owner's explicit Lambda quantity
presence is also necessary: an existential binder and a written affine lambda
can be semantically equivalent while their upstream memo JSON differs. The
encoder reads this metadata rather than guessing it from ranges or names.
F32 literals contain unsigned bits upstream, so positive and negative zero bit
patterns remain distinct.

The first encoder attempt was genuinely checked and passed all 61 direct term
controls. Actual parsed controls then isolated one metadata reconstruction loss:
28 of 29 instance sets agreed, but `f_scope_lambda_var` forced an absent Lambda
quantity to become present. The representation owner's source03 correction
preserves this flag through flattening. Encoder source02, built from that
corrected representation, passes all 29 parsed cases. Both attempts and their
raw results remain available.

The final owned gates are:

- `checker-key-json-direct-02`: 61 exact observations, including all supported
  semantic constructors, lexical/shadowed/parallel-let binders, absent/present
  Lambda quantities, source-reachable reference flags, negative free-variable
  sentinel, F32 bit payloads, all five JSON short escapes, NUL/U+001F, astral
  characters, isolated surrogate direct strings, and all 20 size boundaries.
- `checker-key-json-instances-02`: 29 exact instance-name sets, including saved
  renamed/same-name lambdas, references at different text positions, semantic
  value distinctions, literal/constructor distinctions, repeated negative F32
  expressions, nested calls, and actual parsed Lambda presence alternatives.
- `checker-key-json-growth-01`: both diagnostics are entirely exact, including
  context, snippet and caret. Double growth refuses at `grow~9`; depth-limited
  growth refuses at `grow~63`.

The encoder changes one Bend module by +102 physical lines, +87 nonblank lines,
+7,057 bytes, +16 definitions and -1 law. It replaces the old short-key visitor;
JSON escaping and shared field/list helpers account for the extra code. Runtime
work is one serialization per closed template argument followed by one length
walk. There is no additional whole-book traversal or separate approximate key.
No encoder-specific timing claim is made here. The representation owner's
KLambda/transport costs are reported separately.

`checker-key-json-handoff-01` contains the production project, a one-module memo
patch, a full patch against `literal-context-source-04`, and identities for every
parent/final file. It composes the checked encoder module with the representation
owner's source04, including its three quantity-presence demand guards. Its host
is source04's production host unchanged: the four encoder probe exports are
absent. This exact composition was deliberately left for the root's genuine
integration build; it does not reuse a prior API as proof that new source was
checked.

The raw TypeScript `Ref` factory can construct an explicit `b:false`, but pinned
source producers create only absent or true flags. That artificial factory state
is outside the parsed-source memo claim. Invalid internal-only terms retain a
distinct defensive encoding; they are not silently collapsed. The existing
term-level specialization chronology gap is unchanged. Final full frontend,
backend, history and controlled cost gates belong to the root integration.

One report-generation attempt incorrectly required the full-corpus `complete`
flag on the deliberately selected two-fixture growth probe. It stopped before
writing the implementation report. Its tool and failure record are retained;
the corrected reporter requires `selectedComplete` and both exact rows. No raw
compiler result or oracle was changed.

See [the prospective design](../../design/phase16/checker-canonical-memo-json.md)
and [the identity-bound report](checker-canonical-memo-json.json) for the frozen
source, attempt and gate references.
