# Validate tree-bitonic on the changed checked17 runtime

Checked16's separate 15-second-warmup comparison retained a 4.15% regression.
The new checked17 transfer window has a lower median than Phase29, but both
Bend sides still improve by roughly 13–21% between timed halves. This leaves
settled current-image behavior unresolved even though every exact output passes.

Freeze exactly one changed-image diagnostic by rebinding the retained checked16
long comparison to the actual checked17 module and fresh source/emission/report
identities. Keep `bench(8, 0)` and expected result 971629740, pinned TypeScript
and Phase29 modules, the CPU3 runner, three rotating samples, 15-second warmup,
three-call minimum and one-second measured target unchanged. No generated code,
oracle or protocol is rewritten. Both earlier windows remain immutable.

This is prospective validation of a changed image, not repeated tuning of the
same artifact. Run only after the complete17 matrix and an explicit parent
grant, before any separately granted H compiler-cost window. Report all medians,
ranges and half drift. A continued regression remains a regression; overlapping
ranges or persistent large drift remain uncertain. No additional repetition or
different warmup duration is authorized by this design.
