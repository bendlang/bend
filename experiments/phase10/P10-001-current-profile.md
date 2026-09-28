# P10-001 — Profile the final Phase9 compiler

Date: 2026-09-28. Owner: root. Prospective record before launching the profile.
Status: correctness unchanged; measurement not run; decision investigate.

The Phase9 residual profile predates its final equality optimization. Profile
the actual installed derivative, using immutable `build/phase9/integrated-03`
and its assembled compiler source, rather than extrapolating old percentages.
Verify installed release first. Run the maintained Phase9 profile launcher on
CPU0 with 10,000 microsecond sampling, 4 MiB stack, 4 GiB heap and its existing
600-second deadline. Its kind retains the historical launcher schema; the output
directory and this record establish the new Phase10 run.

Preserve actual worker, request/results, input hashes, raw profile, streaming
summary and any failed attempt under `selfhost/build/phase10/current-profile-01`.
The launcher already verifies ordinary type acceptance, expected unsafe proof
trust refusal and unchanged input identities. Concurrent code inspection/tiny
agent probes are allowed; profile duration is explicitly not a controlled speed
measurement. Stop on identity drift or failed checking instead of reading the
profile as an accepted run.

Read physical callers and repeated traversal opportunities. Generated trampoline
frames can obscure logical ancestry. Sampling percentages, peak memory and
anonymous frames do not establish allocations or a particular optimization.
Use independent operation counts for a concrete source hypothesis. The final
uninstrumented comparison remains a separate integration gate.

Design: [Phase10](../../design/phase10/repeated_work.md).
Outcomes: [report](../../implementation/phase10/repeated_work.md).
