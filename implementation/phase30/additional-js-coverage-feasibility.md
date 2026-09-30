# Feasibility of811 additional JavaScript observations

Static inspection establishes that the13 broader Phase24 JS batches were never
executed. They contain12 selections of64 rows and a final43-row selection, all
positive fixtures eligible for the JS lane and disjoint from its22-row positive
pilot. The original Phase24 report explicitly deferred these broader batches
after the pilot found actionable defects. No historical full observation vectors
exist for these811 rows, so a fresh run must be called **new coverage**.

The prospective [design](../../design/phase30/additional-js-backend-coverage.md)
uses the unchanged paired harness and source oracles, plus a separate fail-closed
wrapper. It binds exact source/fixture/inventory/host/Node/policy identities,
runs serial JS-only batches and compares full raw sideResults rather than relying
only on the historical paired field projection. The wrapper separately audits
known host metadata differences; it retains and rejects unknown fields. Raw
fixture passes, the narrowly defined unprintable-main NA outcomes, failures,
unsupported cases and timeouts remain separate. Matching host errors do not
validate execution.

The prepared tools are review-additional-js-plan.py, review-additional-js-run.py
and review-additional-js-policy.py. They have not been executed or frozen into a
run plan during the clean timing window. Independent static review accepted the protocol and tools after adding an
explicit rejection of shared host signal/error/reason fields in NA observations.
The prepared policy-only control suite subsequently passed22 controls at
review-additional-js-policy-01/report.json under a separate correctness grant.
It checks full-field/type equality, host metadata and narrow NA admission,
including shared signal/error/reason refusals; no compiler or fixture ran.
Metadata generation and fixture acquisition still require the parent's post-timing grant. The older
unexecuted broad-js plan remains unchanged and must not be launched with its
incorrect pass-only expectation.

The fresh22-row JS pilot took20.56 seconds for paired acquisition. Straight
scaling is approximately13 minutes for811; this is only a resource estimate
because the larger fixtures have never been acquired. The parent-approved limits
are1800 seconds, the unchanged420-second batch cap, at most three seconds group
cleanup, no next batch after200MiB retained evidence, and a150MiB free-space
reserve. The latter two are pre-batch stops, not promises that one active batch
cannot exceed them. All never-started/interrupted/completed rows remain explicit.

The first six retained-all pilot batches occupy about6MiB compressed. The21
native retry occupies3.6MiB with45MiB uncompressed, but it is not a good direct
model for JS-only successful artifacts. Existing retain:failed keeps complete
result vectors while discarding only successful program artifacts. Roughly
30–150MiB is a useful allowance under ordinary outcomes, with the explicit
limits taking precedence. Large failures or per-probe timeouts could terminate
the campaign well before811; no elapsed-time or completeness claim is made now.

No Clang invocation is required for these JS-only rows. Nevertheless the native
EPERM episode demonstrates why actual host errors must be retained and stopped,
not admitted through paired equality. A Bun-specific foreign function, unavailable
resource or JavaScript process issue could still block some selected fixtures.
No new runtime/platform/network lane is introduced. The parent will choose
whether this optional coverage remains worthwhile after final timing and the
installed/relocated smoke result.
