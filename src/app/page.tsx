'use client';

import { useState, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Layers, Sparkles } from 'lucide-react';
import { ImageUploader } from '@/components/ImageUploader';
import { ResultsPanel } from '@/components/ResultsPanel';
import { LoadingState } from '@/components/LoadingState';
import { AnalysisResult, DiffResult, UploadedImages, AnalysisStatus } from '@/types';

export default function Home() {
  const [images, setImages] = useState<UploadedImages>({ before: null, after: null });
  const [status, setStatus] = useState<AnalysisStatus>('idle');
  const [diffResult, setDiffResult] = useState<DiffResult | null>(null);
  const [analysisResult, setAnalysisResult] = useState<AnalysisResult | null>(null);
  const [error, setError] = useState<string | null>(null);

  const handleImageUpload = useCallback((type: 'before' | 'after', base64: string) => {
    setImages(prev => ({ ...prev, [type]: base64 }));
    setError(null);
    setAnalysisResult(null);
    setDiffResult(null);
    setStatus('idle');
  }, []);

  const handleAnalyze = useCallback(async () => {
    if (!images.before || !images.after) {
      setError('Please upload both before and after images');
      return;
    }

    setError(null);
    setStatus('diffing');

    try {
      // Step 1: Generate visual diff
      const diffResponse = await fetch('/api/diff', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          before: images.before,
          after: images.after,
        }),
      });

      if (!diffResponse.ok) {
        throw new Error('Failed to generate diff');
      }

      const diffData: DiffResult = await diffResponse.json();
      setDiffResult(diffData);
      setStatus('analyzing');

      // Step 2: AI Analysis
      const analysisResponse = await fetch('/api/analyze', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          before: images.before,
          after: images.after,
          diff: diffData.diffImageBase64,
        }),
      });

      if (!analysisResponse.ok) {
        throw new Error('Failed to analyze images');
      }

      const analysisData: AnalysisResult = await analysisResponse.json();
      setAnalysisResult(analysisData);
      setStatus('complete');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred');
      setStatus('error');
    }
  }, [images]);

  const handleReset = useCallback(() => {
    setImages({ before: null, after: null });
    setDiffResult(null);
    setAnalysisResult(null);
    setStatus('idle');
    setError(null);
  }, []);

  const isReadyToAnalyze = images.before && images.after && status === 'idle';
  const isProcessing = status === 'diffing' || status === 'analyzing';

  return (
    <main className="min-h-screen relative overflow-hidden">
      {/* Background gradients */}
      <div className="gradient-orb w-[600px] h-[600px] bg-accent/30 -top-48 -left-48" />
      <div className="gradient-orb w-[500px] h-[500px] bg-mint/20 top-1/2 -right-32" />
      <div className="gradient-orb w-[400px] h-[400px] bg-purple-500/20 bottom-0 left-1/3" />

      <div className="relative z-10 container mx-auto px-4 py-8 max-w-7xl">
        {/* Header */}
        <motion.header
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center mb-12"
        >
          <div className="flex items-center justify-center gap-3 mb-4">
            <div className="p-3 rounded-2xl bg-gradient-to-br from-accent to-accent-dark">
              <Layers className="w-8 h-8 text-white" />
            </div>
            <h1 className="text-4xl md:text-5xl font-bold tracking-tight">
              Design<span className="text-accent">Diff</span>
            </h1>
          </div>
          <p className="text-surface-400 text-lg max-w-xl mx-auto">
            Upload before & after designs. Get AI-powered change detection, 
            developer specs, and team-ready summaries.
          </p>
        </motion.header>

        <AnimatePresence mode="wait">
          {status === 'complete' && analysisResult && diffResult ? (
            <ResultsPanel
              key="results"
              diffResult={diffResult}
              analysisResult={analysisResult}
              beforeImage={images.before!}
              afterImage={images.after!}
              onReset={handleReset}
            />
          ) : (
            <motion.div
              key="upload"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              className="space-y-8"
            >
              {/* Upload Section */}
              <div className="grid md:grid-cols-2 gap-6">
                <ImageUploader
                  type="before"
                  image={images.before}
                  onUpload={(base64) => handleImageUpload('before', base64)}
                  disabled={isProcessing}
                />
                <ImageUploader
                  type="after"
                  image={images.after}
                  onUpload={(base64) => handleImageUpload('after', base64)}
                  disabled={isProcessing}
                />
              </div>

              {/* Error Display */}
              {error && (
                <motion.div
                  initial={{ opacity: 0, scale: 0.95 }}
                  animate={{ opacity: 1, scale: 1 }}
                  className="p-4 rounded-xl bg-red-500/10 border border-red-500/20 text-red-400 text-center"
                >
                  {error}
                </motion.div>
              )}

              {/* Analyze Button or Loading State */}
              {isProcessing ? (
                <LoadingState status={status} />
              ) : (
                <motion.div
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.2 }}
                  className="flex justify-center"
                >
                  <button
                    onClick={handleAnalyze}
                    disabled={!isReadyToAnalyze}
                    className={`
                      group relative px-8 py-4 rounded-2xl font-semibold text-lg
                      transition-all duration-300 ease-out
                      ${isReadyToAnalyze
                        ? 'bg-gradient-to-r from-accent to-accent-dark text-white shadow-lg shadow-accent/25 hover:shadow-xl hover:shadow-accent/30 hover:scale-[1.02]'
                        : 'bg-surface-800 text-surface-500 cursor-not-allowed'
                      }
                    `}
                  >
                    <span className="flex items-center gap-2">
                      <Sparkles className={`w-5 h-5 ${isReadyToAnalyze ? 'animate-pulse-slow' : ''}`} />
                      Analyze Changes
                    </span>
                    {isReadyToAnalyze && (
                      <div className="absolute inset-0 rounded-2xl bg-white/10 opacity-0 group-hover:opacity-100 transition-opacity" />
                    )}
                  </button>
                </motion.div>
              )}

              {/* Instructions */}
              {!images.before && !images.after && (
                <motion.div
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.4 }}
                  className="text-center text-surface-500 text-sm"
                >
                  <p>Drag & drop or click to upload PNG images</p>
                  <p className="mt-1 text-surface-600">
                    Works best with UI screenshots at similar sizes
                  </p>
                </motion.div>
              )}
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </main>
  );
}

















