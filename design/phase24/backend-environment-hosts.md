# Phase24 supported-host TCP comparison

The first environment ablation executes all four unchanged emissions under
Bun 1.2.22. Both upstream emissions pass their complete TCP output oracle.
Both candidate emissions fail during module loading because this Bun version
does not export Node's `getSystemErrorMap`. Keep that same-Bun failure unchanged;
do not patch generated code or claim candidate compatibility with this Bun.

The next bounded comparison executes the upstream emissions under the verified
Bun and the candidate emissions under the original verified Node24, including
its existing 4 MiB stack and 4 GiB heap arguments. Compare exit status, complete
stdout/stderr, deadline outcome and the unchanged fixture oracle. Record both
runtime identities and different runtime resource policies explicitly.

This can close the original missing upstream execution oracle for these two
programs. It does not establish same-engine equivalence, identical resource
limits, Bun support in the candidate, a new compilation, or a speed result.
All emitted-source and original fixture hashes must remain unchanged.
