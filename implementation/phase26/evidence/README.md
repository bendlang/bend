# Phase26 evidence capsule

`campaign.tar.gz` contains1,445 files and44,419,701 logical bytes, compressed to
6,534,897 bytes. SHA256:
`9de6e9c99119bf86a4906c07cc74bd9a34687807e96c19dd5c46e8976402beff`.

The [receipt](receipt.json) lists every member's path, size and SHA256. The
[capture tool](archive.py) reopened the completed archive and independently
decompressed every member, verifying exact membership and bytes against the
frozen inputs. It rejected links and unsafe paths. Recovery validation did not
rerun benchmarks or manufacture relocated compiler provenance.

The capsule contains the whole closed `selfhost/build/phase26/` directory:

- Checked attempt01, canonical source/host snapshot, Base cache, genuine checked
  bootstrap, guarded derivative and36 focused observations.
- Frozen installed baseline API/runtime/Base/release metadata; new candidate
  corpus emissions and127 checks. The old full corpus is preserved separately in
  [Phase25](../../phase25/README.md), including its original emission receipts.
- Upstream source/refusal pilots01–03, baseline/candidate paired controls and the
  ignored-bit supplement. Consumed runner/source snapshots retain earlier errors.
- Guard attempts01–02, including the missing-export failure, original test sources
  and successful append-only diagnostic API copy.
- Extracted compiler escape old/new/upstream emissions and full-text/scalar oracles.
- Fifteen upstream JS execution comparisons, all90 timing samples and calibration
  logs, original config/module hashes, six separate counter runs and their controls,
  compressed complete AST census, source summary and Base-path comparison.
- Install and CLI smoke observations; the documentation-inclusive audit pilot is
  retained as invalid, and the corrected [closure audit](../closure.json) checks
  canonical compiler files and the103 protected pre-existing paths.

Inspect or recover into a new directory:

```sh
sha256sum implementation/phase26/evidence/campaign.tar.gz
mkdir /tmp/phase26-recovery
tar -xzf implementation/phase26/evidence/campaign.tar.gz -C /tmp/phase26-recovery
```

The files have original historical absolute paths inside JSON records. Restoring
bytes at a new location does not make those original build-verification paths
current. Use the [reproduction guide](../README.md) for a fresh checked attempt,
or use the repository's relative release verification for the committed release.
External prerequisites are Node24.18.0, the clean pinned upstream checkout and
the original Phase25 capsule when replaying old corpus modules. Node binaries,
upstream Git history and unrelated prior experiments are not copied into this tar.

The final independent audit recomputed all90 medians/ranges/ratios from raw
launch/stdout observations, verified exits, scalar checksums, module identities,
affinity, warmup, serial timing and exact counter normalization. All agreed with
the report. This audit is distinct from byte recovery and from semantic proof.
