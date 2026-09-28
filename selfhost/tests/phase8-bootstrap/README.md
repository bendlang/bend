# New-upstream bootstrap boundary controls

These controls execute the maintained `stage0-library.mjs` and `stage0.mjs` against
upstream `b2111cf43244e65f76ddc278ee695e669f720cbf`. They check complete source books,
then import or execute the JavaScript actually emitted by that compiler. They do
not patch generated JavaScript or substitute parsed bodies for checked `Def.e`.

From the repository root, using a new output directory:

```sh
BEND_UPSTREAM="$PWD/selfhost/.bootstrap/upstream-phase8" \
  taskset -c 0 /home/ai/.nvm/versions/node/v24.18.0/bin/node \
  --stack-size=4096 --max-old-space-size=1024 \
  selfhost/tests/phase8-bootstrap/run.mjs \
  selfhost/build/phase8/bootstrap-adapter-NEW
```

The harness freezes helpers and fixture files, records consumed source hashes,
executes child builds serially with deadlines, and retains stdout/stderr and every
assertion in `report.json`. It records Linux process affinity. This is a boundary
correctness test, not a benchmark or whole-compiler conformance gate.

The selected-root library keeps the full checked definition/constructor/instance
context and restricts only its emission `order` view. Controls establish:

- Eight exact selected exports, with an omitted private dependency still executed.
- Default export selection excludes Base, templates, foreign and IO definitions;
  explicitly requesting these, a datatype, a missing name or duplicates rejects.
- An invalid unselected definition is still checked and rejects emission.
- Unfilled laws and `?TODO` reject through the hole counter in both helpers;
  a named `?missing` is separately rejected by checking.
- Public Nat values remain BigInt through nested records/lists, callbacks,
  returned functions and partial application; U32 remains a wrapping Number.
- Actual Nat overflow and demanded invalid host values reject.
- Host inputs remain unchanged after nested Nat conversion, including a
  20,000-element list; a 100,000-step Nat tail recursion completes.
- A whole generated program executes and prints `2n`.

No graph-identity guarantee for upstream's Nat marshalling is asserted. Selected
host-boundary success does not establish that the Bend compiler accepts the new
Base, implements the new semantics, or reproduces itself.

## Initial migration evidence

The three immutable local attempts are under `selfhost/build/phase8/`:

| Attempt | Result | Interpretation |
| --- | --- | --- |
| `bootstrap-adapter-01` | 7/18 assertions pass | The initial Packet fixture incorrectly put affine `List<Nat>` in Data; other rejection assertions consequently saw that earlier error. The named-hole assertion also expected counter rejection instead of the actual checker rejection. Raw failures remain preserved. |
| `bootstrap-adapter-02` | 31/31 pass | Corrected fixture uses `List<&2, Nat>`; named holes and unfilled laws have distinct oracles. |
| `bootstrap-adapter-03` | 33/33 pass, 19 child executions, CPU 0 | Adds explicit `?TODO` guards and checks the rejected unselected definition's diagnostic location. Helpers are unchanged from attempt 02. |

Attempt 03 report SHA256:
`fa439ca19df0415fe1e30eda55b533cd1d94d36e283a7f26b34c25e4fc801b8c`.

Validated helpers:

- `stage0-library.mjs`: `9f1ce29e0a41fa44211ad8f84196c2d5f3fa207f676000018734bd49e131c401`
- `stage0.mjs`: `8b39cd894c3c0a77693a4db446645edd38cbde8c271fb6932f4ea50c2206aa87`

The root migration report owns durable experiment preservation and promotion;
these local build paths alone are not a distribution artifact.
