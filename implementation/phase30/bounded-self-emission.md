# One checked16 self-emission and small generated-compiler oracle

The bounded experiment passed. The selected checked16 compiler emitted the exact
attested assembled compiler source as a new JavaScript compiler, H. H then checked
Base under its own API hash, compiled and ran the positive Nat/U32 fixture to8,
and rejected the negative Bool-as-U32 fixture at checking. Its positive/negative
observation fields matched B1 exactly; its emitted positive-program JavaScript
was also byte-identical to B1's output.

This is one B1→H acquisition followed by a small functional gate. H was not
installed, and there was no H→H attempt, fixed-point claim, full H conformance
sweep or controlled compiler-speed comparison. It overlapped correctness work,
as explicitly permitted by the [schedule amendment](../../design/phase30/self-emission-schedule-amendment.md).
Historical self-emission durations involve other source/images/protocols and
must not be used to calculate a speedup from this observation.

| Bounded child | Observed wall seconds | Peak RSS, KiB | Result |
|---|---:|---:|---|
| B1 small positive/negative preflight | 3.606 | 389160 | Pass; positive8 |
| B1 emits H | 30.841 | 927172 | Checked emission succeeds |
| H JavaScript syntax | 0.202 | 60184 | Pass |
| H ABI and Base preparation | 20.427 | 545668 | Correct ABI; new H-specific cache created |
| H small positive/negative oracle | 17.624 | 472924 | Exact B1 observations; positive8 |

The full supervisor took78.530 seconds, including repeated input verification
outside those child timings. CPU2, Node24.18.0, 4MiB V8 stack and an8GiB V8 heap
allowance were frozen; the heap allowance is not a total-RSS hard limit. The
emission cap stayed1200 seconds; the other compiler children had90-second caps,
and each emitted small-program execution had its own10-second cap. Per-child
RSS and CPU usage come from `wait4`; all children exited0 and no deadline fired.

Exact identities:

- Selected B1 API: `33545640e25beffb61639b27f4815aaeb345fda14758e1d63418cd1d0ccc0637`.
- Genuine checked parent: `60aa968ffcedb7a02a220b58a51396dd036d0d8b1f39f1b3def3f6b4248d6469`.
- Attested assembled source: `678bafd61cff715c3ee2012ef3840ddfe99a2aeb1d81b5345fb3c6e6bfc1757e`.
- Generated H: `21b53c697c7dce78bb2d7ee2977dc77659fc9f9c66878f54106a8509987001ab`, 2,446,321 bytes.
- Runtime: `fab241aefeb2ad1626d7079a3b798eb163207cd38b3e0d80318941a01f8255f1`.

H used the existing frozen `typed-driver.mjs` and its positional compiler-ADT
adapter. Its ABI versions were load2/term1/span3/check2. The Base cache receipt
records H's actual API hash and `validatedBy: check_book`: it was **created** in
the H Base step, then **validated-existing** in the H oracle step. B1 preflight
used its independently validated existing cache. No Base-check result was
relabelled from B1 as H's result.

Canonical evidence is under `selfhost/build/phase30/self-emission-plan-16/`:
`plan.json`, `stage2.mjs`, adjacent checked-emission receipt, and
`execution/report.json`. The `execution/{preflight,h-base,h-oracle}/report.json`
files retain each observation, cache identity and small-program output; the
supervisor retains every child's raw stdout/stderr and resource accounting.
The plan binds the reviewed supervisor/oracle, exact source/attempt artifacts,
original emitter and frozen driver/helper closure. The earlier14 plan remains
unexecuted and is not relabelled as this16 run.
