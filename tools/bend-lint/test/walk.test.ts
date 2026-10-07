import { expect, test } from "bun:test";
import { fileURLToPath } from "node:url";

import { lint } from "../src/lint.ts";
import { children, walk } from "../src/walk.ts";
import type { LTerm } from "../src/types.ts";

test("walk reaches matches, lets and annotations of checked bodies", async () => {
  const file = fileURLToPath(new URL("./fixtures/userland.bend", import.meta.url));
  const res = await lint(file, []);
  expect(res.ok).toBe(true);
  const kinds = new Set<string>();
  for (const name of res.book.order) {
    const tld = res.book.tlds[name];
    if (tld.$ !== "Def" || tld.e === undefined) continue;
    for (const tm of walk(tld.e)) kinds.add(tm.$);
  }
  for (const k of ["Mat", "Lam", "App", "Var", "Ctr"]) expect(kinds.has(k)).toBe(true);
});

test("an unknown term kind fails loudly", () => {
  expect(() => children({ $: "Nope" } as unknown as LTerm)).toThrow(/unknown term kind Nope/);
});
