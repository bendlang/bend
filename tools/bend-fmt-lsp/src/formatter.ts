export type FormatOptions = {
  tabSize?: number;
  insertSpaces?: boolean;
};

type Token = {
  text: string;
  kind: "word" | "number" | "literal" | "symbol";
  gap: boolean;
  col: number;
};

type Line = {
  indent: string;
  ending: string;
  comment: string;
  commentGap: boolean;
  tokens: Token[];
};

const MULTI = ["<&>", ".|.", ".^.", ".&.", "==", "!=", "->", "<-", "=>", "&&", "||", "++", "<>", "<=", ">=", "<<", ">>"];
const WORD = /[A-Za-z0-9_.]/;
const HEAD = /[A-Za-z_]/;
const DIGIT = /[0-9]/;
const BINARY = new Set(["=", "==", "!=", "->", "<-", "=>", "+", "-", "*", "/", "%", "&&", "||", "++", "<>", "<&>", "<=", ">=", "<<", ">>", ".|.", ".^.", ".&.", "&", "|"]);
const PREFIX_CONTEXT = new Set(["(", "{", "[", "<", ",", ";", ":", "=", "for", "case", "return", "~"]);
const ANGLES = new Set(["<", ">", "<<", ">>"]);
const KEYWORDS = new Set(["return", "match", "case", "do", "for", "exs", "where", "is", "import", "def", "type", "law"]);

// Bend reads % as modulo only when whitespace follows it, and as a rewrite otherwise.
function gluedPercent(line: Line, index: number): boolean {
  if (line.tokens[index].text !== "%") return false;
  const next = line.tokens[index + 1];
  return next ? !next.gap : line.comment !== "" && !line.commentGap;
}

// A logical line ends at a newline outside a literal.
function readLine(source: string, start: number, lines: Line[]): number {
  let i = start;
  while (source[i] === " " || source[i] === "\t") i++;
  const indent = source.slice(start, i);
  let bol = start;
  const tokens: Token[] = [];
  let commentAt = -1;
  let hadGap = false;
  while (i < source.length) {
    const char = source[i];
    if (char === "\n" || (char === "\r" && source[i + 1] === "\n")) break;
    if (/\s/.test(char)) {
      hadGap = tokens.length > 0;
      i++;
      continue;
    }
    if (char === "#") {
      commentAt = i;
      const end = source.indexOf("\n", i + 1);
      i = end < 0 ? source.length : source[end - 1] === "\r" ? end - 1 : end;
      break;
    }
    const tokenAt = i;
    const col = i - bol;
    let kind: Token["kind"] = "symbol";
    if (char === "\"" || char === "'") {
      kind = "literal";
      const quote = char;
      i++;
      // In ''', the first apostrophe after the opener is the character.
      if (quote === "'" && source[i] === "'") i++;
      let escaped = false;
      let closed = false;
      while (i < source.length) {
        const next = source[i++];
        if (next === "\n") bol = i;
        if (escaped) escaped = false;
        else if (next === "\\") escaped = true;
        else if (next === quote) {
          closed = true;
          break;
        }
      }
      if (!closed) throw new Error("unterminated literal");
    } else if (tokens.length === 1 && tokens[0].text === "import" && hadGap) {
      kind = "word";
      while (i < source.length && !/\s/.test(source[i]) && source[i] !== "#") i++;
    } else if (HEAD.test(char)) {
      kind = "word";
      i++;
      while (i < source.length && WORD.test(source[i])) i++;
    } else if (DIGIT.test(char)) {
      kind = "number";
      i++;
      while (i < source.length && DIGIT.test(source[i])) i++;
      if (source[i] === "." && DIGIT.test(source[i + 1] ?? "")) {
        i++;
        while (i < source.length && DIGIT.test(source[i])) i++;
      }
      if (/[eE]/.test(source[i] ?? "") && DIGIT.test(source[i + 1] ?? "") || /[eE]/.test(source[i] ?? "") && /[+-]/.test(source[i + 1] ?? "") && DIGIT.test(source[i + 2] ?? "")) {
        i++;
        if (/[+-]/.test(source[i] ?? "")) i++;
        while (i < source.length && DIGIT.test(source[i])) i++;
      }
      if (source[i] === "n") i++;
    } else {
      // A comparison needs a left operand separated from >; Box<-T opens a <, not a bind.
      const multi = MULTI.find((value) => source.startsWith(value, i) && (value !== ">=" || !tokens.length || hadGap && tokens.at(-1)?.text !== ",")
        && (value !== "<-" || hadGap || tokens.at(-1)?.kind !== "word" || !HEAD.test(source[i + 2] ?? "")));
      i += multi?.length ?? 1;
    }
    tokens.push({ text: source.slice(tokenAt, i), kind, gap: hadGap, col });
    hadGap = false;
  }
  const ending = i === source.length ? "" : source[i] === "\r" ? "\r\n" : "\n";
  const comment = commentAt < 0 ? "" : source.slice(commentAt, i);
  lines.push({ indent, ending, comment, commentGap: hadGap, tokens });
  return i + ending.length;
}

function splitLines(source: string): Line[] {
  const lines: Line[] = [];
  for (let i = 0; i < source.length;) i = readLine(source, i, lines);
  return lines;
}

function unary(tokens: Token[], index: number): boolean {
  const token = tokens[index].text;
  if (!["+", "-", "~", "?", "@", "&"].includes(token)) return false;
  const previous = tokens[index - 1]?.text;
  const next = tokens[index + 1];
  if (!next) return false;
  const atPrefix = index === 0 || PREFIX_CONTEXT.has(previous) || BINARY.has(previous);
  if (token === "~") return atPrefix;
  // @-x and @+x bind x with a quantity.
  if (token === "@" && (next.text === "-" || next.text === "+") && !next.gap) return atPrefix;
  if (token === "+" || token === "-") return next.kind === "word" && (!next.gap || (index > 0 && atPrefix));
  return next.kind === "word" || next.kind === "number" ? atPrefix : false;
}

function keepAngleGap(left: Token, right: Token): boolean | null {
  if (!ANGLES.has(left.text) && !ANGLES.has(right.text)) return null;
  return right.gap;
}

function needsSpace(tokens: Token[], index: number): boolean {
  const left = tokens[index - 1];
  const right = tokens[index];
  if (!left) return false;
  if (left.text === "%") return right.gap;
  if ([")", "]", "}", ",", ";"].includes(right.text)) return false;
  if (right.text === ":") return right.gap;
  if (["(", "[", "{"].includes(left.text)) return false;
  if (left.text === ",") return true;
  if (right.text === "!" && (left.kind === "word" || [")", "]", "}"].includes(left.text))) return false;
  if (left.text === "!" && right.text === "(") return false;
  if (right.text === "?" && left.kind === "word" && (!tokens[index + 1] || tokens[index + 1].text === "(")) return right.gap;
  if (left.text === "?" && right.text === "(" && tokens[index - 2]?.kind === "word") return false;
  if (right.text === "(" || right.text === "[") {
    const suffix = (left.kind === "word" && !KEYWORDS.has(left.text)) || left.kind === "number" || left.kind === "literal" || [")", "]", "}", ">", ">>"].includes(left.text);
    return !suffix;
  }
  // A separated brace can start the next annotated argument, rather than a constructor.
  if (right.text === "{" && ((left.kind === "word" && !["return", "case"].includes(left.text)) || [">", ">>", "}"].includes(left.text))) return left.kind === "word" && right.gap;
  if (left.text === "\\" && right.text === "{") return false;
  if (left.text === "." || right.text === ".") return false;
  if (left.kind === "number" && left.text.endsWith("n") && (right.text === "+" || right.text === "++")) return right.gap;
  if ((left.text === "+" || left.text === "++") && tokens[index - 2]?.kind === "number" && tokens[index - 2].text.endsWith("n")) return right.gap;
  if (unary(tokens, index - 1)) return false;
  if (unary(tokens, index)) return !["(", "[", "{", "<"].includes(left.text);
  const angle = keepAngleGap(left, right);
  if (angle !== null) return angle;
  if (BINARY.has(left.text) || BINARY.has(right.text)) return true;
  if (left.text === ":") return true;
  return true;
}

// The formatted code and the physical column of each formatted token.
function formatTokens(tokens: Token[], col: number): [string, number[]] {
  let output = "";
  const starts: number[] = [];
  for (let i = 0; i < tokens.length; i++) {
    if (needsSpace(tokens, i)) {
      output += " ";
      col++;
    }
    starts.push(col);
    const text = tokens[i].text;
    output += text;
    const lf = text.lastIndexOf("\n");
    col = lf < 0 ? col + text.length : text.length - lf - 1;
  }
  return [output, starts];
}

// Bracketed continuations and comment-only lines use relative indentation;
// inline body pins below preserve the columns that still matter to the parser.
function looseLines(lines: Line[]): boolean[] {
  let open = 0;
  return lines.map((line) => {
    const loose = open > 0 || line.tokens.length === 0;
    for (const token of line.tokens) {
      if (["(", "[", "{"].includes(token.text)) open++;
      else if ([")", "]", "}"].includes(token.text)) open = Math.max(0, open - 1);
    }
    return loose;
  });
}

type BodyScope = { open: number; angle: number; end: number };
type InlineBody = { at: number; scope?: BodyScope };

// The tokens that start a body on the line of its `do`, `match`, `case` or
// `def` header, `=>` lambda opener, `;` separator, `(` group opener or
// parenthesized `,` separator. As in `do IO<Unit>: a`, Bend pins the lines
// after it to the column of `a`.
function inlineBodies(lines: Line[]): InlineBody[][] {
  let open = 0;
  const angles = [0];
  const parens: number[] = [];
  const bodyScopes: BodyScope[] = [];
  let header: { open: number; angle: number; typed: boolean } | null = null;
  return lines.map((line, row) => line.tokens.flatMap((token, index): InlineBody[] => {
    if (token.kind === "word" && ["do", "match", "case", "def"].includes(token.text)) {
      header = { open, angle: 0, typed: token.text === "do" || token.text === "def" };
    } else if (token.text === "=>" || token.text === ";") {
      if (open > 0) bodyScopes.push({ open, angle: angles[open], end: lines.length });
      return index + 1 < line.tokens.length ? [{ at: index + 1, scope: bodyScopes.at(-1) }] : [];
    } else if (["(", "[", "{"].includes(token.text)) {
      open++;
      angles.push(0);
      if (token.text === "(") parens.push(open);
      if (token.text === "(" && index + 1 < line.tokens.length) {
        bodyScopes.push({ open, angle: angles[open], end: lines.length });
        return [{ at: index + 1, scope: bodyScopes.at(-1) }];
      }
    } else if ([")", "]", "}"].includes(token.text)) {
      if (parens.at(-1) === open) parens.pop();
      if (open > 0) angles.pop();
      open = Math.max(0, open - 1);
    } else if (ANGLES.has(token.text)) {
      if (token.text === "<") angles[open]++;
      else if (token.text[0] === ">") angles[open] = Math.max(0, angles[open] - token.text.length);
      if (header?.typed && open === header.open) {
        header.angle += token.text.length * (token.text[0] === "<" ? 1 : -1);
      }
    } else if (header && token.text === ":" && open === header.open && header.angle === 0) {
      header = null;
      return index + 1 < line.tokens.length ? [{ at: index + 1, scope: bodyScopes.at(-1) }] : [];
    }
    // Only commas outside an inline body's type arguments end its argument/body scope.
    while (bodyScopes.length) {
      const scope = bodyScopes.at(-1)!;
      const inside = scope.open < open || scope.open === open && scope.angle <= angles[open];
      const comma = token.text === "," && scope.open === open && scope.angle === angles[open];
      if (inside && !comma) break;
      // A leading closer/separator has no body statement to pin on this line.
      bodyScopes.pop()!.end = row - (index === 0 ? 1 : 0);
    }
    if (token.text === "," && parens.at(-1) === open && angles[open] === 0 && index + 1 < line.tokens.length) {
      bodyScopes.push({ open, angle: angles[open], end: lines.length });
      return [{ at: index + 1, scope: bodyScopes.at(-1) }];
    }
    return [];
  }));
}

type Level = { col: number; depth: number; parent?: Level };

// A tab is one column, as in the parser. Loose lines use a separate path.
// As in bend-lint's Layout, cases retain their match's path across body dedents.
// Inline first cases anchor their later arms and nested matches.
function indentDepths(lines: Line[], loose = looseLines(lines), anchors: (Token | undefined)[] = []): number[] {
  const depths: number[] = [];
  const scopes: { parent: number; first?: number; current: number; level?: Level; anchor?: Token }[] = [];
  let main: Level = { col: 0, depth: 0 };
  let level = main;
  let wasLoose = false;
  let brackets = 0;
  for (const [index, line] of lines.entries()) {
    if (line.tokens.length === 0 && line.comment === "") {
      depths.push(-1);
      continue;
    }
    if (!loose[index] || !wasLoose) level = main;
    const width = line.indent.length;
    while (level.parent && width < level.col) level = level.parent;
    if (width > level.col) level = { col: width, depth: level.depth + 1, parent: level };
    const head = line.tokens[0];
    for (const token of line.tokens) {
      if (token.kind === "symbol" && ["(", "[", "{"].includes(token.text)) brackets++;
      else if (token.kind === "symbol" && [")", "]", "}"].includes(token.text)) brackets--;
      else if (brackets === 0 && head?.text !== "import" && token.kind === "word") {
        if (["def", "type", "law"].includes(token.text)) scopes.length = 0;
        if (token.text === "match") {
          scopes.push({ parent: scopes.at(-1)?.current ?? -1, current: -1, anchor: scopes.at(-1)?.anchor });
        } else if (token.text === "case") {
          while (scopes.length) {
            const scope = scopes.at(-1)!;
            if (scope.first === undefined ? token.col > scope.parent : token.col >= scope.first) break;
            scopes.pop();
          }
          const scope = scopes.at(-1);
          if (!scope) continue;
          if (scope.first === undefined) {
            scope.first = token.col;
            if (token === head) {
              const parent = scopes.at(-2)?.level;
              if (parent && level.depth <= parent.depth) level = { col: token.col, depth: parent.depth + 1, parent };
              scope.level = level;
            } else scope.anchor = token;
          } else if (token === head && scope.level) {
            level = scope.level.col === token.col ? scope.level : { ...scope.level, col: token.col };
            scope.level = level;
          }
          if (token === head) anchors[index] = scope.anchor;
          scope.current = token.col;
        }
      }
    }
    if (!loose[index]) main = level;
    wasLoose = loose[index];
    depths.push(level.depth);
  }
  return depths;
}

function fingerprint(lines: Line[]): string {
  const depths = indentDepths(lines);
  return lines.map((line, index) => {
    if (line.tokens.length === 0) return "";
    const texts = line.tokens.map((token, at) => token.text + (gluedPercent(line, at) ? "\u0001" : ""));
    return depths[index] + ":" + texts.join("\u0000");
  }).join("\n");
}

export function formatBend(source: string, options: FormatOptions = {}): string {
  let lines: Line[];
  try {
    lines = splitLines(source);
  } catch {
    return source;
  }
  const loose = looseLines(lines);
  const anchors: (Token | undefined)[] = [];
  const depths = indentDepths(lines, loose, anchors);
  const bodies = inlineBodies(lines);
  const size = Math.max(1, options.tabSize ?? 2);
  const spaces = options.insertSpaces !== false;
  // A line at or right of an inline body's column moves as far as that body.
  const pins: { from: number; to: number; prefix: string; scope?: BodyScope }[] = [];
  const bodyPins = new Map<Token, typeof pins[number]>();
  const formatted = lines.map((line, index) => {
    const { ending } = line;
    if (line.tokens.length === 0 && line.comment === "") return ending;
    for (let at = pins.length - 1; at >= 0; at--) {
      if ((pins[at].scope?.end ?? lines.length) < index) pins.splice(at, 1);
    }
    const width = line.indent.length;
    if (!loose[index]) while (pins.length > 0 && pins[pins.length - 1].from > width) pins.pop();
    const anchor = anchors[index];
    const pin = anchor ? bodyPins.get(anchor) : pins.filter((pin) => pin.from <= width).pop();
    if (anchor && pin && pins.at(-1) !== pin) pins.push(pin);
    const prefix = pin ? pin.prefix + " ".repeat(width - pin.from + pin.to - pin.prefix.length)
      : spaces ? " ".repeat(depths[index] * size) : "\t".repeat(depths[index]);
    const [code, starts] = formatTokens(line.tokens, prefix.length);
    for (const { at, scope } of bodies[index]) {
      const pin = { from: line.tokens[at].col, to: starts[at], prefix: prefix.slice(0, starts[at]), scope };
      pins.push(pin);
      bodyPins.set(line.tokens[at], pin);
    }
    if (code === "") return prefix + line.comment + ending;
    if (line.comment === "") return prefix + code + ending;
    return prefix + code + (gluedPercent(line, line.tokens.length - 1) ? "" : "  ") + line.comment + ending;
  }).join("");
  try {
    if (fingerprint(lines) !== fingerprint(splitLines(formatted))) return source;
  } catch {
    return source;
  }
  return formatted;
}
