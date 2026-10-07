import { expect, test } from "bun:test";
import * as fs from "node:fs";

import { Bend } from "../src/core.ts";
import { BEND_TS, PatchError, blob, current, patch, pinned, selfCheck } from "../src/instrument.ts";

const src = fs.readFileSync(BEND_TS, "utf8");

test("patch wraps term_infer and term_check once each", () => {
  const out = patch(src);
  expect(out.match(/^export function term_infer\(/gm)?.length).toBe(1);
  expect(out.match(/^export function term_check\(/gm)?.length).toBe(1);
  expect(out).toContain("function lint_infer(");
  expect(out).toContain("function lint_check(");
  expect(out).toContain("export const BEND_LINT_PATCH = 1;");
});

test("patch fails loudly when a signature changes", () => {
  expect(() => patch(src.replace("export function term_infer(book: Book,", "export function term_infer(bk: Book,")))
    .toThrow(PatchError);
  expect(() => patch(src.replace(/^export function term_check\(/m, "export function term_check2(")))
    .toThrow(/found 0 term_check/);
});

test("patch fails loudly on a second signature", () => {
  const sig = src.match(/^export function term_check\(.*$/m)![0];
  expect(() => patch(src + "\n" + sig + "\n")).toThrow(/found 2 term_check/);
});

test("the loaded bend.ts is the patched one, and the self-check passes", () => {
  expect((Bend as unknown as { BEND_LINT_PATCH?: number }).BEND_LINT_PATCH).toBe(1);
  expect(() => selfCheck(Bend)).not.toThrow();
});

test("the pin is a git blob hash, and CRLF reads as LF", () => {
  expect(pinned()).toMatch(/^[0-9a-f]{40}$/);
  expect(blob("a\r\nb\n")).toBe(blob("a\nb\n"));
  // git hash-object of "hello\n"
  expect(blob("hello\n")).toBe("ce013625030ba8dba906f756967f9e9ca394464a");
  if (process.env.BEND_LINT_UNPINNED !== "1") {
    expect(current()).toBe(pinned());
  }
});
