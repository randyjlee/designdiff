# DesignDiff

AI-powered visual design diff tool for seamless designer-developer handoff.

![DesignDiff Preview](preview.png)

## Features

- **Visual Diff Generation** - Pixel-level comparison highlighting exactly what changed
- **AI-Powered Analysis** - GPT-4 Vision analyzes before/after designs to infer UI specifications
- **Developer-Ready Specs** - Get precise measurements, colors, typography, and spacing values
- **Team-Ready Formats** - One-click copy for Slack and Linear
- **Zero Setup** - Just drag and drop PNG images

## Quick Start

### Prerequisites

- Node.js 18+
- OpenAI API key (for AI analysis)

### Installation

```bash
# Clone and install
npm install

# Set up environment
cp .env.local.example .env.local
# Add your OpenAI API key to .env.local

# Run development server
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

### Environment Variables

Create a `.env.local` file with:

```
OPENAI_API_KEY=sk-your-api-key-here
```

Get your API key at [platform.openai.com/api-keys](https://platform.openai.com/api-keys)

> **Note**: Without an API key, the app will use mock data for demonstration.

## How It Works

1. **Upload** - Drag & drop or click to upload before/after PNG images
2. **Diff** - Pixel-level comparison generates a visual diff image
3. **Analyze** - GPT-4 Vision analyzes all three images
4. **Export** - Get formatted specs for developers, Slack, or Linear

## Output Formats

### Change Summary
High-level bullet points for PMs and stakeholders:
- Button height increased (44px → 48px)
- Primary color changed (#2D6BFF → #1F5BFF)
- Card border radius increased (12px → 16px)

### Developer Spec
Implementation-ready specifications:

```
Component: Primary Button
├─ height: 48px
├─ padding: 12px 24px
├─ border-radius: 12px
├─ background-color: #1F5BFF
├─ font-size: 16px
└─ font-weight: 600
```

### Actionable Tasks
Ready-to-import task list:
- [ ] Update PrimaryButton component tokens
- [ ] Adjust Card radius to 16px
- [ ] Update header copy

### Slack/Linear Formats
Pre-formatted messages with proper markdown and emoji for quick sharing.

## Tech Stack

- **Next.js 14** - React framework with App Router
- **Tailwind CSS** - Utility-first styling
- **Framer Motion** - Smooth animations
- **OpenAI GPT-4 Vision** - Multimodal AI analysis
- **Pixelmatch** - Pixel-level image comparison
- **pngjs** - PNG encoding/decoding

## Limitations

- PNG images only (no Figma, Sketch, or design file imports)
- Best-effort inference (not pixel-perfect)
- Requires similar image dimensions for best results
- AI analysis may estimate values

## License

MIT


















