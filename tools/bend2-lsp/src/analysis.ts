import { Worker } from "node:worker_threads";
import type { AnalysisRequest, AnalysisResult } from "./protocol.js";

type Pending = { resolve: (result: AnalysisResult) => void; reject: (error: Error) => void };

export class Analyzer {
  private worker!: Worker;
  private pending = new Map<number, Pending>();
  private nextId = 1;
  private stopping = false;

  constructor() { this.spawn(); }

  private spawn(): void {
    this.worker = new Worker(new URL("./analysis-worker.js", import.meta.url));
    this.worker.on("message", (result: AnalysisResult) => {
      const pending = this.pending.get(result.id);
      if (!pending) return;
      this.pending.delete(result.id);
      pending.resolve(result);
    });
    const fail = (cause: unknown) => {
      if (this.stopping) return;
      const error = cause instanceof Error ? cause : new Error(`analysis worker exited (${String(cause)})`);
      const pending = [...this.pending.values()];
      this.pending.clear();
      for (const request of pending) request.reject(error);
    };
    this.worker.on("error", fail);
    this.worker.on("exit", (code) => { if (code !== 0) fail(code); });
  }

  private request(input: Omit<AnalysisRequest, "id">): Promise<AnalysisResult> {
    if (this.worker.threadId === -1) this.spawn();
    const id = this.nextId++;
    return new Promise((resolve, reject) => {
      this.pending.set(id, { resolve, reject });
      this.worker.postMessage({ ...input, id });
    });
  }

  async analyze(input: Omit<AnalysisRequest, "id">): Promise<AnalysisResult> {
    try {
      return await this.request(input);
    } catch {
      await this.worker.terminate().catch(() => undefined);
      this.spawn();
      return this.request(input);
    }
  }

  async close(): Promise<void> {
    this.stopping = true;
    await this.worker.terminate();
  }
}
