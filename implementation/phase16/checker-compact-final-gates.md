# Phase16: final compact compiler controls

All requested focused groups pass exactly on the same final compiler image,
`compact-final-build-01`, API SHA256
`35044ae6f6cd9bb63690536588c11761695c66cbf524db8bcd3baa6453ed5315`.

| Group | Exact observations |
| --- | ---: |
| Existing backend selection | 41/41 |
| Additional JS/native literal execution | 20/20 |
| Actual parsed memo instance sets | 29/29 |
| Saved growth refusals | 2/2 |
| Literal parse/check selection | 176/176 |

The native groups use the existing SHA-bound Clang16 environment. Growth
refusals preserve `grow~9` for double growth and `grow~63` for depth growth.
The source-instance group includes the parsed absent/present Lambda distinction,
repeated F32 expressions and literal-versus-constructor identity.

The final build's frozen configuration names CPU0. A separate, identity-bound
runner invokes its unchanged snapshot conformance tools on CPU1 and records
that orchestration override explicitly. It verifies the checked derivation,
API-specific Base cache and healthy complete selected observations, then
requires every paired row to match exactly. It does not mutate the build
manifest, compiler source, API, adapter or oracle. The instance probe likewise
uses the final verified API directly on CPU1. All jobs ran serially and closed
before the root's controlled timing window.

These are focused same-image correctness gates. Root-owned full frontend,
historical replay and controlled performance results remain separate. No new
source change or speed claim is made by this addendum. The prior literal and
canonical-key reports retain their original frozen evidence.

[Machine-readable identities and gate references](checker-compact-final-gates.json).
