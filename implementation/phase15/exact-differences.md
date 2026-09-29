# Phase15 independent exact-output attribution

The final2996-observation vector reduces exact differences from **603 to459**, with **144 newly exact observations and zero lost matches**. An independent [audit](../../selfhost/tools/performance/phase15/behavior-attribution.py) reconstructs every compared field directly from the pinned reference, released Phase14 and final Phase15 vectors, then checks its difference set against the maintained strict comparison. The [machine-readable report](exact-differences.json) binds all three input hashes and lists every attributed observation.

| Cause of newly exact output | Observations | Fixtures |
|---|---:|---:|
| Parser caret rendering alone |132|66|
| Missing imported file, correct phase and contextual message |10|5|
| Malformed erased binder refusal plus parser caret rendering |2|1|
| Total |144|72|

The malformed-binder pair is a combined result: validation fixes its refusal boundary, while the separate renderer supplies the exact caret. The dedicated cycle controls are separate evidence; they contribute no newly exact result in this pinned full corpus. No diagnostic improvement is attributed to the lookup speed patch.

Another74 observations change while retaining an exact gap:66 add parser caret lines but keep an older diagnostic difference;8 illegal local-path observations now refuse at parse with context but still print the first character instead of the whole observed path. These are not counted among the144 exact improvements.

## Remaining difference census

The459 exact differences affect **337 unique fixtures**, with122 parse observations and337 check observations. The following mutually exclusive groups describe output shapes, not proven shared semantic causes. Removing marker or snippet lines is used only for this classification; the exact oracle retains every original byte and path.

| Output difference | Observations |
|---|---:|
| Unstructured legacy error text |166|
| Source snippet only |153|
| Same expectation, different observed term or detail |55|
| Other diagnostic shape |43|
| Computed-match legacy message |26|
| Location or span detail |9|
| Caret width or position only |7|
| Total |459|

The four illegal-path fixtures account for8 of the55 same-expectation observations. The7 checker caret width/position gaps predate this phase and are not fixed by sharing the parser renderer.

Across all2996 measured observations, the final compiler agrees with pinned TypeScript on **status, phase, checked flag, type acceptance, proof trust, kernel metadata, unsafe-definition list, exit and output**. Every remaining difference in the compared result fields is diagnostic text. On337 check observations, that difference also changes the diagnostic-sensitive harness verdict and evidence. These facts do not establish identical rejection reasons, universal language semantics, proof-kernel correctness or backend equivalence.

The full check lane reports1157 strict passes and341 strict failures. The341 include337 exact diagnostic mismatches and4 already-matching check observations whose fixture failures occur later in compilation/emission. The broader release report retains those stage distinctions;459 observations must not be described as459 incorrectly accepted or rejected programs.

Inputs are the unchanged pinned b2111cf reference, Phase14 `frontend-audit-02/candidate.json`, and final `selfhost/build/phase15/frontend-01/candidate.json`. Both corpus identity and worker health are checked; no compiler process or new performance measurement is part of this attribution audit.
