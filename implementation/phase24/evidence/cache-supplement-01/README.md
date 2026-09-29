# Installed CLI cache supplement

This separate113,556-byte archive preserves the3,468,122-byte installed CLI Base
cache discovered after closing the primary Phase24 capsule. The primary capsule,
its reports and all producer trees remain unchanged. The manifest records the
exact original path, mode and SHA256; `dependency.json` validates its API/Base
identities and serialized book hash and records the driver path derivation.

The ordinary CLI smoke commands use this installed project, and the cache's
generation timestamp lies within the first invocation. The original CLI report
did not hash this cache individually. This supplement captures its current exact
bytes; it does not manufacture an at-run byte measurement. Missing caches can be
regenerated with the recorded Node/release and `--prepare-base`, but the generated
timestamp makes the new bytes different. Use the supplement for exact restoration.

The [independent receipt](../cache-supplement-recovery-01.json) checks restored and
original bytes, mode, type and complete membership. Repeat with new paths:

```sh
python3 implementation/phase24/evidence/recover.py implementation/phase24/evidence/cache-supplement-01 /tmp/phase24-cache-supplement-recovery-NEW implementation/phase24/evidence/cache-supplement-recovery-NEW.json --original-root "$PWD"
```
