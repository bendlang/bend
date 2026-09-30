# Final checked-14 timing batch

The selected release candidate is checked attempt 14. Root authorized one
exclusive serial measurement window after its integration gates passed. This
document freezes orchestration only; all experiment protocols were already
specified by the linked plans. No optimization variants remain in this batch.

Run the ten commands in `final-transfer-plan-14/plan.json`, in their recorded
order, without modifying their configurations. Each uses the retained transfer
protocol and the prospectively derived 1,200-second outer launcher. In
particular, expensive original programs do not inherit the microbenchmark
confirmation protocol's 100-call warmup floor.

Then run the ordinary compiler check from
`final-integration-plan-14/compiler-cost-config.json`, the checked-library cost
matrix from `library-cost-plan-14/config.json`, and the four scalar helper
scaling points from `scalar-scaling-plan-14/confirm.json`. Generated execution
uses CPU3; both compiler-cost matrices use CPU0. These run serially while all
other campaign executions remain paused.

`prototype-final-batch.py` prepares an immutable manifest binding the exact
commands, configurations, tools, and plans. Its separate run operation journals
each job before launch and after exit, retaining stdout, stderr, process identity,
wall duration, report identity, and compact summaries. Existing per-process
receipts remain authoritative. The batch stops at the first failure and never
overwrites or retries an output. Resume decisions require a new record.

Report each original point separately, including medians, ranges and within-run
half drift where both halves contain calls. A single-call sample has no useful
half-drift statistic. Compiler request and process costs remain distinct from
generated-program speed. No additional warmup or confirmation is automatically
authorized by a noisy result. The parent decides follow-up measurements after
reviewing this complete retained matrix.
