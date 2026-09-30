# Independent static review of the F32 scalar-root experiment

Reviewed `design/phase30/f32-ordinary-root-ablation.md`, its generated-output
deriver and controls, and the six original `fl`/intersection definitions from
the checked attempt08 raytrace module. No static blocker was found. This note
does not claim those new controls have executed.

Both Boolean helper pairs preserve their original polarity: True returns the
sentinel, False evaluates the continuation. Primitive and let-IIFE expressions
retain each original `Math.fround` boundary. The owner callback keeps its slot
reads, exact-entry check, full live closure guard and generic fallback. Captures
are attached to definition construction, rather than the first invocation.

The F32 predicate accepts signed zero, subnormals, infinities and NaN while
rejecting boxed, coercible and non-F32 Number inputs without coercion. This
depends on the explicitly retained stable host-intrinsic contract. The prepared
independent oracle rounds each arithmetic operation and uses `Object.is` for
results, with tangent, epsilon and unusual scalar inputs. Boundary controls
include the owner and all dependencies, saved partials, raw/new/overapplied
callbacks, reentry, coercion and primitive-prototype fallbacks. Final-result
signed-zero witnesses should be retained if the formula produces them; unusual
input coverage alone would not demonstrate preservation of a signed-zero output.
