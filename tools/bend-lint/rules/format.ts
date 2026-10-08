// One formatter owns indentation, spacing, declaration gaps and wrapping.
// No engine option defaults: wrapAtWidth is a number | "never", and the
// existing engine accepts mixed types when the rule validates its options.
// Run: bun src/lint.ts file.bend --rules rules/format.ts --fix
// Config: { "rules": { "format/layout": { "tabWidth": 2, "wrapAtWidth": 100 } } }
// Both numbers are positive integers; "never" disables optional wrapping.
import * as path from "node:path";
import type { Options, RuleContext, LintRule } from "../src/lint.ts";
import type { Book, HTerm } from "bend2/bend.ts";

export type FormatOptions = { tabWidth: number; wrapAtWidth: number | "never" };
type Token = { text: string; beg: number; end: number; col: number; kind: "code" | "literal" | "comment" | "newline" };
type Node = Token | { open: Token; close: Token; children: Node[] };
type Doc = string | { kind: "line"; flat: string; hard?: boolean; offset?: number }
  | { kind: "group" | "nest"; doc: Doc; amount?: number } | Doc[];
type Frame = { doc: Doc; indent: number; flat: boolean };
const DELIMITERS = new Map([["(", ")"], ["[", "]"], ["{", "}"], ["<", ">"]]);

export function formatOptions(options: Options): FormatOptions {
  const { tabWidth = 2, wrapAtWidth = 100 } = options;
  const unknown = Object.keys(options).find((k) => k !== "tabWidth" && k !== "wrapAtWidth");
  if (unknown) throw new Error("format/layout has no option " + unknown);
  const positive = (v: unknown): v is number => typeof v === "number" && Number.isSafeInteger(v) && v > 0;
  if (!positive(tabWidth)) throw new Error("format/layout: tabWidth must be a positive integer");
  if (wrapAtWidth !== "never" && !positive(wrapAtWidth)) {
    throw new Error('format/layout: wrapAtWidth must be "never" or a positive integer');
  }
  return { tabWidth, wrapAtWidth };
}

// Preserve literals and comment text verbatim. In particular, a quote or #
// inside a string is not syntax; successor notation and quantities are atoms.
function tokens(source: string): Token[] {
  const out: Token[] = [];
  let at = 0, start = 0;
  while (at < source.length) {
    const beg = at, c = source[at];
    if (c === " " || c === "\t" || c === "\r") { at++; continue; }
    let kind: Token["kind"] = "code";
    if (c === "\n") { at++; kind = "newline"; }
    else if (c === "#") {
      while (at < source.length && source[at] !== "\n" && source[at] !== "\r") at++;
      kind = "comment";
    } else if (c === '"' || c === "'") {
      at++;
      while (at < source.length) {
        if (source[at] === "\\") { at += 2; continue; }
        if (source[at++] === c) break;
      }
      kind = "literal";
    } else {
      const word = /^[A-Za-z_][\w]*(?:\.[A-Za-z_]\w*)*/.exec(source.slice(at));
      const number = /^\d+(?:n\+?|\.\d+(?:[eE][+-]?\d+)?)/.exec(source.slice(at))
        ?? /^\d+/.exec(source.slice(at));
      const symbol = /^(?:<&>|\.&\.|\.\|\.|\.\^\.|->|=>|<-|==|!=|<=|>=|<<|&&|\|\||\+\+|<>|&[012])/.exec(source.slice(at));
      if (source.startsWith("<-", at) && /[\w.]/.test(source[at - 1] ?? "")) at++;
      else if (source.startsWith(">>", at) && /\s/.test(source[at - 1] ?? "")) at += 2;
      else at += (word?.[0] ?? number?.[0] ?? symbol?.[0] ?? c).length;
    }
    out.push({ text: source.slice(beg, at), beg, end: at, col: beg - start, kind });
    if (kind === "newline") start = at;
    else if (kind === "literal") {
      const newline = out[out.length - 1].text.lastIndexOf("\n");
      if (newline >= 0) start = beg + newline + 1;
    }
  }
  return out;
}

function tree(ts: Token[]): Node[] {
  const root: Node[] = [];
  const stack: Array<{ children: Node[]; group?: Extract<Node, { open: Token }> }> = [{ children: root }];
  for (let i = 0; i < ts.length; i++) {
    const t = ts[i], prev = ts[i - 1];
    const close = DELIMITERS.get(t.text);
    // Bend distinguishes type arguments from comparisons by a glued '<'.
    const angle = t.text === "<" && prev?.end === t.beg && /^[\w.]+$/.test(prev.text);
    const frame = stack[stack.length - 1];
    if (close && (t.text !== "<" || angle)) {
      const group = { open: t, close: { ...t, text: close }, children: [] as Node[] };
      frame.children.push(group);
      stack.push({ children: group.children, group });
    } else if (frame.group?.close.text === t.text) {
      frame.group.close = t;
      stack.pop();
    } else frame.children.push(t);
  }
  if (stack.length !== 1) throw new Error("format/layout: unbalanced delimiters");
  return root;
}

const first = (n: Node): Token => "open" in n ? n.open : n;
const last = (n: Node): Token => "open" in n ? n.close : n;
const soft = (flat = " "): Doc => ({ kind: "line", flat });
const hard = (offset = 0): Doc => ({ kind: "line", flat: "", hard: true, offset });
const nest = (doc: Doc, amount: number): Doc => ({ kind: "nest", doc, amount });
const group = (doc: Doc): Doc => ({ kind: "group", doc });
const OPERATORS = new Set(["+", "-", "*", "/", "%", "^", "++", "&&", "||", "<&>",
  ".&.", ".|.", ".^.", "<<", ">>", "<>", "<", ">", "<=", ">=", "==", "!=", "&", "|"]);

function gluedPrefix(a: Token, b: Node | undefined): boolean {
  return ["+", "-", "%", "&"].includes(a.text) && b !== undefined && a.end === first(b).beg;
}

function separator(a: Node, b: Node): string {
  const x = last(a), y = first(b), l = x.text, r = y.text;
  if (y.kind === "comment") return "  ";
  if (r === "," || r === ";" || r === ":" || r === "?" || r === "!" || r === ".") return "";
  if (l === "," || l === ";" || l === ":") return " ";
  if (["~", "@", "?", "!", "\\"].includes(l)) return "";
  if (gluedPrefix(x, b)) return "";
  if (/n\+$/.test(l)) return "";
  // A constructor brace must be glued to its name; a separated brace can
  // instead be the next (annotated) argument in a comma-optional call.
  if ("open" in b && r === "{" && x.end !== y.beg) return " ";
  if ("open" in b && ["(", "[", "{", "<"].includes(r)) {
    if ((/^[\w.]+$/.test(l) || l === "!" || [")", "]", "}"].includes(l))
      && !["return", "case", "match", "for", "exs", "is"].includes(l)) return "";
  }
  // Module paths are printed separately; other atoms need a separator.
  return " ";
}

function sequence(nodes: Node[], source: string, opts: FormatOptions, base: number, raw = false): Doc {
  const out: Doc[] = [];
  const levels = [base];
  let continuation: Doc[] | undefined;
  let prev: Node | undefined;
  for (let i = 0; i < nodes.length; i++) {
    const n = nodes[i], t = first(n);
    if (!("open" in n) && t.kind === "newline") {
      if (raw || prev && last(prev).kind === "comment") {
        let next = i + 1;
        while (next < nodes.length && first(nodes[next]).kind === "newline") next++;
        if (next < nodes.length) {
          const col = first(nodes[next]).col;
          while (levels.length > 1 && col < levels[levels.length - 1]) levels.pop();
          if (col > levels[levels.length - 1]) levels.push(col);
          (continuation ?? out).push(hard((levels.length - 1) * opts.tabWidth));
        } else if (prev && last(prev).kind === "comment") (continuation ?? out).push(hard());
        i = next - 1;
        prev = undefined;
      }
      continue;
    }
    if (prev) {
      const prefix = gluedPrefix(t, nodes[i + 1]);
      if (!raw && !("open" in n) && OPERATORS.has(t.text) && !prefix) {
        if (!continuation) { continuation = []; out.push(nest(continuation, opts.tabWidth)); }
        continuation.push(soft());
      } else (continuation ?? out).push(separator(prev, n));
    }
    (continuation ?? out).push(nodeDoc(n, source, opts, base));
    prev = n;
  }
  return group(out);
}

function nodeDoc(n: Node, source: string, opts: FormatOptions, base: number): Doc {
  if (!("open" in n)) return n.kind === "newline" ? "" : n.kind === "comment" ? commentText(n.text) : n.text;
  const children = n.children;
  if (!children.length) return n.open.text + n.close.text;
  // Embedded statement bodies have significant line/column boundaries.
  // They retain those boundaries, while nested ordinary calls still wrap.
  const block = children.some((c) => !("open" in c) && ["match", "case", "do", "=", ";", "%", "\\"].includes(c.text));
  if (block) return [n.open.text, sequence(children, source, opts, base, true), n.close.text];
  const parts: Node[][] = [[]];
  for (let i = 0; i < children.length; i++) {
    const c = children[i];
    if (!("open" in c) && c.text === ",") {
      const next = children[i + 1];
      if (next && first(next).kind === "comment" && !source.slice(c.end, first(next).beg).includes("\n")) {
        parts[parts.length - 1].push(c, next);
        i++;
      }
      parts.push([]);
    }
    else parts[parts.length - 1].push(c);
  }
  while (parts.length > 1 && parts[parts.length - 1].every((c) => first(c).kind === "newline")) parts.pop();
  const content: Doc[] = [];
  for (let i = 0; i < parts.length; i++) {
    if (i) {
      const prev = parts[i - 1].filter((n) => first(n).kind !== "newline");
      if (prev.length && last(prev[prev.length - 1]).kind === "comment") content.push(hard());
      else content.push(",", soft());
    }
    content.push(sequence(parts[i], source, opts, base));
  }
  const comments = children.some((c) => first(c).kind === "comment");
  // A generic closing '>' must stay glued to its preceding term: a spaced
  // '>' is parsed as a comparison by Bend, even across a newline.
  const closing: Doc = n.close.text === ">" ? "" : comments ? hard() : soft("");
  return group([n.open.text, nest([comments ? hard() : soft(""), content], opts.tabWidth), closing, n.close.text]);
}

function commentText(text: string): string {
  // Keep empty comments, whitespace, test expectations, directives and headings.
  return /^#[^\s#!|]/u.test(text) ? "# " + text.slice(1) : text;
}

// A small document printer: a group is entirely flat if it fits; otherwise
// its list separators break together. Nesting is relative, never alignment
// under a function name. The width is a target, not a license to split atoms.
function print(doc: Doc, width: number, indent: number): string {
  const stack: Frame[] = [{ doc, indent, flat: false }];
  let out = " ".repeat(indent), col = indent;
  const fits = (remaining: number, pending: Frame[]): boolean => {
    while (remaining >= 0 && pending.length) {
      const f = pending.pop()!, d = f.doc;
      if (typeof d === "string") {
        if (d.includes("\n")) return true;
        remaining -= d.length;
      } else if (Array.isArray(d)) pending.push(...d.map((doc) => ({ ...f, doc })).reverse());
      else if (d.kind === "line") {
        if (d.hard || !f.flat) return true;
        remaining -= d.flat.length;
      } else pending.push({ doc: d.doc, indent: f.indent + (d.amount ?? 0), flat: true });
    }
    return remaining >= 0;
  };
  while (stack.length) {
    const f = stack.pop()!, d = f.doc;
    if (typeof d === "string") {
      out += d;
      col = d.includes("\n") ? d.length - d.lastIndexOf("\n") - 1 : col + d.length;
    } else if (Array.isArray(d)) stack.push(...d.map((doc) => ({ ...f, doc })).reverse());
    else if (d.kind === "line") {
      if (!d.hard && (f.flat || width === Infinity)) { out += d.flat; col += d.flat.length; }
      else {
        col = f.indent + (d.offset ?? 0);
        out = out.trimEnd() + "\n" + " ".repeat(col);
      }
    } else if (d.kind === "nest") stack.push({ doc: d.doc, indent: f.indent + d.amount!, flat: f.flat });
    else stack.push({ doc: d.doc, indent: f.indent,
      flat: f.flat || width === Infinity || fits(width - col, [...stack, { doc: d.doc, indent: f.indent, flat: true }]) });
  }
  return out.trimEnd();
}

export function format(source: string, opts: FormatOptions): string {
  const nodes = tree(tokens(source));
  const records: Node[][] = [[]];
  for (let i = 0; i < nodes.length; i++) {
    const n = nodes[i];
    if (!("open" in n) && n.kind === "newline") {
      const next = nodes[i + 1], following = nodes[i + 2];
      const prefix = next && gluedPrefix(first(next), following);
      const previous = records[records.length - 1].at(-1);
      if (next && previous && last(previous).kind !== "comment" && first(next).kind !== "comment"
        && (!prefix && !("open" in next) && OPERATORS.has(next.text)
          || ["->", "=", "++", "&&", "||"].includes(last(previous).text))) continue;
      records.push([]);
    }
    else records[records.length - 1].push(n);
  }
  const rows: string[] = [], levels = [0];
  let blank = false, previous = "", previousComment = false;
  for (const record of records) {
    if (!record.length) { blank = true; continue; }
    const head = first(record[0]), col = head.col;
    while (levels.length > 1 && col < levels[levels.length - 1]) levels.pop();
    if (col > levels[levels.length - 1]) levels.push(col);
    const indent = (levels.length - 1) * opts.tabWidth;
    const declaration = /^(def|type|law)$/.test(head.text) || head.text === "@";
    const comment = head.kind === "comment";
    if (rows.length && col === 0 && ((declaration && !previousComment && previous !== "@unsafe") || comment && blank)
      && rows[rows.length - 1] !== "") rows.push("");
    else if (rows.length && blank && col > 0 && rows[rows.length - 1] !== "") rows.push("");
    let doc: Doc;
    if (head.text === "import") {
      // Paths and aliases use their own grammar; do not treat / or - as operators.
      const text = source.slice(head.beg, last(record[record.length - 1]).end).trimEnd();
      const at = text.indexOf("#");
      doc = (at < 0 ? text : text.slice(0, at)).trim().replace(/^import\s+/, "import ").replace(/\s+as\s+/, " as ");
      if (at >= 0) doc = [doc, "  ", commentText(text.slice(at))];
    } else {
      // Canonicalize an inline declaration body into the indented body form.
      const colon = col === 0 && declaration ? record.findIndex((n) => !("open" in n) && n.text === ":") : -1;
      if (colon >= 0 && colon < record.length - 1 && first(record[colon + 1]).kind !== "comment") {
        doc = [sequence(record.slice(0, colon + 1), source, opts, col),
          nest([hard(), sequence(record.slice(colon + 1), source, opts, col)], opts.tabWidth)];
      } else doc = sequence(record, source, opts, col);
    }
    rows.push(print(doc, opts.wrapAtWidth === "never" ? Infinity : opts.wrapAtWidth, indent));
    previous = record.map((n) => first(n).text).join("");
    previousComment = comment;
    blank = false;
  }
  return rows.join("\n").trimEnd() + "\n";
}

// Reparse both versions with the same imported declarations. No typecheck,
// disk writes or import fetches. Compare parsed terms, not checked terms:
// checking unfolds definitions and would hide changes in source meaning.
export function sameProgram(cx: Pick<RuleContext, "Bend" | "book" | "root" | "sources" | "walk">, text: string): boolean {
  const B = cx.Bend, root = cx.root;
  const body = (s: string) => s.split("\n").map((line) => /^import\s/.test(line) ? "" : line).join("\n");
  const original = body(root.text);
  let aliases: Record<string, string> = {};
  if (/^import\s+\S+\s+as\s+/m.test(root.text)) {
    search: for (const tld of Object.values(cx.book.tlds)) {
      for (const term of [tld.T, ...(tld.$ === "Def" && tld.v ? [tld.v] : [])]) {
        for (const tm of cx.walk(B.term_lower(term))) {
          if (tm.s?.file.str === original) { aliases = tm.s.file.al; break search; }
        }
      }
    }
  }
  // A proof consisting solely of {==} has no body span. Resolve local
  // aliases from the already loaded sources in that case.
  for (const m of root.text.matchAll(/^import\s+(\S+)\s+as\s+(\w+)/gm)) {
    if (aliases[m[2]] !== undefined) continue;
    const importedPath = path.resolve(path.dirname(root.path), m[1]).replaceAll("\\", "/");
    const imported = cx.sources.find((s) => s.path === importedPath);
    if (imported) aliases = { ...aliases, [m[2]]: imported.ns };
  }
  const qualify = (name: string) => {
    const dot = name.indexOf(".");
    return dot >= 0 && aliases[name.slice(0, dot)] !== undefined
      ? aliases[name.slice(0, dot)] + ":" + name.slice(dot + 1)
      : (root.ns ? root.ns + ":" : "") + name;
  };
  const own = new Set([...root.text.matchAll(/^(?:@unsafe\s+)?(?:def|type|law)\s+([\w.]+)/gm)].map((m) => qualify(m[1])));
  const seed = (): Book => {
    const book = B.book_nil();
    book.tlds = { ...cx.book.tlds };
    book.ctrs = { ...cx.book.ctrs };
    for (const k of own) {
      const tld = book.tlds[k];
      // A proof of an imported law fills its declaration rather than creating one.
      if (k.includes(":") && !k.startsWith(root.ns + ":") && tld?.$ === "Def") {
        book.tlds[k] = { ...tld, v: null, i: undefined, u: false };
      } else {
        if (tld?.$ === "ADT") for (const c of tld.c) delete book.ctrs[c.k];
        delete book.tlds[k];
      }
    }
    return book;
  };
  const snapshot = (s: string) => {
    const book = seed();
    const dir = root.path.slice(0, root.path.lastIndexOf("/") + 1);
    B.parse_book(book, dir, body(s), root.ns, aliases);
    const lower = (t: HTerm | null) => t === null ? null : B.term_lower(t);
    return JSON.stringify(book.order.map((k) => {
      const t = book.tlds[k];
      return t.$ === "ADT" ? [k, t.n, t.g, lower(t.T), t.c.map((c) => [c.k, c.n, lower(c.T)])]
        : [k, t.n, t.x, t.u ?? false, t.i, lower(t.T), lower(t.v)];
    }), (k, v) => k === "s" ? undefined : v);
  };
  try { return snapshot(root.text) === snapshot(text); }
  catch { return false; }
}

export const rules: LintRule[] = [{
  id: "format/layout",
  run(cx) {
    const opts = formatOptions(cx.options);
    const text = format(cx.root.text, opts);
    if (text === cx.root.text) return [];
    const spn = { file: cx.root.file, beg: 0, end: cx.root.text.length };
    if (!sameProgram(cx, text)) return [cx.diag({
      message: "Cannot safely format this syntax: the result parses differently. No fix was offered.", spn,
    })];
    return [cx.diag({ message: "Apply canonical formatting.", spn,
      fixes: [{ title: "Format file", applicability: "safe", edits: [{ spn, text }] }],
    })];
  },
}];
