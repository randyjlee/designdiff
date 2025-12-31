'use client';

import { useCallback, useState, useRef } from 'react';
import { motion } from 'framer-motion';
import { Upload, Image as ImageIcon, X, ArrowRight, ArrowLeft } from 'lucide-react';

interface ImageUploaderProps {
  type: 'before' | 'after';
  image: string | null;
  onUpload: (base64: string) => void;
  disabled?: boolean;
}

export function ImageUploader({ type, image, onUpload, disabled }: ImageUploaderProps) {
  const [isDragging, setIsDragging] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFile = useCallback((file: File) => {
    if (!file.type.startsWith('image/png')) {
      alert('Please upload a PNG image');
      return;
    }

    const reader = new FileReader();
    reader.onload = (e) => {
      const base64 = e.target?.result as string;
      onUpload(base64);
    };
    reader.readAsDataURL(file);
  }, [onUpload]);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    if (disabled) return;

    const file = e.dataTransfer.files[0];
    if (file) handleFile(file);
  }, [handleFile, disabled]);

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    if (!disabled) setIsDragging(true);
  }, [disabled]);

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
  }, []);

  const handleClick = useCallback(() => {
    if (!disabled) fileInputRef.current?.click();
  }, [disabled]);

  const handleInputChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) handleFile(file);
  }, [handleFile]);

  const handleRemove = useCallback((e: React.MouseEvent) => {
    e.stopPropagation();
    onUpload('');
  }, [onUpload]);

  const isBefore = type === 'before';
  const Icon = isBefore ? ArrowLeft : ArrowRight;
  const label = isBefore ? 'Before' : 'After';
  const accentColor = isBefore ? 'rose' : 'emerald';

  return (
    <motion.div
      initial={{ opacity: 0, x: isBefore ? -20 : 20 }}
      animate={{ opacity: 1, x: 0 }}
      transition={{ duration: 0.5 }}
      className="relative"
    >
      {/* Label */}
      <div className="flex items-center gap-2 mb-3">
        <div className={`p-1.5 rounded-lg ${isBefore ? 'bg-rose-500/20' : 'bg-emerald-500/20'}`}>
          <Icon className={`w-4 h-4 ${isBefore ? 'text-rose-400' : 'text-emerald-400'}`} />
        </div>
        <span className="font-medium text-surface-200">{label} Design</span>
        {image && (
          <span className="text-xs text-surface-500 ml-auto">Click to replace</span>
        )}
      </div>

      {/* Drop Zone */}
      <div
        onClick={handleClick}
        onDrop={handleDrop}
        onDragOver={handleDragOver}
        onDragLeave={handleDragLeave}
        className={`
          drop-zone relative overflow-hidden rounded-2xl border-2 border-dashed
          aspect-[4/3] cursor-pointer group
          ${isDragging ? 'dragging' : ''}
          ${disabled ? 'opacity-50 cursor-not-allowed' : ''}
          ${image
            ? 'border-surface-700 bg-surface-900'
            : isBefore
              ? 'border-rose-500/30 bg-rose-500/5 hover:border-rose-500/50 hover:bg-rose-500/10'
              : 'border-emerald-500/30 bg-emerald-500/5 hover:border-emerald-500/50 hover:bg-emerald-500/10'
          }
        `}
      >
        <input
          ref={fileInputRef}
          type="file"
          accept="image/png"
          onChange={handleInputChange}
          className="hidden"
          disabled={disabled}
        />

        {image ? (
          <>
            {/* Image Preview */}
            <img
              src={image}
              alt={`${type} design`}
              className="absolute inset-0 w-full h-full object-contain p-4"
            />
            
            {/* Remove Button */}
            <button
              onClick={handleRemove}
              className="absolute top-3 right-3 p-2 rounded-full bg-surface-900/80 hover:bg-red-500/80 text-surface-400 hover:text-white transition-all opacity-0 group-hover:opacity-100"
            >
              <X className="w-4 h-4" />
            </button>

            {/* Overlay on hover */}
            <div className="absolute inset-0 bg-surface-950/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
              <div className="flex items-center gap-2 text-surface-200">
                <Upload className="w-5 h-5" />
                <span>Replace Image</span>
              </div>
            </div>
          </>
        ) : (
          /* Empty State */
          <div className="absolute inset-0 flex flex-col items-center justify-center p-6 text-center">
            <div className={`
              p-4 rounded-2xl mb-4 transition-transform group-hover:scale-110
              ${isBefore ? 'bg-rose-500/10' : 'bg-emerald-500/10'}
            `}>
              <ImageIcon className={`w-8 h-8 ${isBefore ? 'text-rose-400' : 'text-emerald-400'}`} />
            </div>
            <p className="text-surface-300 font-medium mb-1">
              Drop {label.toLowerCase()} design here
            </p>
            <p className="text-surface-500 text-sm">
              or click to browse
            </p>
            <p className="text-surface-600 text-xs mt-3">
              PNG only
            </p>
          </div>
        )}
      </div>
    </motion.div>
  );
}


















