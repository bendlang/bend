import { FILES } from "./assets.ts";

// The small Node surface used by the unmodified compiler, backed by memory.
const files = new Map(Object.entries(FILES));

export function normalize(p: string): string {
  const absolute = p.startsWith("/");
  const parts: string[] = [];
  for (const part of p.split("/")) {
    if (!part || part === ".") continue;
    if (part === ".." && parts.length && parts[parts.length - 1] !== "..") parts.pop();
    else if (part !== ".." || !absolute) parts.push(part);
  }
  return (absolute ? "/" : "") + parts.join("/") || ".";
}

export function join(...parts: string[]): string {
  return normalize(parts.filter(Boolean).join("/"));
}

export function resolve(...parts: string[]): string {
  let result = "/";
  for (const p of parts) result = p.startsWith("/") ? p : result + "/" + p;
  return normalize(result);
}

export function dirname(p: string): string {
  p = normalize(p);
  const at = p.lastIndexOf("/");
  return at < 0 ? "." : at === 0 ? "/" : p.slice(0, at);
}

export const posix = { normalize, join, dirname };
export const homedir = () => "/";
export const fileURLToPath = (u: URL | string) => decodeURIComponent(new URL(u).pathname);

// The bundle derives base.bend from worker.js's URL (bend.ts:982), so a
// subpath host yields /play-dist/base.bend or /bbend/playground/base.bend.
// Canon maps any such path back to the in-memory /base.bend and /effs/*.
function canon(p: string): string {
  const n = normalize(p);
  if (n === "/main.bend") return n;
  if (n === "/base.bend" || n.endsWith("/base.bend")) return "/base.bend";
  const at = n.lastIndexOf("/effs/");
  if (at >= 0) return "/effs/" + n.slice(at + 6);
  return n;
}

export function existsSync(p: string): boolean {
  if (normalize(p).startsWith("/packages/")) {
    throw new Error("Hub packages are not available in the playground. Use import Base or paste your definitions into main.bend.");
  }
  return files.has(canon(p));
}

export function realpathSync(p: string): string {
  if (!existsSync(p)) throw new Error("File not available in the playground: " + p);
  return canon(p);
}

export function readFileSync(p: string, _encoding: string): string {
  return files.get(realpathSync(p))!;
}

export function writeFileSync(p: string, source: string): void {
  const n = normalize(p);
  if (n !== "/main.bend" && !/^\/[A-Za-z0-9_]+\.bend$/.test(n)) {
    throw new Error("Only main.bend and root-level .bend helpers can be edited in the playground.");
  }
  files.set(n, source);
}

export function mkdirSync(): never {
  throw new Error("The playground has no host filesystem.");
}
