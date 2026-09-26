# S4 B01: original S0 source and review-context recount

This static audit compares B01 with **the original S0 baseline**,
`fc509f4cd5bf00b2cd600922b4e40c5d7b9a1e01`. B01 has less production source,
but its parser review context grows when the full files now owning shared
operations are included. A smaller same-path total alone does not establish a
smaller context for the original task. This report makes no correctness,
performance, cognitive-complexity or milestone claim.

[Machine-readable counts](context-counts.json) retain every original logical
path, rationale, baseline/current hash, physical/nonblank/byte count, source
location and delta. Source is read from
`selfhost/build/phase7/s4/candidate-b01-project`; no candidate build or compiler
execution was performed for this audit. Its validation status is owned by the
separate S4 report.

## Production source

Membership is the same 59 modules in `src/compiler.json`, whose SHA-256 remains
`08c4c055006c8564139a88b793aadfe1dc0b6d100b4c3f2b26ccf8005f8d65c7`.

| Measure | Original S0 | B01 | B01 minus S0 |
| --- | ---: | ---: | ---: |
| Physical lines | 16,509 | 14,667 | -1,842 |
| Nonblank lines | 13,803 | 12,505 | -1,298 |
| Bytes | 509,937 | 470,062 | -39,875 |
| Definitions | 1,526 | 1,433 | -93 |
| Laws | 1,280 | 789 | -491 |
| Datatypes | 66 | 61 | -5 |

The physical reduction is 11.16%; nonblank reduction is 9.40%; byte reduction is
7.82%. **544 removed physical lines are blank separators** and receive no
conceptual simplification credit. Law-to-signature migration reduces authored
declaration boundaries; these declaration totals do not count semantic rules.

## Original fixed context paths

The [S0 parser set](../s0-evidence/parser-context.json) and
[S0 checker/backend sets](../s0-evidence/contexts-root.json) are retained in full.
Every `selfhost/src/` entry maps to the same relative file in B01, including
source-local backend tests and documentation. Other original entries use their
complete current repository files. No original test, fixture, contract or
historical evidence entry is dropped. The task sets overlap and must not be
summed.

| Original fixed task | Files | S0 physical / nonblank / bytes | B01 physical / nonblank / bytes | Delta physical / nonblank / bytes |
| --- | ---: | ---: | ---: | ---: |
| Parser first-error choice | 30 | 5,716 / 4,851 / 198,816 | 5,234 / 4,533 / 190,925 | -482 / -318 / -7,891 |
| Dependent application check | 9 | 3,156 / 2,652 / 106,647 | 2,764 / 2,389 / 98,075 | -392 / -263 / -8,572 |
| Constructor lowering across JS/native | 15 | 3,397 / 2,857 / 126,336 | 3,162 / 2,707 / 121,876 | -235 / -150 / -4,460 |

The original parser record omitted nonblank counts. They are recovered from
bytes matching its frozen hashes. Its two Phase 6 historical evidence files
were not tracked at S0; their current bytes exactly match the S0 hashes and
supply those original counts. All other baseline bytes come from S0 Git.

The current `CONFORMANCE.md` adds 11 physical / 9 nonblank lines / 648 bytes;
`ARCHITECTURE.md` adds 6 / 5 / 415. Those changes are included, not replaced with
smaller historical copies. Every other original nonproduction context item is
byte-identical to its S0 entry.

## Replacement-owner supplement

The frozen parser policy requires comparing replacement files serving the same
roles. Two B01 owners fall outside its original 30 paths:

- `core/normalize.bend`: `norm_join` replaces the concatenation worker formerly
  inside `front/elaborate.bend`, also called from `front/sugar.bend`.
  Whole-file cost: **534 / 463 / 16,605**.
- `load/seed.bend`: `fs_load` and its worker family now perform the ordinary
  graph traversal reached through `f_graph_load`. Whole-file cost:
  **160 / 139 / 5,257**.

The shared `fpe_term`/`fpe_defs` error traversal remains in `load/graph.bend`,
already included. Shared selectors and `terms_len` remain in the included
`core/term.bend`. No additional file is charged for those replacements.

For the checker, a separately identified conservative supplement includes
`diagnostic/produce.bend` (**236 / 210 / 8,138**): S3 redirected kernel book-level
checking/error wrapping to `check_book_diagnostic` and `dg_result_error` there.
Dependent-application checking itself remains in `kernel.bend`; this supplement
does not pretend to identify the smallest possible application-only context.
No additional replacement owner was identified for the backend set.

| Task with replacement owners | B01 files | B01 physical / nonblank / bytes | Delta against **original S0 set** |
| --- | ---: | ---: | ---: |
| Parser | 32 | 5,928 / 5,135 / 212,787 | +212 / +284 / +13,971 |
| Checker, conservative supplement | 10 | 3,000 / 2,599 / 106,213 | -156 / -53 / -434 |
| Backend | 15 | 3,162 / 2,707 / 121,876 | -235 / -150 / -4,460 |

Thus the parser replacement-owner view is **3.71% larger in physical lines,
5.85% larger in nonblank lines and 7.03% larger in bytes than its original S0
set**. Its same-path reduction must not be presented as the complete context
change.

For sensitivity analysis only, the JSON also adds the same owner files to both
revisions. Those expanded S0 sets are 6,608 / 5,612 / 227,077 for parser and
3,502 / 2,948 / 118,367 for checker. Their corresponding B01 reductions are
680 / 477 / 14,290 and 502 / 349 / 12,154. These symmetric expansions are
explicitly additional views; they do not replace the original S0 denominators.
This remains a whole-file proxy, not a transitive dependency closure.

## Separate authored overhead

The finite inventory below contains the new maintained B control and the direct
files in `implementation/phase7/s4-evidence` at this audit cutoff. Every listed
path is absent from S0 Git. The JSON records exact membership and hashes.

| Additional material | Files | Physical | Nonblank | Bytes |
| --- | ---: | ---: | ---: | ---: |
| `selfhost/tests/frontend/shared-operations.mjs` | 1 | 142 | 141 | 12,567 |
| Top-level S4 validation/migration source tools | 7 | 601 | 576 | 42,247 |
| Top-level S4 evidence/report data | 23 | 30,610 | 30,365 | 972,531 |

These are additional tests, audit tools and evidence, not production compiler
savings or runtime memory. This finite inventory excludes this recount's own
JSON/Markdown, nested generated evidence, Clang binaries, bytecode caches,
compiler images and raw execution logs. It also excludes concurrently edited
S4 design/root report files and older S1-S3 additions outside the frozen
contexts. It is not a complete repository overhead census.

## Deterministic method and verification

Physical lines are `len(data.decode('utf-8').splitlines())`; a final newline adds
no empty line. Nonblank lines have a nonempty Python `str.strip()`. Bytes are
the unchanged file-byte length. All hashes use SHA-256. Input files were reread
and compared before writing the JSON; none changed during the count.

The B01 production identity is
`4a4266b61240bf6fa9874147bb94e3360ec9126e4fc333c3d139f6fe3d6b5044`:
SHA-256 over sorted original logical production paths, a TAB, their B01 SHA-256,
and an LF. The complete observed-input identity is
`0dfdd95563e62e48924d137d2fbe3904f67900519a481779709929c83e3c7c2d`, using the same
format with recorded repository-relative storage paths.

From the repository root, this read-only check recomputes every recorded
baseline/current file count and hash without importing any compiler API:

```sh
python3 - <<'PY'
from pathlib import Path
import hashlib, json, subprocess
r = json.loads(Path('implementation/phase7/s4-evidence/context-counts.json').read_text())
def check(data, expected):
    lines = data.decode('utf-8').splitlines()
    actual = dict(bytes=len(data), physical=len(lines),
                  nonblank=sum(bool(line.strip()) for line in lines),
                  sha256=hashlib.sha256(data).hexdigest())
    assert all(expected[k] == v for k, v in actual.items())
rows = list(r['production']['files'])
for context in r['contexts'].values():
    rows += context['fixed_original_paths']['files']
    rows += context['supplementary_replacement_owners']['files']
for row in rows:
    old = row['baseline']; source = old['source']
    data = (subprocess.check_output(['git', 'show', source['git_revision'] + ':' + source['git_path']])
            if 'git_revision' in source else Path(source['file']).read_bytes())
    check(data, old)
    check(Path(row['candidate']['file']).read_bytes(), row['candidate'])
for item in r['input_documents']:
    check(Path(item['file']).read_bytes(), item)
for group in r['separate_S4_overhead']['groups'].values():
    for item in group['files']:
        check(Path(item['file']).read_bytes(), item)
print('All recorded file hashes and counts match.')
PY
```
