# Retained reference and harness evidence

`raw.tar.gz` contains content-addressed objects from the completed focused
reference gates, full 2,996-row reference frontend run, frozen harness, generated
programs/native binaries, initial failures and passing harness tests.
`manifest.json` maps each original repository-relative path to its object hash.

Archive SHA-256: `b011854d9869ee6db4262668c0523a36ab84d253c13b901b57a39bc53ba42422`.
It contains 335 path identities and 227 distinct objects, in 2,258,668 compressed
bytes. `archive.py` verifies every archived object and checks that original
inputs did not change while archiving. It refuses to overwrite prior evidence.

To recover a file, read its entry in `manifest.json`, then extract
`objects/<sha256>` from the archive and write those bytes at the chosen
relative path. Original absolute paths remain in raw reports; relocation is
not claimed to be an exact replay. Node, the pinned upstream checkout and the
Clang toolchain remain explicit external prerequisites.

This archive covers reference/harness evidence only. Candidate03 compiler and
execution evidence has separate reports and source identities. The later repair
of two old hardcoded inventory tests is retained as the adjacent
`inventory-tests-v2.stdout` and `inventory-followup.json`; the initial archive
is unchanged.
