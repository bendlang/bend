// The ES module's TypeScript view of Bend values at the JS boundary.
import * as Bend from "./bend.ts";
import * as Comp from "./comp.ts";

const TS_NO_ALIAS: Record<string, true> = {
  any: true, bigint: true, boolean: true, never: true, number: true,
  object: true, string: true, symbol: true, unknown: true, void: true,
};

const HOST_PRIMITIVES: Record<string, string> = {
  Nat: "bigint", U32: "number", F32: "number", Bool: "boolean",
  Char: "string", String: "string",
};

const EMPTY_VARS = new Map<Bend.Name, string>();

// An unsupported dependent or higher-order type is unknown, not a false
// promise about the value's JS representation.
function type_text(book: Bend.Book, ty: Bend.HTerm, refs: Set<Bend.Name>,
  vars: Map<Bend.Name, string>): string {
  const v = Bend.term_force(ty);
  if (v.$ === "Var") {
    return vars.get(v.k) ?? "unknown";
  }
  const t = Bend.term_wnf(book, ty);
  if (t.$ !== "ADT") {
    return "unknown";
  }
  if (Object.hasOwn(HOST_PRIMITIVES, t.k)) {
    return HOST_PRIMITIVES[t.k];
  }
  if (t.k === "Array") {
    return t.x.length === 1 ? type_text(book, t.x[0], refs, vars) + "[]"
      : "unknown";
  }
  const adt = book.tlds[t.k];
  if (adt?.$ !== "ADT" || !Comp.js_named(t.k)
    || Object.hasOwn(TS_NO_ALIAS, t.k)) {
    return "unknown";
  }
  const doms = Bend.tele_unbind(book, adt.T).doms;
  const args: string[] = [];
  for (let i = 0; i < doms.length; i += 1) {
    const kind = Bend.term_wnf(book, doms[i][2]);
    if (kind.$ === "Qnt") {
      continue;
    }
    if (kind.$ !== "Typ") {
      return "unknown";
    }
    args.push(t.x[i] ? type_text(book, t.x[i], refs, vars) : "unknown");
  }
  refs.add(t.k);
  return t.k + (args.length === 0 ? "" : "<" + args.join(", ") + ">");
}

export function emit(book: Bend.Book, outs: Bend.Name[]): string {
  const refs = new Set<Bend.Name>();
  const defs = Comp.js_signatures(book, outs).map(({ k, live, ret }) => {
    const used = new Set<string>();
    const params = live.map(([, name, A], i) => {
      const base = Comp.js_named(name) ? name : "arg" + i;
      let label = base;
      for (let j = 1; used.has(label); j += 1) {
        label = base + "_" + j;
      }
      used.add(label);
      return `${label}: ${type_text(book, A, refs, EMPTY_VARS)}`;
    }).join(", ");
    return { k, params, result: type_text(book, ret, refs, EMPTY_VARS) };
  });
  const types: string[] = [];
  for (const k of refs) {
    const adt = book.tlds[k] as Bend.ADT;
    const doms = Bend.tele_unbind(book, adt.T).doms.filter((d) =>
      Bend.term_wnf(book, d[2]).$ !== "Qnt");
    const vars = new Map(doms.map(([, name], i) =>
      [name, doms.length === 1 ? "T" : "T" + i]));
    const generics = [...vars.values()];
    const arms = adt.c.map((c) => {
      const fields = Bend.tele_unbind(book, c.T).doms.slice(-c.n)
        .filter(([q]) => q.$ !== "None").map(([, name, A]) =>
          `${JSON.stringify(name)}: ${type_text(book, A, refs, vars)}`);
      return `{ $: ${JSON.stringify(c.k)}${fields.length === 0 ? ""
        : "; " + fields.join("; ")} }`;
    });
    types.push(`export type ${k}${generics.length === 0 ? ""
      : "<" + generics.join(", ") + ">"} = ${arms.join(" | ") || "never"};`);
  }
  const named = defs.filter(({ k }) => Comp.js_named(k));
  const names = new Map(named.map(({ k }, i) =>
    [k, Object.hasOwn(TS_NO_ALIAS, k) ? "$0export" + i : k]));
  const props = defs.map(({ k, params, result }) =>
    `  ${JSON.stringify(k)}: ${names.has(k) ? "typeof " + names.get(k)
      : "(" + params + ") => " + result};`).join("\n");
  return "// A Nat is a bigint in 0..2^48-1 at the JS boundary.\n"
    + types.join("\n") + "\n"
    + named.map(({ k, params, result }, i) =>
      Object.hasOwn(TS_NO_ALIAS, k)
        ? `declare const $0export${i}: (${params}) => ${result};\n`
          + `export { $0export${i} as ${k} };`
        : `export declare function ${k}(${params}): ${result};`).join("\n")
    + `\ndeclare const $bend: {\n${props}\n};\nexport default $bend;\n`;
}
