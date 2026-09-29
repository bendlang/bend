# Preserve semicolons throughout the datatype checkpoint

The first brace-boundary design is extended before source04. The same f_skip
helper also feeds the constructor loop from f_type_kind and f_type_ctor; the loop
then falls through f_tops, which skips semicolons again. Widening the loop to admit
valid column-zero constructors exposes new false acceptance if those semicolons
are erased first. Preserve all earlier sources, controls and reports.

Use f_space at exactly the two datatype loop-entry calls and at the new brace
checkpoint. Use f_top on the already-spaced loop-exit cursor. Global f_skip,
f_tops and the telescope parser remain unchanged. The existing top-level error
producer then observes a semicolon at its real position, as the pin does; no
error-string substitution or new state is needed. This is the common whitespace
contract of the datatype grammar, not a global semicolon conformance change.

Extend the eight raw/nine loaded brace controls with six raw/loaded loop neighbors:
semicolon before the first column-zero constructor; between an indented and a
column-zero constructor; the corresponding inherited indented forms; semicolon
before a next def; and comment/newline separation between constructors. Run both
source01 and source02 against identical pinned strings before preparing source04.
Keep alias/duplicate/name errors before brace errors. Existing raw30 includes the
legal def/type/law/decorator/EOF transitions and remains mandatory on the final
image, along with the complete planned source03 gates.

Source03's completed checked build is retained but not eligible for promotion:
its unchanged source02 datatype checkpoint contains the same review finding.
The final report must distinguish new versus inherited baseline acceptance errors
and explicitly supersede the source02/source03 publication recommendation.
