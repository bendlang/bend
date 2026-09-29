# Phase22 rewrite and array baseline

Frozen feature40 has 29 exact observations; alias4 has zero; program12 has eight. All acquisitions are healthy. Raw failures and two incorrect prospective alias expectations remain unchanged. Programs cover rewrite shadow restoration (7), a written Array.set statement (9), and existing nested index writes (34). Only the written-call program differs in all four parent lanes.

Two code findings require contextual integration checks. First, a namespace Error under a completed Let must be returned shallowly before checking array count or an index RHS. The pinned `[(x = 1; x + 1) : 0*3n]` witness reports the namespace error; the raw parent reports the later count error. Root has prepared a shared helper correction. Second, the actual frozen namespace helper puts an alias failure at operator end85; pin points at86, the space immediately after `]`. The next token starts at87. `previousEnd` is the correct cursor for this delimiter checkpoint, with the original operator origin preserved on success.

The pinned count reader accepts Nat literals and explicit Succ/Zero chains, refuses U32 counts, and checks closing delimiter before namespace and count. Parent behavior differs on U32 and Succ. The new fixtures preserve those outcomes for the real production route. Rewrite inspection confirms motive-only endpoint/evidence scope, restoration before body, and shallow proof/motive failure stops. The actual future image still needs all frozen public controls.

The original alias-good-RHS fixture lacked a module `add`, so the pin legitimately fell back to global U32.add and accepted it. Both mistaken refusal expectations are preserved. A separate four-observation cohort declares that module member; pin then reports ambiguity immediately after `]` before both valid and invalid RHS neighbors. No oracle or fixture was rewritten.

The JSON binds the baseline selections/results and the direct private witness. No compiler source was edited. This report claims baseline closure and review findings only; production candidate controls are separate.
