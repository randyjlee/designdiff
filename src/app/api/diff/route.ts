import { NextRequest, NextResponse } from 'next/server';
import { PNG } from 'pngjs';
import pixelmatch from 'pixelmatch';

interface DiffRequest {
  before: string; // base64 encoded PNG
  after: string; // base64 encoded PNG
}

function base64ToBuffer(base64: string): Buffer {
  // Remove data URL prefix if present
  const base64Data = base64.replace(/^data:image\/\w+;base64,/, '');
  return Buffer.from(base64Data, 'base64');
}

function bufferToBase64(buffer: Buffer): string {
  return `data:image/png;base64,${buffer.toString('base64')}`;
}

async function decodePNG(buffer: Buffer): Promise<PNG> {
  return new Promise((resolve, reject) => {
    const png = new PNG();
    png.parse(buffer, (error, data) => {
      if (error) reject(error);
      else resolve(data);
    });
  });
}

function encodePNG(png: PNG): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    png.pack()
      .on('data', (chunk) => chunks.push(chunk))
      .on('end', () => resolve(Buffer.concat(chunks)))
      .on('error', reject);
  });
}

export async function POST(request: NextRequest) {
  try {
    const body: DiffRequest = await request.json();
    const { before, after } = body;

    if (!before || !after) {
      return NextResponse.json(
        { error: 'Both before and after images are required' },
        { status: 400 }
      );
    }

    // Decode images
    const beforeBuffer = base64ToBuffer(before);
    const afterBuffer = base64ToBuffer(after);

    const beforePNG = await decodePNG(beforeBuffer);
    const afterPNG = await decodePNG(afterBuffer);

    // Ensure images are the same size (use the larger dimensions)
    const width = Math.max(beforePNG.width, afterPNG.width);
    const height = Math.max(beforePNG.height, afterPNG.height);

    // Create canvases with the same size
    const resizedBefore = new PNG({ width, height });
    const resizedAfter = new PNG({ width, height });

    // Fill with white background
    for (let i = 0; i < width * height * 4; i += 4) {
      resizedBefore.data[i] = 255;
      resizedBefore.data[i + 1] = 255;
      resizedBefore.data[i + 2] = 255;
      resizedBefore.data[i + 3] = 255;
      resizedAfter.data[i] = 255;
      resizedAfter.data[i + 1] = 255;
      resizedAfter.data[i + 2] = 255;
      resizedAfter.data[i + 3] = 255;
    }

    // Copy original images onto resized canvases
    for (let y = 0; y < beforePNG.height; y++) {
      for (let x = 0; x < beforePNG.width; x++) {
        const srcIdx = (y * beforePNG.width + x) * 4;
        const dstIdx = (y * width + x) * 4;
        resizedBefore.data[dstIdx] = beforePNG.data[srcIdx];
        resizedBefore.data[dstIdx + 1] = beforePNG.data[srcIdx + 1];
        resizedBefore.data[dstIdx + 2] = beforePNG.data[srcIdx + 2];
        resizedBefore.data[dstIdx + 3] = beforePNG.data[srcIdx + 3];
      }
    }

    for (let y = 0; y < afterPNG.height; y++) {
      for (let x = 0; x < afterPNG.width; x++) {
        const srcIdx = (y * afterPNG.width + x) * 4;
        const dstIdx = (y * width + x) * 4;
        resizedAfter.data[dstIdx] = afterPNG.data[srcIdx];
        resizedAfter.data[dstIdx + 1] = afterPNG.data[srcIdx + 1];
        resizedAfter.data[dstIdx + 2] = afterPNG.data[srcIdx + 2];
        resizedAfter.data[dstIdx + 3] = afterPNG.data[srcIdx + 3];
      }
    }

    // Create diff output
    const diffPNG = new PNG({ width, height });

    // Run pixelmatch
    const changedPixels = pixelmatch(
      resizedBefore.data,
      resizedAfter.data,
      diffPNG.data,
      width,
      height,
      {
        threshold: 0.1,
        includeAA: true,
        diffColor: [255, 0, 0],      // Red for changed
        diffColorAlt: [255, 255, 0], // Yellow for anti-aliased
        alpha: 0.3,                   // Show original with overlay
      }
    );

    // Encode diff image
    const diffBuffer = await encodePNG(diffPNG);
    const diffBase64 = bufferToBase64(diffBuffer);

    const totalPixels = width * height;
    const diffPercentage = (changedPixels / totalPixels) * 100;

    return NextResponse.json({
      diffImageBase64: diffBase64,
      diffPercentage,
      changedPixels,
      totalPixels,
    });
  } catch (error) {
    console.error('Diff generation error:', error);
    return NextResponse.json(
      { error: 'Failed to generate diff' },
      { status: 500 }
    );
  }
}






