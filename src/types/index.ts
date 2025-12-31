export interface ComponentSpec {
  name: string;
  properties: Record<string, string>;
}

export interface LayoutSpec {
  property: string;
  value: string;
}

export interface AnalysisResult {
  changeSummary: string[];
  developerSpec: {
    components: ComponentSpec[];
    layout: LayoutSpec[];
  };
  actionableTasks: string[];
  slackFormat: string;
  linearFormat: string;
}

export interface DiffResult {
  diffImageBase64: string;
  diffPercentage: number;
  changedPixels: number;
  totalPixels: number;
}

export interface UploadedImages {
  before: string | null;
  after: string | null;
}

export type AnalysisStatus = 'idle' | 'uploading' | 'diffing' | 'analyzing' | 'complete' | 'error';




















