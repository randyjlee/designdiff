'use client';

import { useState, useCallback } from 'react';
import { motion } from 'framer-motion';
import {
  ArrowLeft,
  Copy,
  Check,
  Download,
  Slack,
  MessageSquare,
  Code,
  ListTodo,
  FileText,
  RefreshCw,
  ChevronRight,
  Layers,
} from 'lucide-react';
import { AnalysisResult, DiffResult } from '@/types';
import { ImageComparison } from './ImageComparison';

interface ResultsPanelProps {
  diffResult: DiffResult;
  analysisResult: AnalysisResult;
  beforeImage: string;
  afterImage: string;
  onReset: () => void;
}

type Tab = 'summary' | 'spec' | 'tasks' | 'slack' | 'linear';

const tabs: { id: Tab; label: string; icon: typeof FileText }[] = [
  { id: 'summary', label: 'Summary', icon: FileText },
  { id: 'spec', label: 'Dev Spec', icon: Code },
  { id: 'tasks', label: 'Tasks', icon: ListTodo },
  { id: 'slack', label: 'Slack', icon: Slack },
  { id: 'linear', label: 'Linear', icon: MessageSquare },
];

export function ResultsPanel({
  diffResult,
  analysisResult,
  beforeImage,
  afterImage,
  onReset,
}: ResultsPanelProps) {
  const [activeTab, setActiveTab] = useState<Tab>('summary');
  const [copiedState, setCopiedState] = useState<string | null>(null);

  const copyToClipboard = useCallback(async (text: string, id: string) => {
    await navigator.clipboard.writeText(text);
    setCopiedState(id);
    setTimeout(() => setCopiedState(null), 2000);
  }, []);

  const downloadJSON = useCallback(() => {
    const data = JSON.stringify(analysisResult, null, 2);
    const blob = new Blob([data], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'design-diff-analysis.json';
    a.click();
    URL.revokeObjectURL(url);
  }, [analysisResult]);

  const downloadDiffImage = useCallback(() => {
    const a = document.createElement('a');
    a.href = diffResult.diffImageBase64;
    a.download = 'design-diff.png';
    a.click();
  }, [diffResult]);

  const CopyButton = ({ text, id, label }: { text: string; id: string; label?: string }) => (
    <button
      onClick={() => copyToClipboard(text, id)}
      className="copy-btn flex items-center gap-2 px-3 py-1.5 rounded-lg bg-surface-800 hover:bg-surface-700 text-surface-300 hover:text-white text-sm transition-colors"
    >
      {copiedState === id ? (
        <>
          <Check className="w-4 h-4 text-emerald-400" />
          <span className="text-emerald-400">Copied!</span>
        </>
      ) : (
        <>
          <Copy className="w-4 h-4" />
          <span>{label || 'Copy'}</span>
        </>
      )}
    </button>
  );

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-6"
    >
      {/* Header */}
      <div className="flex items-center justify-between">
        <button
          onClick={onReset}
          className="flex items-center gap-2 px-4 py-2 rounded-xl bg-surface-800 hover:bg-surface-700 text-surface-300 hover:text-white transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          <span>New Analysis</span>
        </button>

        <div className="flex items-center gap-3">
          <button
            onClick={downloadDiffImage}
            className="flex items-center gap-2 px-4 py-2 rounded-xl bg-surface-800 hover:bg-surface-700 text-surface-300 hover:text-white transition-colors"
          >
            <Download className="w-4 h-4" />
            <span>Diff PNG</span>
          </button>
          <button
            onClick={downloadJSON}
            className="flex items-center gap-2 px-4 py-2 rounded-xl bg-accent hover:bg-accent-dark text-white transition-colors"
          >
            <Download className="w-4 h-4" />
            <span>Export JSON</span>
          </button>
        </div>
      </div>

      {/* Main Content */}
      <div className="grid lg:grid-cols-2 gap-6">
        {/* Left: Image Comparison */}
        <ImageComparison
          beforeImage={beforeImage}
          afterImage={afterImage}
          diffImage={diffResult.diffImageBase64}
          diffPercentage={diffResult.diffPercentage}
        />

        {/* Right: Analysis Results */}
        <div className="bg-surface-900/50 backdrop-blur-sm rounded-2xl border border-surface-800 overflow-hidden">
          {/* Tabs */}
          <div className="flex border-b border-surface-800 overflow-x-auto">
            {tabs.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`
                  flex items-center gap-2 px-4 py-3 text-sm font-medium whitespace-nowrap
                  transition-colors relative
                  ${activeTab === tab.id
                    ? 'text-accent'
                    : 'text-surface-400 hover:text-surface-200'
                  }
                `}
              >
                <tab.icon className="w-4 h-4" />
                {tab.label}
                {activeTab === tab.id && (
                  <motion.div
                    layoutId="activeTab"
                    className="absolute bottom-0 left-0 right-0 h-0.5 bg-accent"
                  />
                )}
              </button>
            ))}
          </div>

          {/* Tab Content */}
          <div className="p-4 max-h-[500px] overflow-y-auto">
            {activeTab === 'summary' && (
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-semibold text-surface-100">Change Summary</h3>
                  <CopyButton
                    text={analysisResult.changeSummary.map(s => `• ${s}`).join('\n')}
                    id="summary"
                  />
                </div>
                <ul className="space-y-2">
                  {analysisResult.changeSummary.map((change, i) => (
                    <motion.li
                      key={i}
                      initial={{ opacity: 0, x: -10 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: i * 0.05 }}
                      className="flex items-start gap-3 p-3 rounded-xl bg-surface-800/50"
                    >
                      <ChevronRight className="w-4 h-4 text-accent mt-0.5 flex-shrink-0" />
                      <span className="text-surface-200">{change}</span>
                    </motion.li>
                  ))}
                </ul>
              </div>
            )}

            {activeTab === 'spec' && (
              <div className="space-y-6">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-semibold text-surface-100">Developer Spec</h3>
                  <CopyButton
                    text={formatDevSpec(analysisResult.developerSpec)}
                    id="spec"
                  />
                </div>

                {/* Components */}
                {analysisResult.developerSpec.components.map((comp, i) => (
                  <motion.div
                    key={i}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: i * 0.1 }}
                    className="code-block"
                  >
                    <div className="flex items-center gap-2 px-4 py-2 bg-surface-800/50 border-b border-surface-700">
                      <Layers className="w-4 h-4 text-accent" />
                      <span className="font-medium text-surface-200">{comp.name}</span>
                    </div>
                    <div className="p-4 font-mono text-sm space-y-1">
                      {Object.entries(comp.properties).map(([key, value]) => (
                        <div key={key} className="flex">
                          <span className="text-surface-500 w-40">{key}:</span>
                          <span className="text-mint">{value}</span>
                        </div>
                      ))}
                    </div>
                  </motion.div>
                ))}

                {/* Layout */}
                {analysisResult.developerSpec.layout.length > 0 && (
                  <motion.div
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="code-block"
                  >
                    <div className="flex items-center gap-2 px-4 py-2 bg-surface-800/50 border-b border-surface-700">
                      <Code className="w-4 h-4 text-mint" />
                      <span className="font-medium text-surface-200">Layout</span>
                    </div>
                    <div className="p-4 font-mono text-sm space-y-1">
                      {analysisResult.developerSpec.layout.map((item, i) => (
                        <div key={i} className="flex">
                          <span className="text-surface-500 w-40">{item.property}:</span>
                          <span className="text-mint">{item.value}</span>
                        </div>
                      ))}
                    </div>
                  </motion.div>
                )}
              </div>
            )}

            {activeTab === 'tasks' && (
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-semibold text-surface-100">Actionable Tasks</h3>
                  <CopyButton
                    text={analysisResult.actionableTasks.map(t => `- [ ] ${t}`).join('\n')}
                    id="tasks"
                  />
                </div>
                <ul className="space-y-2">
                  {analysisResult.actionableTasks.map((task, i) => (
                    <motion.li
                      key={i}
                      initial={{ opacity: 0, x: -10 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: i * 0.05 }}
                      className="flex items-center gap-3 p-3 rounded-xl bg-surface-800/50"
                    >
                      <div className="w-5 h-5 rounded border-2 border-surface-600 flex-shrink-0" />
                      <span className="text-surface-200">{task}</span>
                    </motion.li>
                  ))}
                </ul>
              </div>
            )}

            {activeTab === 'slack' && (
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Slack className="w-5 h-5 text-[#4A154B]" />
                    <h3 className="text-lg font-semibold text-surface-100">Slack Format</h3>
                  </div>
                  <CopyButton text={analysisResult.slackFormat} id="slack" label="Copy for Slack" />
                </div>
                <div className="code-block p-4 font-mono text-sm whitespace-pre-wrap text-surface-300">
                  {analysisResult.slackFormat}
                </div>
              </div>
            )}

            {activeTab === 'linear' && (
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <MessageSquare className="w-5 h-5 text-[#5E6AD2]" />
                    <h3 className="text-lg font-semibold text-surface-100">Linear Format</h3>
                  </div>
                  <CopyButton text={analysisResult.linearFormat} id="linear" label="Copy for Linear" />
                </div>
                <div className="code-block p-4 font-mono text-sm whitespace-pre-wrap text-surface-300">
                  {analysisResult.linearFormat}
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </motion.div>
  );
}

function formatDevSpec(spec: AnalysisResult['developerSpec']): string {
  let output = '';
  
  spec.components.forEach((comp) => {
    output += `## ${comp.name}\n`;
    Object.entries(comp.properties).forEach(([key, value]) => {
      output += `- ${key}: ${value}\n`;
    });
    output += '\n';
  });

  if (spec.layout.length > 0) {
    output += '## Layout\n';
    spec.layout.forEach((item) => {
      output += `- ${item.property}: ${item.value}\n`;
    });
  }

  return output.trim();
}


















