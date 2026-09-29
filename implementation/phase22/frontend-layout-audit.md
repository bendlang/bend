# Exact frontend audit across the contextual module insertion

The new comparison-policy controls pass 25/25. Reauditing the already-recorded contextual source05 vector completes successfully as an audit, but refuses the compiler candidate: 30 exact differences, 30 lost prior exact matches, and 25 primitive-axis differences. Both formerly remaining monad observations become exact. Full differences are in `selfhost/build/phase22/context-frontend-gate-01/`; no fixture was rerun and no oracle changed.

The maintained comparator remains byte-for-byte unchanged. `frontend-layout-compare.mjs` is an explicit Phase22 derivative: manifest hashes may differ only under the frozen descriptor, which binds complete ordered module lists and their exact hashes. Actual on-disk manifest bytes, initial/final report hashes, report schema and all non-module manifest fields are checked. Fixture paths/content/oracles, upstream checkout/pin, report health and every compared observation field retain strict behavior. The admitted layout adds only `src/front/contextual.bend` after lexer. Synthetic controls prove rejection of target, schema, pin, path, oracle, content, module and hash drift, and continued visibility of missing/different observations.

The reusable entry is:

```
node selfhost/tools/performance/phase22/frontend-gate.mjs ATTEMPT NEW_OUT PREVIOUS_ACCEPTED_GATE MODULE_LAYOUT.json [REUSE_ACQUISITION]
```

It acquires the unchanged 1,498-fixture / 2,996-observation parse/check inventory, freezes acquisition evidence, and invokes the same layout-audited comparison. Optional reuse accepts only the matching checked artifact and healthy original acquisition. `noRegressionPass` records the primitive/exact preservation gate; the main `pass` additionally requires zero exact differences. The tested reuse path correctly returns a completed failing gate for source05. A later fresh acquisition is root-owned.

The first reauditor failed because synthetic-control identities use file/SHA records without `canonicalPath`; it and its tool remain frozen. V2 checks their actual SHA and checks canonical paths when present. V3 additionally preserves the ordinary strict policy when a comparison pair already has identical manifests, allowing later accepted contextual predecessors without relaxing target policy. No compiler source, fixture or maintained harness was changed.

Source05 regressions were sent to the parser owner: comparison/operator namespaces, missing bare-operator refusal, an alias namespace, three marked-variable ranges, and a `~` argument parse. This report does not select or promote that compiler.
