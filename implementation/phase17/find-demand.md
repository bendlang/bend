# Actual declaration lookup demand controls

Completed controls for [the direct worker](../../design/phase17/frontend_find_worker.md).
The installed compact API is baseline `35044ae6`; candidate is the independently
checked `find-worker-build-01` with the unchanged version5 derivative. These are
internal generated-helper controls, not the public `run_lib` calling convention.

Freeze the launcher, runner and 23 case descriptions before invoking either
helper. Preserve each original API as the exact prefix of a separate probe and
append only `(...args) => run_loop($f_find$(...args))`. The trampoline is required
on both sides because the old internal helper returns `$JMP` records on misses.
Do not replace or reimplement the actual lookup in the test.

The controls compare complete returned property descriptors or raw thrown values,
returned-definition reference identity, exact getter event order and name-read
counts. Descriptor inspection does not evaluate getter sentinels after a lookup.
Independent expected outcomes supplement paired equality, preventing two equally
wrong implementations from passing merely because they agree. Cases include
empty/missing/first/middle/last results, duplicate law/definition precedence,
poisoned tail tags and unused fields, demanded raw string/object throws, empty
names, common prefixes, astral/combining names and ordinary treatment of a
`BookCache`-kind definition. A 100,000-definition miss uses the original stack
4MiB and heap4GiB limits. Both lanes run in separate CPU2 Node processes.

This checks the narrow worker's demand and return contract. It does not establish
language conformance, generated-program behavior, a speed improvement or the
public foreign/erased/affine ABI. The raw JavaScript getter sentinels deliberately
probe boundaries that ordinary parsed books cannot express. Root owns maintained
controls, full regressions, timing and promotion. Original failures, if any, stay
in distinct attempts; no existing Phase16 file is modified.

## Results

The frozen [paired attempt](../../selfhost/build/phase17/find-demand-01/report.json)
passes **23/23 exact comparisons** and **46/46 independent expected outcomes**
(two authentic APIs). Both processes exited 0 without a signal or setup error.
The 100,000-definition miss read exactly 100,000 names in each lane and returned
the identical complete named `Missing` shape without stack overflow. All five
expected raw throw cases, poisoned undemanded fields/tails, access order and
returned first-definition identities agree. No control was removed or weakened,
and this harness had no failed run.

[Machine-readable summary](find-demand.json) binds attempt manifests, genuine
checked parents, unchanged version5 derivation records, exact API/probe hashes,
frozen consumed tools, process arguments and all case names. The original API
prefix is preserved byte-for-byte; only the explicitly recorded internal export
is appended. The candidate production change remains root-owned: one Boolean
worker, +8 physical lines/+145 bytes/+1 definition in declarations.bend. This
control result does not measure the optimization's speed.

| Artifact | Baseline | Candidate |
| --- | --- | --- |
| API SHA256 | `35044ae6f6cd9bb63690536588c11761695c66cbf524db8bcd3baa6453ed5315` | `9b20de5032e306a0b7ee2686a1cc79452f81fcb282ff6419a0d1ad5c4b5716b6` |
| Internal probe SHA256 | `fcf49f8ca7d647e681e409b8658f136c40a1559d5c2ff01da1ba49a186395b30` | `13441154ebd63243934090cc2d1657421eb14a5b614548704481dd5555c9820a` |
| Checked parent SHA256 | `83113283980375efc9cbb3911c4b3df03d18f4cb8066133ea14597df20b98458` | `59317ea5f8ec47b98e55a5e4d72718ffa9e59fec780cae0819a45e4eafe3f451` |
