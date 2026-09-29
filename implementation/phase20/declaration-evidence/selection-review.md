# Independent Phase20 capture review

Capture is approved for inventory
`0f49cdf105cf75b5e90d3ef6a7817e7a07eda4f6a53868af3c6caf4fb0db6d70`.
The exact52 closed roots select3,303 members:3,300 regular files and three links,
totaling121,192,708 bytes. The largest member is6,121,197 bytes, safely below the
unchanged64,000,000-byte per-part/member limit; the compressed archive limit
remains99,000,000 bytes. Independent extraction/reconstruction is still pending.

The collector is exactly the recorded literal-only adaptation of the frozen
Phase19 instance collector. Archive selection, bounds, byte/mode/path/type/link
checks and committed-source patch handling are unchanged. The original Phase16
recoverer retains SHA `654bcf4435c7b02d329299aa3f4a71aed46c122b556ecd06bfbccece15972234`.
All three `link.bend -> a.bend` links resolve to selected regular fixture files
inside their own captured directories, with no symlink ancestor or escaping path.

All60 released paths match fixed commit `c385d3913e9f10c6c4d9c5cfef3f34bc0682d351`;
all20 root-frozen dependencies are selected, and all87 current freeze identities
match. The source anchor contains214 members and its patch changes only
`src/front/declarations.bend` against fixed prior release
`fd9e8b28c906dff13471fab9afc6975fd5574edd`. Recovery uses committed bytes, not live
source. All75 protected Phase6 hashes and git statuses remain unchanged, and none
of their payloads enters this capsule.

The rejected source02/source03, failed audits01/02 and zero-copy promotions01/02
are present. The five fixture expansions are exact sibling fixture directories;
no wider historical experiment family was swept in. Private contextual payload
is excluded except the exact reviewed first-element patch. One prospective
Phase21 design, `design/phase21/group-boundaries.md`, is included because it is
explicitly among the60 frozen release files; no Phase21 build/tool payload is
included. Prior release capsules, pin and toolchain remain declared external
prerequisites.

This was an independent read-only inspection, with no archive, extraction,
compiler or source mutation. The adjacent JSON binds reviewed metadata/tools and
records link identities and scope. These review outputs are outside capture
inputs. Keep capture and independent recovery separate; retain any failure and
rerun the protected/frozen-input audit afterward. Root owns publication.
