# First Phase22 production controls

The first production candidate is withheld. All 124 frozen observations were acquired against `context-build-04` / source05; 108 are exact versus 73 on the installed baseline (36 gains, one lost exact match). The original main/do comparison reports remain failed. A separate read-only closing audit confirms all consumed input, API, attempt and cache hashes are unchanged.

| Cohort | Parent exact | Candidate exact | Outcome |
| --- | ---: | ---: | --- |
| Original60 | 27 | 52 | Guard fails on a changed false-acceptance outcome |
| Do20 | 17 | 18 | Imported return-type parse regression; one lost exact |
| Rewrite/array40 | 29 | 38 | No regression; two inherited diagnostic differences |
| Alias4 | 0 | 0 | Correct refusal, wrong caret |

Both maintained monad-destructuring observations are now exact. Scope checkpoints and constructor-pattern refusals improve. The remaining grouped raw local/parallel comma forms must still refuse; current candidate accepts them. Local-bang error wording also differs. The imported `Box.Id<U32>` return annotation now refuses at `>` expecting `:`, before entering the do body.

Rewrite controls all agree. U32 count refusal, explicit Succ count acceptance, namespace-before-count order and written Array.set binding now agree. Nonvariable Array.set followed by semicolon still points at the following statement instead of the semicolon. Alias ambiguity now has the correct expected/observed fields but points after the operator rather than after `]`.

The original prospective fixture assumptions and raw false statuses are preserved. The 24/12 program baselines remain frozen; candidate execution waits for these production acceptance boundaries to close. No compiler source or oracle was edited by this owner.
