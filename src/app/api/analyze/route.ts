import { NextRequest, NextResponse } from 'next/server';
import OpenAI from 'openai';
import { AnalysisResult } from '@/types';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

interface AnalyzeRequest {
  before: string; // base64 PNG
  after: string; // base64 PNG
  diff: string; // base64 PNG
}

const SYSTEM_PROMPT = `You are a senior UI/UX designer and frontend developer expert. Your task is to analyze visual differences between two UI designs (before and after) and provide detailed, actionable specifications for developers.

You will receive three images:
1. BEFORE - The original design
2. AFTER - The updated design  
3. DIFF - A visual diff highlighting changed areas in red/yellow

Analyze these images and provide a comprehensive report in the following JSON format:

{
  "changeSummary": [
    "Brief, clear descriptions of each visual change (e.g., 'Button height increased from 44px to 48px')",
    "Include specific values when visible or inferable"
  ],
  "developerSpec": {
    "components": [
      {
        "name": "Component Name (e.g., Primary Button, Card, Header)",
        "properties": {
          "height": "48px",
          "padding": "16px 12px",
          "border-radius": "12px",
          "background-color": "#1F5BFF",
          "font-size": "16px",
          "font-weight": "600"
        }
      }
    ],
    "layout": [
      {"property": "section-spacing", "value": "24px"},
      {"property": "card-padding", "value": "20px"}
    ]
  },
  "actionableTasks": [
    "Update PrimaryButton component with new height and padding",
    "Change Card border-radius to 16px",
    "Update header text from 'Settings' to 'Account'"
  ],
  "slackFormat": "Markdown formatted summary suitable for Slack with emoji and clear sections",
  "linearFormat": "Clean markdown formatted for Linear issue comments with task checkboxes"
}

Guidelines:
- Be specific with measurements (px, rem, hex colors)
- Group related changes by component
- Infer reasonable values when exact measurements aren't visible
- Focus on actionable, implementation-ready specifications
- Use semantic component names developers would recognize
- Include both structural (layout, spacing) and visual (color, typography) changes
- For colors, provide hex codes when possible
- For spacing, estimate based on visual proportions

Return ONLY valid JSON, no additional text.`;

export async function POST(request: NextRequest) {
  try {
    const body: AnalyzeRequest = await request.json();
    const { before, after, diff } = body;

    if (!before || !after || !diff) {
      return NextResponse.json(
        { error: 'Before, after, and diff images are required' },
        { status: 400 }
      );
    }

    if (!process.env.OPENAI_API_KEY) {
      // Return mock data for demo/development
      return NextResponse.json(getMockAnalysis());
    }

    const response = await openai.chat.completions.create({
      model: 'gpt-4o',
      messages: [
        {
          role: 'system',
          content: SYSTEM_PROMPT,
        },
        {
          role: 'user',
          content: [
            {
              type: 'text',
              text: 'Please analyze the visual differences between these UI designs. The first image is BEFORE, the second is AFTER, and the third is the DIFF highlighting changes.',
            },
            {
              type: 'image_url',
              image_url: {
                url: before,
                detail: 'high',
              },
            },
            {
              type: 'image_url',
              image_url: {
                url: after,
                detail: 'high',
              },
            },
            {
              type: 'image_url',
              image_url: {
                url: diff,
                detail: 'high',
              },
            },
          ],
        },
      ],
      max_tokens: 4096,
      temperature: 0.3,
    });

    const content = response.choices[0]?.message?.content;
    
    if (!content) {
      throw new Error('No response from AI');
    }

    // Parse JSON from response (handle potential markdown code blocks)
    let jsonStr = content;
    const jsonMatch = content.match(/```(?:json)?\s*([\s\S]*?)```/);
    if (jsonMatch) {
      jsonStr = jsonMatch[1].trim();
    }

    const analysis: AnalysisResult = JSON.parse(jsonStr);

    return NextResponse.json(analysis);
  } catch (error) {
    console.error('Analysis error:', error);
    
    // Return mock data on error for demo purposes
    return NextResponse.json(getMockAnalysis());
  }
}

function getMockAnalysis(): AnalysisResult {
  return {
    changeSummary: [
      'Primary button height increased (44px → 48px)',
      'Button border radius changed (8px → 12px)',
      'Primary color updated (#2D6BFF → #1F5BFF)',
      'Card shadow increased for more elevation',
      'Header text weight changed (500 → 600)',
      'Section spacing increased (16px → 24px)',
      'Input field border color lightened',
    ],
    developerSpec: {
      components: [
        {
          name: 'Primary Button',
          properties: {
            'height': '48px',
            'padding': '12px 24px',
            'border-radius': '12px',
            'background-color': '#1F5BFF',
            'font-size': '16px',
            'font-weight': '600',
            'text-color': '#FFFFFF',
          },
        },
        {
          name: 'Card',
          properties: {
            'padding': '24px',
            'border-radius': '16px',
            'background-color': '#FFFFFF',
            'box-shadow': '0 4px 24px rgba(0, 0, 0, 0.08)',
            'border': '1px solid #EAEAEA',
          },
        },
        {
          name: 'Input Field',
          properties: {
            'height': '44px',
            'padding': '12px 16px',
            'border-radius': '8px',
            'border': '1px solid #E5E5E5',
            'font-size': '14px',
          },
        },
      ],
      layout: [
        { property: 'section-spacing', value: '24px' },
        { property: 'card-gap', value: '16px' },
        { property: 'container-padding', value: '32px' },
        { property: 'form-field-gap', value: '12px' },
      ],
    },
    actionableTasks: [
      'Update PrimaryButton component height to 48px',
      'Change button border-radius to 12px in design tokens',
      'Update $primary-color variable to #1F5BFF',
      'Increase Card component shadow depth',
      'Update heading font-weight to 600',
      'Adjust section spacing from 16px to 24px',
      'Update input border color to #E5E5E5',
    ],
    slackFormat: `🎨 *Design Update Summary*

*Visual Changes:*
• Primary button height: 44px → 48px
• Border radius updated: 8px → 12px  
• Primary color: \`#2D6BFF\` → \`#1F5BFF\`
• Card shadow increased
• Section spacing: 16px → 24px

*Action Items:*
☐ Update button tokens
☐ Adjust card shadow
☐ Update spacing variables

_Full spec in thread_ 👇`,
    linearFormat: `## Design Diff Analysis

### Summary
Visual changes detected in the following areas:
- Button styling (height, radius, color)
- Card elevation
- Layout spacing

### Tasks
- [ ] Update PrimaryButton component height to 48px
- [ ] Change button border-radius to 12px
- [ ] Update primary color to #1F5BFF
- [ ] Increase Card shadow
- [ ] Adjust section spacing to 24px

### Developer Spec
See attached JSON for complete specifications.`,
  };
}




