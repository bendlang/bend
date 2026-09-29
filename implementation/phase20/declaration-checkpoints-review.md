# Independent review of declaration checkpoints

No remaining blocker was found on source04, genuinely checked attempt
`import-diagnostic-build-04`, guarded API
`40c8f7f3b7cd0e96aef57d7d574ebfd85607cd4e096909d083b450b4d973362c`.
The adjacent JSON binds the final source, patches, checked/bootstrap/derived
images, attempt, pin, owner receipts and reviewed gates. Source01's committed
review is unchanged. This review does not approve source02 or source03.

The datatype loop now uses the pinned ASCII name-head boundary without requiring
indentation. Complete def/type/law tokens end the loop; keyword-prefix names
remain constructor candidates. Other reserved or malformed names fail before
alias and duplicate checks, which both precede opening-brace parsing. Valid
unindented constructors and newline/comment-separated braces follow the same
field telescope and publication path. A decorator exits to the existing
pending-unsafe/top-level owner. Dependency discovery is unchanged; ordered-host
controls preserve earlier dependency failure and do not read imports appearing
later in the body.

Independent review found a real acceptance regression in the original correction:
`C;{}` passed because the new brace checkpoint used `f_skip`, which also consumes
semicolons. The root's related loop-boundary review exposed the same interaction
before unindented first/later constructors. Frozen44 preserves15 newly false
acceptances and9 inherited false acceptances. Source02's earlier50 exact controls
did not cover these cases; source03 inherited the defect.

Source04 corrects only the datatype route. Both loop feeds and all three uses at
the new brace checkpoint use existing `f_space`, which consumes newline tokens
but preserves semicolons; comments have already been skipped by the lexer. The
loop exit calls `f_top` on the already-spaced cursor, preventing `f_tops` from
silently removing the semicolon or moving its diagnostic. Actual generated
helper bodies confirm these replacements. The final44 comparisons are exact.

The first-element guards are separately sound within this scope. They fire only
when the accumulated head/pattern list is empty and the current token is colon
or comma. Original nonempty optional-comma, missing-comma, trailing-comma and
doubled-comma paths remain unchanged. In the actual generated API, `List.is_empty`
inspects one Nil/Con tag. Token predicates are evaluated eagerly but remain
constant-time; neither they nor the selected error branch traverse the growing
accumulator or enter the later term/body parser. The original first offending
cursor is retained. All54 frozen neighboring observations are exact.

Final source04 also passes constructor50, decorator24 and maintained36 exactly;
unchanged supplied39 and ordered-host43 have empty strict-difference lists.
The separate `declaration-programs.md/json` gate passes12 exact full-program
check/interpreter/JS/native observations for the newly accepted positive grammar.

This review used source/generated-code inspection and closed owner evidence;
the additional program gate is explicitly separate. Constructor name validation
and first-element predicates add bounded correctness work on successful parsing.
No timing, zero-cost, broad corpus or universal correctness claim is made here.
Root owns broad frontend/group, controlled cost, installation and package gates.
The source01 review's inherited offending-Unicode renderer limitation still applies.
