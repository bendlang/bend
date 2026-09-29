# Exact Phase15 capsule recovery

Use the companion below for this capsule. The inherited generic materializer
refused four legitimate fixture symlinks containing `..`, even though their
normalized targets are captured regular files inside the recovery root. Capture
and archive verification succeeded before that refusal; no recovery destination
was created. The failed publisher record remains verbatim in
`publication-01.json`, with its original command logs in `publication-run-01/`.

The archive and manifest were **not recaptured or modified**:

- Manifest SHA256: `70b99f29a3e7adc5d5c31f2e324a79d9e93ed7a9e1e1d288220a82ecad384c26`.
- Archive SHA256: `0f9e37ef2f6a2116086757f4cfcc2d2d4300bd110461584eebdbb44565c52a80`.
- Archive size: 24,925,020 bytes; 17,179 recorded file/symlink paths.

`recover-reviewed-symlinks.py` accepts only that exact manifest. Its four literal
path/target/hash/mode exceptions cover the `alias-same-physical`,
`cycle-canonical` and `diamond` fixture links in the two retained behavior-cycle
attempts. Three targets are `../leaf.bend`; one is `../a.bend`. The fifth ordinary
`leaf-link.bend` → `leaf.bend` link uses the original no-parent-component policy.

Every link target must normalize to a captured regular file inside a fresh
recovery destination. Absolute targets, escapes, unreviewed parent-relative
links, absent or non-regular targets and selected symlink ancestors are refused.
All regular files are restored and chmodded before any symlink is created. The
unchanged collector verifies the archive and eleven prerequisite capsules first;
the unchanged independent checker subsequently validates every restored type,
byte count, hash, mode and symlink target. Eight policy controls accompany the
recovery report. Root and an independent reviewer inspected this narrow policy
before execution. This is not a general recovery-policy relaxation.

Keep the companion, this addendum and publication/recovery reports alongside the
capsule and all earlier prerequisites. These evidence-only files were added after
capture and are published in Git; they are not falsely represented as contents of
the original archive. Completion is recorded in the final `publication.json`,
which links the preserved initial failure and the reviewed recovery records.

From the repository root, with Python3.9+ **without `-O`**, using fresh destinations:

```sh
python3 implementation/phase15/evidence/collect.py verify implementation/phase15/evidence/capsule-01
python3 implementation/phase15/evidence/recover-reviewed-symlinks.py implementation/phase15/evidence/capsule-01 /tmp/phase15-fresh-recovery /tmp/phase15-fresh-recovery.json
python3 implementation/phase15/evidence/recovery-check.py implementation/phase15/evidence/capsule-01 /tmp/phase15-fresh-recovery /tmp/phase15-fresh-recovery-check.json
```

The copied `README-captured.md` retains the original README verbatim, SHA256
`08de8e3b06c00096535c7e02e61cf099fed358adae38a5d1c4ba88c4718d07c1`.
The capsule contains that original wording, including the older generic
materialization command. The live README has only an explicit post-capture header
pointing here; compiler sources, producer reports, captured tools and archive
bytes remain frozen.

This establishes complete recorded byte/mode recovery, including the exact five
fixture symlinks. It does not automatically rerun archived compiler experiments;
those retain historical paths and external Node/Clang/profile prerequisites.
