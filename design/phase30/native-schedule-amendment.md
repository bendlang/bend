# Native host failure and the final timing schedule

This records the lead's schedule decision made when the remaining native pilot
closed, before the renewed final16 timing batch was granted. The frozen batch
design and its input hash remain unchanged; this is an explicit exception to
its requirement that broad conformance close successfully before timing.

The selected JavaScript/runtime gates, original JavaScript outputs and renewed
frontend comparison had passed. The remaining native acquisition produced the
same Clang host-process error on both compilers, with no differing language
observation. That failure prevents claiming native execution validation, but
does not invalidate a controlled comparison of the already-validated JavaScript
artifacts. All acquisition jobs were stopped before timing began.

The lead therefore moved native environment diagnosis and any bounded retry
after the exclusive timing window. This permits measurement only. It does not
relax the native oracle, rewrite the failed acquisition, accept existing binaries
as executed, or grant installation before release checks. The exact host error,
lost raw-status limitation and retry boundary remain in the backend report and
the separate native retry design. The compiler source and compared JS bytes are
unchanged by this scheduling decision.
