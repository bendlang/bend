# P12-001 — Profile the released Phase11 compiler

- Owner: root. Status: prospective; investigate, no new speed claim.
- Baseline: `f8244c9`, checked attempt `selfhost/build/phase11/integrated-01`,
  selected API `63c861e900450ab2045474d6c822371d30c56019521a12c13d8e4c62009ddf1f`.
- Hypothesis: the previous elimination of branch wrappers and repeated native
  reconstruction changed the dominant costs; Phase11's old profile cannot rank
  the remaining opportunities reliably.
- Discriminator: successful ordinary source/type/trust check with stable inputs
  and complete raw samples; group exclusive costs by lexical generated owner.
  Do not distribute runtime/GC cost to inferred callers.

Use the unchanged Phase9 `profile-check.mjs` with the Phase11 immutable attempt,
fresh `build/phase12/current-profile-01`, CPU0 and10000us interval. Node24.18.0,
4MiB stack,4GiB heap; retained validated Base cache and unchanged pinned upstream.
No competing intentional compiler/archive jobs. Sampling includes startup and
is excluded from all uninstrumented speed ratios. Preserve original failure if
the profile/check does not complete; choose a fresh attempt after correction.

The raw profile, summary, lexical grouping, launcher/resource settings and exact
input identities are preserved in the final Phase12 evidence capsule. Outcomes
and decisions belong in [the report](../../implementation/phase12/avoidable_work.md),
not edits to this prospective input.
