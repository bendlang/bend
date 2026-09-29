# Required final root freeze

Do not create `root-freeze.json` until root explicitly marks every selected
producer closed. The collector refuses to prepare or capture without it.

The adapter must bind:

- `authorized: true`, `allProducersClosed: true`, authorization provenance.
- `anchorStatus: installed-contextual-parser-release` and final release commit.
- Exact `finalAttempt`, `finalApiSha256`, final source project and its membership.
- All selected root release docs/tools/reports/dist bytes as path/SHA256 inputs.
- Exact additional release paths, with no directory sweeps of active outputs.
- Owner freeze identities and the unchanged 75 protected Phase6 identities/statuses.
- The reviewed selection, archive bounds, prior-capsule dependencies and disk grant.

The existing collector directly enforces the status/API/input-hash portion. The
selection review and preparation record enforce the broader scope/disk contract.
An uninstalled final decision requires a fresh reviewed status adaptation;
`installed-contextual-parser-release` must never describe a rejected prototype.
