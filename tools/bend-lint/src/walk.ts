// The children of a checked term. Binders are explicit, so Var.v cells
// are not followed. A new term kind in bend.ts is a type error here, and
// throws when the code runs.

import type { LTerm } from "./types.ts";

export function children(tm: LTerm): LTerm[] {
  switch (tm.$) {
    case "Let": return [...tm.v, tm.f];
    case "Lam": return [tm.f];
    case "Sub": return [tm.f];
    case "App": return [tm.f, tm.x];
    case "Ctr": return tm.x;
    case "ADT": return tm.x;
    case "Mat": return [tm.h, tm.m];
    case "Rwt": return [tm.e, tm.p, tm.f];
    case "Typ": return [tm.g];
    case "Min": return [tm.a, tm.b];
    case "All": return [tm.A, tm.B];
    case "Eql": return [tm.a, tm.b, tm.T];
    case "Ann": return [tm.x, tm.T];
    case "Var":
    case "Ref":
    case "Qnt":
    case "Qua":
    case "Lit":
    case "Efq":
    case "Rfl":
    case "Hol":
      return [];
    default: {
      const kind: never = tm;
      throw new Error("bend-lint: unknown term kind " + (kind as { $: string }).$
        + "; update tools/bend-lint/src/walk.ts");
    }
  }
}

export function* walk(tm: LTerm): Generator<LTerm> {
  yield tm;
  for (const child of children(tm)) {
    yield* walk(child);
  }
}
