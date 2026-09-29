# Retire raw loader replay after contextual completion

This source08 plan follows the checked source07 contextual candidate. Its gates
remain separate: a correct contextual implementation must not imply that deleting
a second route has already preserved behavior. Root owns load/modules, load/graph
and load/seed; the frontend owner retires obsolete frontend entry points and
scoping/flattening/counter-replay workers. Both use the same fresh source snapshot.

Internal load ABI2 accepts raw file text for contextual loading or an
invocation-local FCompletedSource containing the exact FResult already returned
by that compiler's contextual completion. It does not accept a raw parsed tree
as if it were completed. Located source ownership remains separate. The host
requires ABI2 and the complete required function set; old or missing versions
fail explicitly. The frozen host patch already has independent protocol controls;
actual compiler/CLI gates remain required.

Remove FLoaded and its independent import traversal, f_parse_at, raw parse-source
accessors and qualification replay. The ordinary canonical graph loader keeps
import traversal, cycle detection, relative namespaces, loaded declaration events,
foreign path adjustment, exact Base seed validation and final global freshening.
Its old f_load compatibility name, if retained, can only delegate to this graph.
No standalone raw-parser consumer may keep the superseded frontend alive.

Alias resolution happens at the actual parser checkpoint. Its ambiguity helper
therefore checks the supplied name without recursively rewriting already resolved
children. Graph completion still validates imported law fills against the loaded
prior declarations; remove only the dead raw Body/counter-replay branch there.
Module completion qualifies declaration names and recursively handles constructors;
Core references have already been resolved and are not qualified again.

Remove the FCompleted per-term compatibility wrapper once every loader record is
contextually completed. This also removes the possibility of replacing a real
child origin with a zero-range wrapper. The parser's syntax/value distinction
remains until each completed term no longer needs syntax decisions.

The existing --checkup user command must follow pinned import-line discovery,
including order and filtering, rather than parse the parent body merely to list
its imports. Do not mistake removed internal raw-AST exports for a lost user CLI
feature. Main declaration reporting must continue using the actual completed
main-module event order, excluding imported declarations.

Gate source08 with checked B1/Base/36, exact saved parser vectors and independent
completion/beta/error-order controls, real CLI and program executions, then the
same-source exclusive performance screen. Record the maintained source census
and every retired responsibility. Do not claim simplification from merely moving
code or hiding helpers outside the module manifest.
