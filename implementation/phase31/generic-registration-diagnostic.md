# Generic-row regression: unused exact-call registration

The final checked07 canary measures the unchanged generic row 5.04% slower
than installed17. This diagnostic tests one mechanism: module-wide exact-call
registration enables the existing WeakSet membership check on every generic
exact-arity invocation. Installed17 has no registrations in this module;
checked07 registers two private roots, `pair` and `batch`, even though the row
probe never calls either. The [prospective design](../../design/phase31/generic-registration-diagnostic.md)
fixes the perturbation, controls and interpretation before measurement.

The diagnostic appends only `exactCode(()=>null);` to the exact installed17
module. Its registered wrapper is never retained or called. Removing that one
22-byte suffix recovers all original bytes and the original SHA256. Every public body,
runtime helper and measured wrapper remains byte-identical. Actual checked07
and pinned TypeScript remain the original canary inputs.

`generic-registration-controls-01` passes the unchanged independent row review:
99 complete four-array oracle points, 12 exact native schedules, 18 fresh/alias
scenarios, 39 ordered public-boundary scenarios and delayed-write/zero-swap
negative witnesses on all three selfhost variants. The separate CPU6 control
acquisition completes in 0.817 seconds; that duration is not throughput evidence.

Frozen raw artifacts are `generic-registration-01`,
`generic-registration-controls-01` and `generic-registration-plan-01`, under
`selfhost/build/phase31`. The maintained derivation/plan tool and the unchanged
reviewer are preserved by identity and consumed copies.

An independent static review confirms that this isolates enabling the existing
registration lookup; it does not establish a safe runtime fix and does not
address the separate scalar zero-work guard overhead.

Timing uses the same complete n32/seed17 serialized row, five fresh rotating
serial samples on CPU3, at least 100 warm calls and three seconds of warmup,
and the existing 300ms measurement target. The prior checked07 canary remains
preserved as its own window.

The exclusive comparison completes in 84.23 seconds, including its launcher.
`generic-registration-confirm-01/report.json` records:

| Module | Median ms | Five-sample range ms | Change from installed17 |
| --- | ---: | ---: | ---: |
| Installed17, no registration | 0.422862 | 0.417267–0.430662 | — |
| Same bytes plus unused registration | 0.447108 | 0.446919–0.452052 | +5.73% |
| Unchanged checked07 | 0.447867 | 0.444686–0.452632 | +5.91% |
| Pinned TypeScript | 0.008421 | 0.008373–0.008446 | — |

The diagnostic meets every prospective criterion. Its range is disjoint from
installed17; its median increase is 96.97% of checked07's same-window median
increase; checked07 is only 0.17% above it, with overlapping ranges. Half-sample
drift is −0.90% to +2.37% for the registration diagnostic, −0.99% to +0.02% for
checked07 and −4.85% to +0.43% for installed17. The baseline has one warming
sample, but its full range remains below both registered modules.

Enabling the existing global registration lookup is therefore a substantial
causal explanation of this generic-row regression. The percentage explained
is a descriptive ratio for this window, not a universal allocation of CPU time.
The exact 22-byte change does no row computation and changes no generic body;
it enables the extra WeakSet lookup already present in `invokeExact`.

This finding informs an explicit promotion tradeoff: private local-array
programs become much faster, while modules containing any exact registered
entry make their remaining generic calls slightly more expensive. A future
dispatch optimization needs its own proof for mutable public code, raw calls,
forged arguments and observable property access. This experiment neither
removes those checks nor proves a safe replacement. The approximately 0.18µs
extra scalar zero-work entry cost is a separate result, outside this diagnostic.

The diagnostic's causal criterion is **PASS**. Checked07's original
no-material-regression admission criterion remains **FAIL**; explaining the
regression does not convert it into a pass. The root selects checked07 under
the explicit [admission amendment](../../design/phase31/admission-tradeoff.md),
subject to original-program transfer, separate compiler-cost measurements and
the full correctness/release gates. The prior designs, failed performance
condition and measured regressions remain visible and unchanged.
