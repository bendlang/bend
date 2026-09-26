# S4 C independent review: reject the proposed unit

Reviewed the 17-helper design committed at `1187708` against
`selfhost/build/phase7/s4/candidate-b01-project/src`. No production source was
changed. The ordinary call-graph premises hold, but the required local matching
is unsupported by the pinned language. **Fourteen fusions are blocked; the other
three provide only 23 prospective nonblank lines**, below the 100-line gate.
Do not implement this unit or alter the language to rescue its budget.

## Decisive syntax evidence

Pinned upstream revision: `6018e28ecc67cf1fffc0c20c64b11023474c2df8`.
`bend2/bend.ts` SHA256:
`461e0c5dd12789ea293daf01c1cb5b8504f8dfcf8d38b85744665a77ecc63168`.

- `body_flatten`, lines 2821–2829: a local binding followed by matching that
  binding does not produce the required lambda and is rejected at line 2825:
  “a match cannot scrutinize a local binder: give it its own def”.
- Constructor-pattern locals are not an escape hatch. Lines 2817–2819 lower
  `Box{value} = make(x)` through `match_flatten`. Its computed scrutinee is rejected
  at lines 2724–2725. Adding `+` does not change the syntactic restriction.

The parent authorized a tiny falsifier after this read-only finding. The fresh
[falsifier report](c-syntax-falsifier-01/report.json) preserves the runner, three
source files, identities and exact diagnostics. On CPU 1/nice 10 with pinned Node
24.18.0 and a verified clean upstream checkout:

| Source form | Observed result |
| --- | --- |
| Existing helper matches its `Box` parameter | Loads and checks |
| `+made = make(x)`, then `match made` | Local-binder parse/flatten error |
| `Box{value} = make(x)` | Computed-scrutinee parse/flatten error |

All three expected outcomes passed; process exit was zero. No Bend compiler/API,
generated artifact, broad build or performance comparison was run for this check.

## Selected helper mapping

Line numbers below identify helper definitions in the B01 source, not S0.

| Helper → caller | Module:line | Outcome for the proposed body fusion |
| --- | --- | --- |
| `f_ascii_space_code` → `f_ascii_space` | `front/lexer.bend:294` | Match-free; syntactically viable |
| `f_all_body` → `f_all_domain` | `front/parser.bend:320` | Blocked computed `FParsed` match |
| `f_equation_type` → `f_equation` | `front/parser.bend:379` | Blocked computed `FParsed` match |
| `f_matcher_tail` → `f_matcher_arm` | `front/parser.bend:456` | Blocked computed `FParsed` match |
| `f_let_body` → `f_let_value` | `front/declarations.bend:508` | Blocked computed `FParsed` match |
| `ff_miss_done` → `ff_hit_done` | `front/flatten.bend:197` | Blocked computed `FFlatten` match |
| `f_do_tail` → `f_do_value` | `front/sugar.bend:194` | Blocked computed `FParsed` match |
| `f_rewrite_body` → `f_rewrite_motive` | `front/sugar.bend:240` | Blocked computed `FParsed` match |
| `f_char_decoded` → `f_char_literal` | `front/unicode.bend:68` | Blocked computed `FDecoded` match |
| `f_float_read` → `f_float` | `front/literals_arrays.bend:82` | Blocked computed two-arm `Maybe` match |
| `f_array_size` → `f_array_type` | `front/literals_arrays.bend:106` | Blocked computed `FParsed` match |
| `f_fresh_result_end` → `f_fresh_result` | `front/freshen.bend:53` | Blocked computed `FFreshDefs` match |
| `f_adt_fill` → `f_adt` | `front/families.bend:60` | Match-free; syntactically viable |
| `f_graph_finish_alias` → `f_graph_finish` | `load/graph.bend:223` | Match-free; syntactically viable |
| `f_main_result_names` → `f_main_names` | `load/graph.bend:278` | Blocked computed `FResult` match |
| `f_qual_result` → `f_parse_at` | `load/modules.bend:108` | Blocked computed `FResult` match |
| `f_loaded_result` → `f_load` | `load/modules.bend:238` | Blocked computed `FLoaded` match |

## Quantity, capture, sequencing and dependencies

There is no additional caller-pattern quantity promotion to make in these cases.
`FParsed` declares `+term/+rest` (`front/parser.bend:3–4`), and `FGraph` declares
`+book`. Its unmarked case variables already inherit unrestricted field demand.
Pinned `bend.ts:3611` derives that demand from constructor fields; explicit `+`
at line 3494 promotes an otherwise affine field. Ordinary captured parameters
already have unrestricted laws. This corrects the review's initial quantity
concern; it does not resolve the local-match rejection.

For the three viable forms, share `Char.to_u32(c)` as `+code`; evaluate `da(d)`
before `f_leading_quants(dt(d))`, sharing the latter as `+g`; and compute
`+aliasedBook = f_alias_defs(book, imports)` inside the existing `FGraph` arm.
Both module processing and declaration counting must use that aliased book.
The graph's original `prior`, `err` and `done` remain unchanged. No expression
moves out of a selected arm or into a lazy `f_choose` branch.

The blocked forms also have real capture obligations: `f_rewrite_body.motive`
means the newly constructed nested lambda, `f_qual_result.ns` means the caller's
`namespace`, and inner `ts`, `next` and `book` mean the new remainder/counter/book.
Parser-assigned fresh binder IDs permit intentional shadowing; a textual rewrite
must still distinguish those meanings. The legacy loader's `f_fresh_result` step
must remain after the existing `f_load_module`, even on a rejected result.

A conservative lexical dependency scan of all 59 manifest modules found 1,433
definitions, exactly one production caller for every selected helper, and no
selected helper able to reach itself. No selected name occurs in B01's `.mjs`,
`.js`, `.ts` or `.json` tools/tests. Historical build outputs and design/evidence
references are not public roots. Eliminating the three match-free boundaries
adds no recursive continuation or new forward-law requirement: caller/helper
definitions are adjacent, except for unrelated `f_ascii_ident_code`. Required
body callees already precede the caller or have retained laws.

## Budget correction

The original boundary arithmetic is reproducible: the 17 laws, `@unsafe`/`def`
headers and old call lines contain **139 nonblank lines / 3,353 bytes**, excluding
retained bodies and separator blank lines. Subtracting 20 computed-argument
bindings gives 119 hypothetical nonblank lines only if all shapes are legal.
They are not.

For the three viable shapes, preserving body text except graph indentation and
the two `book`→`aliasedBook` references gives the following prospective cost.
These counts use `+code`, `+arity`, `+g`, `+aliasedBook`, and remove one existing
blank separator after each deleted law and helper definition. No source edit was
made or claimed as an achieved saving.

| Helper boundary | Computed locals | Net nonblank | Net physical | Net bytes |
| --- | ---: | ---: | ---: | ---: |
| `f_ascii_space_code` | 1 | 5 | 7 | 100 |
| `f_adt_fill` | 2 | 7 | 9 | 152 |
| `f_graph_finish_alias` | 1 | 11 | 13 | 305 |
| Total | 4 | **23** | **29** | **557** |

This fails both the 100-nonblank and 1,800-byte gates. The three potential helper
interfaces are not three major compiler concepts; no new representation or
algorithm is retired. C contributes **zero achieved source or context savings**.

## B01 source identities

Manifest SHA256: `08c4c055006c8564139a88b793aadfe1dc0b6d100b4c3f2b26ccf8005f8d65c7`.
All paths below are relative to the B01 `src` directory.

| Module | SHA256 |
| --- | --- |
| `front/lexer.bend` | `aed5103d42d33312f6e5e873ae786646be42f7332f04a80b78ab0cca70d31f31` |
| `front/parser.bend` | `c2ea3940944434dea9d52c146e998831288b5d4bc1d45e3ce80030bf89c91129` |
| `front/declarations.bend` | `ea488d9b26663285b66d7a625f9eb1488c872f0f003590ba9b49cae08269a2a7` |
| `front/flatten.bend` | `0eb3b45ddec363d21e715b491cd19698e4dd6a50b259800edad42dd1e4338392` |
| `front/sugar.bend` | `ce5ef60fada67616142961f07a07c0c2a29283e4b553028480ccf7810687d547` |
| `front/unicode.bend` | `ca1576b9c9a1992157c98bb66da63ca45aff204c724d902e2e88c5ee87662a51` |
| `front/literals_arrays.bend` | `6468fe13b93ebb879c81ac8d18e2e99d4de16dabbf7dc0cc6f389e4a95343981` |
| `front/freshen.bend` | `26abdc135603675f2ab3dffc3c049a20982500907d8819a3fdfea42ba917136a` |
| `front/families.bend` | `8bf0c69ad09a5d8793f56a5f6f967838857fbf43b8d2f2806521d801a1fd66f0` |
| `load/graph.bend` | `6a5ab7cecafed72e49c06fc912127d87c9ccecea9cd0b341eb430ac5bee284bc` |
| `load/modules.bend` | `a7fd4c42cd13cc8165cec2a4e9f71f070fb10703910f7780064bd533aaa711fe` |
