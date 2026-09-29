# Phase22 materialization feedback

Checked build05 matches 20 of 22 new public observations, compared with 13 on the installed parent. It fixes eager-versus-deferred error order, do-header alias-before-argument order, compact `<>` cursor, and immediate versus lazy header demand. All positive discarded-lambda programs retain acceptance.

Two diagnostics regress: raw `(k => k)(0) = 1` remains correctly rejected before completion, with the correct original span, but its observed term prints the unreduced application rather than the pin's `0`. Eligibility must still use the raw App; only its rejection display needs the pinned materialization behavior. The original failed materialization report is preserved. This feedback does not select the candidate.

All 22 rows were acquired and a closing audit verifies the exact consumed identities. Root delegated the private beta-origin probes to speed; this owner's prepared direct helper remains unconsumed. Source07's larger public rerun is separate.
