export type OffsetRange = { start: number; end: number };

export type AnalysisDiagnostic = {
  uri: string;
  range: OffsetRange;
  message: string;
  code: "parsing" | "checking" | "imports" | "incomplete-law" | "holes";
};

export type AnalysisResult = {
  id: number;
  uri: string;
  version: number;
  versions: Record<string, number>;
  diagnostics: AnalysisDiagnostic[];
  hovers: Record<string, string>;
};

export type Overlay = { uri: string; path: string; version: number; text: string };
export type AnalysisRequest = {
  type: "analyze";
  id: number;
  uri: string;
  path: string;
  version: number;
  text: string;
  overlays: Overlay[];
};
