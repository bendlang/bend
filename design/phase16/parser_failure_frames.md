# Rejected-parser frame inventory

Read-only companion to parser_failure_chronology.md. Sources: frozen wave8 and
context source04, plus pinned TypeScript b2111cf. No compiler changes are proposed
as already complete. The module FParseScope alone is insufficient: its fields
are prior, index, ns, aliases and enabled; it carries no lexical environment.

| Enclosing construct | Existing Bend callback and available data | What a selected failure must retain |
| --- | --- | --- |
| Definition parameters | f_def_body has pars, type, name, local book, imports, unsafe and contextual scope | All original parameter identities, quantities and ranges; current declaration scope. It currently discards the failing declaration. |
| Ordinary/dotted lambda | f_binary receives left term, operator endpoints and parsed RHS; f_lambda_valid runs afterward | Binder eligibility precedes body parsing. Preserve original binder identity and outer scope; do not introduce an invalid qualified binder. Current ordinary-error shortcut drops it. |
| Dependent All/Exists | f_all_domain and f_all_body know binder name/id/quantity, domain and body | Domain is outside the new binding, body is inside it. Generated Exists lambda is the same lexical boundary. |
| Sequential local or erased local | f_let_value knows pattern and parsed value; f_let_body knows pattern, value, continuation | Left expression first, then RHS, then pattern validation, then continuation under the new bindings. f_let_body currently drops all this on continuation Error. A frame must retain eligibility, not merely append a name. |
| Parallel/typed local | f_parallel_values/body retain patterns and all RHS values; f_typed_let_try retains type and value | All pattern expressions and values precede eligibility. Parallel/typed mode requires names. Existing Parallel retains its body Error structurally, but its scope chronology must remain explicit. |
| Match row | f_case_pats/body retain heads, previous rows, current patterns and row body | Validate current patterns before its body. Earlier rows' parse-time validation may precede the selected failure. Do not flatten the enclosing match while a case body is unfinished. Bound fields retain original identities/ranges. |
| Do bind or typed do let | f_do_value/tail retain monad, binder, type, value, purity and continuation | Type/value precede the new binder; continuation sees it. A do-return opens no binder. Keep monad/type metadata for observed desugared syntax. |
| Rewrite motive | f_rewrite_motive builds nested lambdas for `_` and optional named proof | Both temporary bindings exist only in the motive. TypeScript closes them before parsing the rewrite body; leaking them into the body is a correctness error. |
| Telescope prefixes | f_tele_type/next and their callers retain accumulated earlier cells | Parameter, datatype and constructor-field type expressions can contain grouped bodies. Earlier cells are in scope, the current cell is not opened until its type finishes. A transport limited to def bodies is insufficient. |
| Law clauses and refinement | f_law_type/where retain earlier clauses and current binder/domain | Earlier clauses remain in scope. A where predicate temporarily opens its own binder; later clauses see the normal declaration binder. |
| Group, annotation, application and collection | Their callbacks introduce no lexical names | Preserve the selected failure and its existing frames; do not choose later delimiter/argument errors over it. Nested grouped bodies can perform flattening before the outer term resumes. |
| Module completion | FParseScope and f_complete_source retain module namespace, resolved aliases, prior declarations and source interval | Use exactly the declarations available at the checkpoint and original lexical spellings. An alias-shadowed local call and a global alias call render differently. |

The relevant distinction is parser stage, not whether a node is structurally
inside another node. TypeScript's parse_patt happens before a local/case
continuation, but body_flatten happens only after the entire corresponding body
parse returns. Parenthesized bodies call body_flatten before the closing `)`;
therefore a nested completed match can correctly beat a later delimiter error.

A rejected-path resolver could fold explicit frames from outer to inner and
reuse existing scope/pattern operations. It must validate an outer local's
pattern before accepting the inner selected failure, and preserve any earlier
inner Error in left/RHS expressions. Retaining only lexical names would miss
these earlier checkpoints. Retaining arbitrary raw Local/Match trees and doing
normal flattening would run some later checkpoints too early. Both shortcuts
are rejected.

Before implementation, demonstrate one small common frame operation for each
row above and a rule for distinguishing parse-time validation from flattening.
If those operations require a second implementation of parse_body, use a single
contextual term parser instead. Error payloads may contain explicit compiler
records; they may not hide scope in ids/quantities/origin fields or infer it from
messages. Successful parsing must not allocate these rejection-only records or
walk bodies an extra time.
