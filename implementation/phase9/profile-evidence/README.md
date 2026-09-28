# Lossless Phase9 CPU profile

The [preservation manifest](baseline-01/manifest.json) binds the complete raw
profile to [checking.cpuprofile.gz](baseline-01/checking.cpuprofile.gz).
The raw profile is **1,573,317,008 bytes**; gzip is **54,791,942 bytes**.
Streaming decompression reproduced the raw length and SHA256 exactly. No split
was needed because the payload is below the declared 95 MB threshold.

The original experiment's summary failed at Node's JSON-string length limit.
That failure is retained. Root subsequently summarized the same bytes using the
bounded-memory `selfhost/tools/performance/phase9/profile-summary.py`; its recovered
summary and both rejected parser attempts belong to the main Phase9 evidence
capsule. Successful byte preservation does not change the original failed report.

Restore and check the raw profile with:

```sh
gzip -dc implementation/phase9/profile-evidence/baseline-01/checking.cpuprofile.gz > /tmp/phase9-checking.cpuprofile
sha256sum /tmp/phase9-checking.cpuprofile
```

Expected raw SHA256:
`05e62a8dad989161a2d117c17d8beaaa00508c796a136ac475a9bc18cbd3dd33`.
Compressed SHA256:
`89963a067d05c57e2100262e34aaa704f55ee688ba7aa4c23f6d2d11ed490038`.

[preserve.py](preserve.py) streams compression, checks the source's unchanged
identity, verifies the complete gzip roundtrip, and would split compressed
payloads above 95 MB into numbered 64 MiB parts. This run used one ordinary gzip
file. The original ignored raw file remains untouched. The main collector records
its identity and points here rather than storing another copy of either payload.
