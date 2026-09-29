# Newly accepted constructor grammar executes correctly

All twelve paired observations pass exactly on source04/API `40c8f7f3`: three
complete programs, each checked and run through the interpreter, emitted JS and
native backend. Both pinned TypeScript and the Bend compiler return the frozen
expected results41,42 and43, respectively. Every lane exits0 and reports checked
execution or checker acceptance.

The fixtures exercise an unindented constructor, a comment/newline before its
opening brace, and their combination with two constructors. Each type is followed
by ordinary definitions; each program constructs a value with a U32 field and
consumes that field in a match. This adds usable-program coverage beyond the
owner's successful parser constructor-inventory comparisons.

The prospective plan is `design/phase20/declaration-programs.md`; frozen fixtures
and selection are in `selfhost/build/phase20/declaration-programs-inputs-01`.
The final paired report is `declaration-programs-01/selected/paired.json`.
The thin runner reuses the frozen Phase19 backend harness and environment,
changing its CPU to2 and adding exact3-program/12-row assertions. Compiler source,
host and runtime remain unchanged. No probe failure occurred and no timing or
general backend-conformance claim is made. The adjacent JSON binds the complete
reference/candidate results, command logs, fixtures, runner, plan and exact API.
