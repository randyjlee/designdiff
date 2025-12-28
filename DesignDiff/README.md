# DesignDiff for macOS

AI-powered visual design diff tool for seamless designer-developer handoff. Native macOS app built with SwiftUI.

## Features

- **Visual Diff Generation** - Pixel-level comparison highlighting exactly what changed
- **AI-Powered Analysis** - GPT-4 Vision analyzes before/after designs to infer UI specifications
- **Developer-Ready Specs** - Get precise measurements, colors, typography, and spacing values
- **Team-Ready Formats** - One-click copy for Slack and Linear
- **Zero Setup** - Just drag and drop PNG images
- **Native macOS Experience** - Beautiful dark theme with smooth animations

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- OpenAI API key (optional - app works with demo data without it)

## Getting Started

1. Open `DesignDiff.xcodeproj` in Xcode
2. Build and run the project (⌘R)
3. (Optional) Add your OpenAI API key in Settings (⌘,)

## Usage

1. **Upload Images**
   - Drag & drop or click to upload before/after PNG images
   - Works best with UI screenshots at similar sizes

2. **Analyze**
   - Click "Analyze Changes" to generate visual diff and AI analysis
   - View diff with slider comparison, before/after toggle

3. **Export**
   - Copy formatted text for Slack or Linear
   - Export diff PNG or full JSON report
   - View developer specs with exact measurements

## Project Structure

```
DesignDiff/
├── DesignDiffApp.swift      # App entry point
├── ContentView.swift        # Main UI with upload/results flow
├── Models/
│   ├── Models.swift         # Data models for analysis results
│   └── AppState.swift       # App state management
├── Views/
│   ├── ImageDropZone.swift  # Drag & drop upload component
│   ├── ImageComparisonView.swift  # Before/after/diff viewer
│   ├── ResultsView.swift    # Tabbed results panel
│   └── SettingsView.swift   # API key configuration
└── Services/
    ├── ImageDiffEngine.swift  # Pixel-level diff generation
    └── OpenAIService.swift    # GPT-4 Vision API integration
```

## Output Formats

### Change Summary
High-level bullet points for PMs and stakeholders

### Developer Spec
Implementation-ready specifications with exact values:
- Component properties (height, padding, colors, etc.)
- Layout specifications (spacing, gaps)

### Actionable Tasks
Ready-to-import task list for project management

### Slack/Linear Formats
Pre-formatted messages with proper markdown

## Demo Mode

Without an OpenAI API key, the app uses mock data to demonstrate all features. This is great for testing the UI and understanding the output format.

## Privacy

- All image processing happens locally on your Mac
- Images are only sent to OpenAI if you provide an API key
- No data is stored or shared beyond the API call

## License

MIT




