# Constructor brace whitespace correction

Independent source02 review identified a concrete boundary to test: f_skip before
the new `{` checkpoint skips semicolons as well as newlines, while the pinned
parse_eat only skips whitespace/comments. Source03's first-element composition is
already consumed and must remain immutable. Do not promote either candidate on
the earlier focused results alone.

Freeze semicolon, doubled-semicolon, newline/semicolon, whitespace/newline/comment,
duplicate-name and alias-name controls. Compare the identical files with source01,
source02 and the pin before correcting source. Name validation and alias/duplicate
freshness must continue to precede the brace error. Record any new source02 false
acceptance explicitly; existing reports remain historical bounded results.

If confirmed, prepare fresh source04 from source03. Replace only f_skip(f_tl(ts))
at the new constructor-header brace checkpoint with f_space(f_tl(ts)), which skips
newlines after lexical whitespace/comment removal. Do not change global f_skip,
the telescope parser, declaration terminators or any inherited semicolon policy
elsewhere. This correction introduces no helper, state, law or type.

Require genuine B1/default36 and all source03 planned controls on the final image,
plus the new semicolon controls. The final report must supersede source02/source03
for promotion, retain the counterexample and bind every failed/superseded attempt.
Root owns broad regression gates and installation.
