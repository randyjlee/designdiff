'use client';

import { motion } from 'framer-motion';
import { Scan, Brain, Sparkles } from 'lucide-react';
import { AnalysisStatus } from '@/types';

interface LoadingStateProps {
  status: AnalysisStatus;
}

const statusConfig = {
  diffing: {
    icon: Scan,
    title: 'Generating Visual Diff',
    description: 'Comparing pixels between your designs...',
    color: 'accent',
  },
  analyzing: {
    icon: Brain,
    title: 'AI Analysis in Progress',
    description: 'Detecting UI changes, components, and specifications...',
    color: 'mint',
  },
  uploading: {
    icon: Sparkles,
    title: 'Uploading Images',
    description: 'Preparing your designs for analysis...',
    color: 'accent',
  },
};

export function LoadingState({ status }: LoadingStateProps) {
  const config = statusConfig[status as keyof typeof statusConfig];
  if (!config) return null;

  const Icon = config.icon;

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.95 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.95 }}
      className="flex flex-col items-center justify-center py-12"
    >
      {/* Animated Icon Container */}
      <div className="relative mb-6">
        {/* Outer ring */}
        <motion.div
          animate={{ rotate: 360 }}
          transition={{ duration: 8, repeat: Infinity, ease: 'linear' }}
          className={`absolute inset-0 rounded-full border-2 border-dashed border-${config.color}/30`}
          style={{ width: 100, height: 100, margin: -10 }}
        />
        
        {/* Middle ring */}
        <motion.div
          animate={{ rotate: -360 }}
          transition={{ duration: 12, repeat: Infinity, ease: 'linear' }}
          className={`absolute inset-0 rounded-full border border-${config.color}/20`}
          style={{ width: 120, height: 120, margin: -20 }}
        />

        {/* Icon container */}
        <motion.div
          animate={{ scale: [1, 1.1, 1] }}
          transition={{ duration: 2, repeat: Infinity, ease: 'easeInOut' }}
          className={`
            relative p-5 rounded-2xl
            ${config.color === 'accent' ? 'bg-gradient-to-br from-accent/20 to-accent-dark/20' : 'bg-gradient-to-br from-mint/20 to-mint-dark/20'}
          `}
        >
          <Icon className={`w-10 h-10 ${config.color === 'accent' ? 'text-accent' : 'text-mint'}`} />
        </motion.div>

        {/* Particles */}
        {[...Array(6)].map((_, i) => (
          <motion.div
            key={i}
            className={`absolute w-2 h-2 rounded-full ${config.color === 'accent' ? 'bg-accent' : 'bg-mint'}`}
            initial={{ opacity: 0, scale: 0 }}
            animate={{
              opacity: [0, 1, 0],
              scale: [0, 1, 0],
              x: [0, Math.cos(i * 60 * Math.PI / 180) * 50],
              y: [0, Math.sin(i * 60 * Math.PI / 180) * 50],
            }}
            transition={{
              duration: 2,
              repeat: Infinity,
              delay: i * 0.3,
              ease: 'easeOut',
            }}
            style={{ left: '50%', top: '50%', marginLeft: -4, marginTop: -4 }}
          />
        ))}
      </div>

      {/* Text */}
      <motion.h3
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        className="text-xl font-semibold text-surface-100 mb-2"
      >
        {config.title}
      </motion.h3>
      
      <motion.p
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
        className="text-surface-400 text-center max-w-sm"
      >
        {config.description}
      </motion.p>

      {/* Progress bar */}
      <motion.div
        initial={{ opacity: 0, width: 0 }}
        animate={{ opacity: 1, width: 200 }}
        transition={{ delay: 0.3 }}
        className="mt-6 h-1 bg-surface-800 rounded-full overflow-hidden"
      >
        <motion.div
          className={`h-full ${config.color === 'accent' ? 'bg-accent' : 'bg-mint'}`}
          initial={{ x: '-100%' }}
          animate={{ x: '100%' }}
          transition={{
            duration: 1.5,
            repeat: Infinity,
            ease: 'easeInOut',
          }}
        />
      </motion.div>
    </motion.div>
  );
}








