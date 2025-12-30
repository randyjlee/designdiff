'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Eye, Layers, GitCompare, ZoomIn, ZoomOut } from 'lucide-react';

interface ImageComparisonProps {
  beforeImage: string;
  afterImage: string;
  diffImage: string;
  diffPercentage: number;
}

type ViewMode = 'before' | 'after' | 'diff' | 'slider';

const viewModes: { id: ViewMode; label: string; icon: typeof Eye }[] = [
  { id: 'before', label: 'Before', icon: Eye },
  { id: 'after', label: 'After', icon: Eye },
  { id: 'diff', label: 'Diff', icon: GitCompare },
  { id: 'slider', label: 'Compare', icon: Layers },
];

export function ImageComparison({
  beforeImage,
  afterImage,
  diffImage,
  diffPercentage,
}: ImageComparisonProps) {
  const [viewMode, setViewMode] = useState<ViewMode>('diff');
  const [sliderPosition, setSliderPosition] = useState(50);
  const [zoom, setZoom] = useState(1);

  const getDisplayImage = () => {
    switch (viewMode) {
      case 'before':
        return beforeImage;
      case 'after':
        return afterImage;
      case 'diff':
        return diffImage;
      default:
        return diffImage;
    }
  };

  return (
    <div className="bg-surface-900/50 backdrop-blur-sm rounded-2xl border border-surface-800 overflow-hidden">
      {/* Header */}
      <div className="flex items-center justify-between p-4 border-b border-surface-800">
        <div className="flex items-center gap-2">
          <GitCompare className="w-5 h-5 text-accent" />
          <span className="font-medium text-surface-200">Visual Comparison</span>
        </div>
        <div className="flex items-center gap-2 text-sm">
          <span className="text-surface-500">Change:</span>
          <span className={`font-mono font-medium ${diffPercentage > 10 ? 'text-rose-400' : diffPercentage > 5 ? 'text-amber-400' : 'text-emerald-400'}`}>
            {diffPercentage.toFixed(2)}%
          </span>
        </div>
      </div>

      {/* View Mode Tabs */}
      <div className="flex border-b border-surface-800">
        {viewModes.map((mode) => (
          <button
            key={mode.id}
            onClick={() => setViewMode(mode.id)}
            className={`
              flex items-center gap-2 px-4 py-2.5 text-sm font-medium
              transition-colors relative flex-1 justify-center
              ${viewMode === mode.id
                ? 'text-accent bg-surface-800/50'
                : 'text-surface-400 hover:text-surface-200 hover:bg-surface-800/30'
              }
            `}
          >
            <mode.icon className="w-4 h-4" />
            {mode.label}
          </button>
        ))}
      </div>

      {/* Image Display */}
      <div className="relative aspect-[4/3] bg-surface-950 overflow-hidden">
        {viewMode === 'slider' ? (
          /* Slider Comparison */
          <div className="absolute inset-0">
            {/* After Image (full) */}
            <img
              src={afterImage}
              alt="After"
              className="absolute inset-0 w-full h-full object-contain"
              style={{ transform: `scale(${zoom})` }}
            />
            
            {/* Before Image (clipped) */}
            <div
              className="absolute inset-0 overflow-hidden"
              style={{ width: `${sliderPosition}%` }}
            >
              <img
                src={beforeImage}
                alt="Before"
                className="absolute inset-0 w-full h-full object-contain"
                style={{
                  transform: `scale(${zoom})`,
                  width: `${100 / (sliderPosition / 100)}%`,
                  maxWidth: 'none',
                }}
              />
            </div>

            {/* Slider Handle */}
            <div
              className="absolute top-0 bottom-0 w-1 bg-accent cursor-ew-resize"
              style={{ left: `${sliderPosition}%` }}
            >
              <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-8 h-8 rounded-full bg-accent flex items-center justify-center shadow-lg">
                <Layers className="w-4 h-4 text-white" />
              </div>
            </div>

            {/* Slider Input (invisible, for dragging) */}
            <input
              type="range"
              min="0"
              max="100"
              value={sliderPosition}
              onChange={(e) => setSliderPosition(Number(e.target.value))}
              className="absolute inset-0 w-full h-full opacity-0 cursor-ew-resize"
            />

            {/* Labels */}
            <div className="absolute top-4 left-4 px-2 py-1 rounded bg-surface-950/80 text-xs text-rose-400 font-medium">
              Before
            </div>
            <div className="absolute top-4 right-4 px-2 py-1 rounded bg-surface-950/80 text-xs text-emerald-400 font-medium">
              After
            </div>
          </div>
        ) : (
          /* Single Image View */
          <motion.img
            key={viewMode}
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.2 }}
            src={getDisplayImage()}
            alt={viewMode}
            className="absolute inset-0 w-full h-full object-contain"
            style={{ transform: `scale(${zoom})` }}
          />
        )}

        {/* Zoom Controls */}
        <div className="absolute bottom-4 right-4 flex items-center gap-2 bg-surface-900/80 backdrop-blur-sm rounded-lg p-1">
          <button
            onClick={() => setZoom(Math.max(0.5, zoom - 0.25))}
            className="p-1.5 rounded hover:bg-surface-700 text-surface-400 hover:text-white transition-colors"
          >
            <ZoomOut className="w-4 h-4" />
          </button>
          <span className="text-xs text-surface-400 w-12 text-center font-mono">
            {Math.round(zoom * 100)}%
          </span>
          <button
            onClick={() => setZoom(Math.min(3, zoom + 0.25))}
            className="p-1.5 rounded hover:bg-surface-700 text-surface-400 hover:text-white transition-colors"
          >
            <ZoomIn className="w-4 h-4" />
          </button>
        </div>

        {/* Diff Legend (when in diff mode) */}
        {viewMode === 'diff' && (
          <div className="absolute bottom-4 left-4 flex items-center gap-4 bg-surface-900/80 backdrop-blur-sm rounded-lg px-3 py-2 text-xs">
            <div className="flex items-center gap-1.5">
              <div className="w-3 h-3 rounded bg-[#ff0000]" />
              <span className="text-surface-400">Changed</span>
            </div>
            <div className="flex items-center gap-1.5">
              <div className="w-3 h-3 rounded bg-[#ffff00]" />
              <span className="text-surface-400">Anti-aliased</span>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}








