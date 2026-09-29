# Constructor goal note correction

The source had omitted the pinned check that the constructor family must be
absent before suggesting datatype angle arguments. This adds that predicate to
the existing trace renderer; no term/checker representation change is needed.

The isolated wave7 candidate `checker-note-source-01` builds through genuine
checked B1 and guarded equality derivation. Maintained36 pass, retaining two
existing strict differences. Both strict paired controls are exact: Base F32's
`switch_miss_guard` loses its incorrect note, while `ctr_of_datatype` retains its
required note. See `checker-note-focus-01/report.json` and the adjacent JSON for
identities. There is no speed claim; integration remains the root gate's decision.
