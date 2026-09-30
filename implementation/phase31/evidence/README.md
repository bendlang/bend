# Phase31 raw evidence capsule

Capture and verification are complete after all producers, installation and
release smoke closed. The [receipt](receipt.json) records **22,095 regular files /
251,864,074 logical bytes**, compressed to **49,396,387 bytes**. The
[capture process](capture-run/run.json) completed in24.908 seconds. Every member
was independently reopened and compared by name, size, SHA256 and mode, and
the pre/post-capture live inventories agreed. No experiment bytes were removed.

Archive SHA256: `35ada1da1833edc601f59d6a473237d4af3f89d8e9d4bbf23fc298e7a4daf446`.
From this directory, verify and restore into a separate destination:

```sh
sha256sum campaign.tar.gz
mkdir -p /tmp/bend-phase31-recovery
tar -xzf campaign.tar.gz -C /tmp/bend-phase31-recovery
```

Recovery expands to about252MB and runs no experiment. The committed archive
is below GitHub's per-file limit and requires no transport splitting.

`archive.py` is the retained Phase30 preservation algorithm with only the phase
name/source root changed. It captures every regular file under
`selfhost/build/phase31`, including failed attempts and consumed tool copies. It
refuses symbolic links and existing archive/receipt names, records pre-capture
identities, stores hardlinks as regular bytes, reopens the compressed archive to
compare every name/size/hash/mode, and verifies the live input set is unchanged
at the end of capture.
Partial output is not a successful capsule and must not be overwritten on retry.

The capsule is an acquisition record, not a standalone copy of every dependency.
Reproduction also needs the [Phase30 capsule](../../phase30/evidence/README.md)
for checked17 and its retained launchers; the named Phase23 frontend and Phase24
backend reference/census artifacts; Phase25/27 library and compiler-component
inputs; and Phase28 original source/TypeScript modules. Those prior capsules
link their own exact prerequisites. The upstream target is
`018751270e800bc222a93dad7f257083ee53a5f7`.

External Node24.18.0, pinned Clang16 and ordinary system/Python tools are bound
by executable identities where consumed, not vendored. Zig was researched from
primary sources; no Zig compiler installation or performance run is implied.
The H17 CPU profile exceeded its original raw-size bound; its exact gzip bytes
and verification receipt preserve the complete profile, not selected samples.

Recover beneath a separate directory; recorded absolute acquisition paths are
provenance and need explicit path adaptation for replay. Extracting bytes does
not rerun validation, establish full backend or proof conformance, or create a
new self-hosted fixed point. The103 unrelated starting files are outside this
capture root and remain covered by the separate start/final protection audit.
