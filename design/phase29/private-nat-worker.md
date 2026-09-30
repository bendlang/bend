# Prospective Phase29 private Nat worker

Frozen after the first six-output screen, before production worker code/builds
or worker compiler measurements. The disposable experiment measured unchanged
2.787ms, arithmetic1.007ms, worker1.359ms, combined0.436ms per128-step call; the
checked arithmetic compiler emitted0.992ms. These are provisional short-window
results. Independent120-input oracles pass; counters identify repeated partial
descriptors as a removable mechanism. This justifies a narrow production trial.

Recognize only a top-level native Nat Zero/Succ matcher with explicit unlifted,
live residual parameter telescopes. Preserve the public matcher, its initial
argument demand and partial descriptors. Change the fully entered successor
callback to a private local-slot loop. Support only reviewed Let/Ann tail chains
whose final exactly saturated self call decrements to the captured predecessor.
Reject erased, eta-short, unknown, foreign, non-native or otherwise unsupported
shapes. No Nat representation, runtime ABI or global arity change.

The loop evaluates next arguments once in source order into temporaries. Its
recursive Nat value is the already captured predecessor; matching that value is
total on supported native Nat inputs. At zero, execute the original Zero body;
otherwise recover the next predecessor and continue. Preserve parallel-let scope,
temporary ownership, public partial behavior and bounded tail stack. Reuse the
ordinary expression emitter for non-tail expressions. Do not hand-patch output
bytes as a production path.

An independent reviewer checks the recognizer and error/effect order, with0/1/many
iterations, varying inputs, partial calls, refusal boundaries and deep recursion.
Compare the new checked arithmetic+worker image against immutable arithmetic-only,
old and TypeScript outputs. The disposable worker-only comparison remains separate.
Use the original prospective screen/confirmation protocols; all failures survive.
General argument grouping is deferred to avoid adding a third production mechanism.
