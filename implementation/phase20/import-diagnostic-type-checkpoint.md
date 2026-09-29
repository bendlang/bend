# Datatype constructor checkpoint: source02 handoff

The isolated correction closes a real grammar gap at the constructor loop. All
50 frozen comparisons now match the pin exactly, improving 32 without losing an
exact result. Twelve observations correct acceptance (seven false rejections and
five false acceptances); the other 20 correct diagnostic checkpoints. Counts are
observations, not distinct corpus fixtures. No broad conformance claim follows.

Pinned `parse_book` (2521–2527) keeps parsing constructors while the next character
can start a name, except for the complete declaration keywords def/type/law. It
then validates the name, alias/duplicate freshness, and opening brace in that
order. Our previous `f_type_ctors` required positive indentation and an immediately
following brace before entering the constructor path. This both ended the type
body too early and bypassed name validation on accepted constructor shapes.

Source02 uses the pinned loop boundary and the existing f_valid_name/fpe_name_error
at the actual name checkpoint. A small named worker retains alias-before-duplicate
and both-before-brace ordering. Whitespace/comments can occur before the opening
brace, using the existing skip and telescope parser. EOF, punctuation, decorators
and legal declaration terminators retain their own paths. No loader, namespace,
host, public record, ABI or language-state mechanism changes.

The original read-only22 census is retained: only nine observations were exact,
and five changed acceptance. The frozen extension adds qualified names, dot
neighbors, missing/newline braces, keyword-prefix names and underscore names.
Raw30 improves from 10 to 30 exact, including matching constructor name/arity
inventories on successful programs. Ten loaded fixtures run on supplied and
ordered-host routes, improving from eight to 20 exact. These retain prior
dependency failures, alias/duplicate precedence, qualified constructors and
missing-import boundaries, with unchanged exact read lists.

The genuinely checked B1/default36 passes with **zero strict differences**.
The separately frozen decorator24 remains fully exact. Original supplied39 and
ordered-host43 tools and historical fixture bytes also pass with empty strict
differences. No preparation, build or control failure occurred in this source02
sequence. Baseline mismatches are preserved results, not hidden failures.

The change adds 17 physical lines and one function, zero laws/types, and 713 bytes
relative to source01. Including the independent decorator correction, the delta
from Phase19 is 17 lines, one function and 805 bytes in declarations.bend. The
helper makes the existing constructor checks readable; this is a correctness
improvement with small code growth, not a line-count reduction. No timing was run.

Authoritative source: `selfhost/build/phase20/import-diagnostic-source-02/project`.
Its manifest binds all 214 files and contains both parent-relative counts; patches
are `declarations-parent01.patch` and `declarations-phase19.patch`. The checked
image is `import-diagnostic-build-02`. All input/API identities, individual changed
observations and closed report paths are in the adjacent machine report. Source01
and its report remain immutable and independently eligible. Root owns any later
guard composition, broad frontend/groups, performance gate and promotion; no
unreviewed corpus regression is permitted by these custom expected changes.
