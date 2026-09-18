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

export function existsSync(p: string): boolean {
  if (normalize(p).startsWith("/packages/")) {
    throw new Error("Hub packages are not available in the playground. Use import Base or paste your definitions into main.bend.");
  }
  return files.has(normalize(p));
}

export function realpathSync(p: string): string {
  if (!existsSync(p)) throw new Error("File not available in the playground: " + p);
  return normalize(p);
}

export function readFileSync(p: string, _encoding: string): string {
  return files.get(realpathSync(p))!;
}

export function writeFileSync(p: string, source: string): void {
  if (p !== "/main.bend") throw new Error("Only main.bend can be edited in the playground.");
  files.set(p, source);
}

export function mkdirSync(): never {
  throw new Error("The playground has no host filesystem.");
}
