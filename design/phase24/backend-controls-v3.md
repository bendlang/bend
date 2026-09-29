# Phase24 final fixture maintenance

The v2 foreign FID control consumes the affine IO result `n` twice; both compilers
reject it identically during checking. Retain that fixture and all four original
outcomes. Before the v3 run, replace the two parallel calls with composition
`a_b(a.b(U32.to_nat(n)))`, consuming `n` once while keeping both recursive
functions live. Its expected result is2, since the FID comparison yields1 and
the outer function adds1. No compiler or generated C change is proposed.

The exact historical native unit script initially cannot bootstrap its scoped
assembly: KF_Source is absent. Add the existing core/reach.bend module that owns
the now-shared foreign scanner to that test assembly only. The new isolated copy
records this live test-script overlay and all frozen production dependencies.
Retain backend-native-unit-01 before the second attempt. Correct small confirmed
synthetic fixture ABI issues only if the next run exposes them; preserve failures.
