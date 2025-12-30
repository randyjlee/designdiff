import Foundation
import AppKit
import CoreImage

class ImageDiffEngine {
    
    enum DiffError: LocalizedError {
        case invalidImage
        case processingFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidImage:
                return "Could not process one or more images"
            case .processingFailed:
                return "Failed to generate diff image"
            }
        }
    }
    
    func generateDiff(before: NSImage, after: NSImage) async throws -> DiffResult {
        // Get bitmap representations
        guard let beforeBitmap = getBitmapRep(from: before),
              let afterBitmap = getBitmapRep(from: after) else {
            throw DiffError.invalidImage
        }
        
        // Determine output size (use larger dimensions)
        let width = max(beforeBitmap.pixelsWide, afterBitmap.pixelsWide)
        let height = max(beforeBitmap.pixelsHigh, afterBitmap.pixelsHigh)
        
        // Create normalized images at the same size
        let normalizedBefore = normalizeImage(beforeBitmap, toWidth: width, height: height)
        let normalizedAfter = normalizeImage(afterBitmap, toWidth: width, height: height)
        
        // Create diff output bitmap
        guard let diffBitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: width * 4,
            bitsPerPixel: 32
        ) else {
            throw DiffError.processingFailed
        }
        
        var changedPixels = 0
        let totalPixels = width * height
        
        // Perform pixel-by-pixel comparison
        for y in 0..<height {
            for x in 0..<width {
                let beforeColor = normalizedBefore.colorAt(x: x, y: y) ?? NSColor.white
                let afterColor = normalizedAfter.colorAt(x: x, y: y) ?? NSColor.white
                
                let isDifferent = !colorsAreSimilar(beforeColor, afterColor, threshold: 0.05)
                
                if isDifferent {
                    changedPixels += 1
                    // Highlight changed pixels with red overlay
                    let blendedColor = blendWithHighlight(afterColor, highlightColor: NSColor(red: 1, green: 0, blue: 0, alpha: 0.6))
                    diffBitmap.setColor(blendedColor, atX: x, y: y)
                } else {
                    // Keep original but slightly dimmed
                    let dimmedColor = dimColor(afterColor, amount: 0.3)
                    diffBitmap.setColor(dimmedColor, atX: x, y: y)
                }
            }
        }
        
        let diffImage = NSImage(size: NSSize(width: width, height: height))
        diffImage.addRepresentation(diffBitmap)
        
        let diffPercentage = Double(changedPixels) / Double(totalPixels) * 100
        
        return DiffResult(
            diffImage: diffImage,
            diffPercentage: diffPercentage,
            changedPixels: changedPixels,
            totalPixels: totalPixels
        )
    }
    
    // MARK: - Helper Methods
    
    private func getBitmapRep(from image: NSImage) -> NSBitmapImageRep? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap
    }
    
    private func normalizeImage(_ bitmap: NSBitmapImageRep, toWidth width: Int, height: Int) -> NSBitmapImageRep {
        // If already correct size, return as is
        if bitmap.pixelsWide == width && bitmap.pixelsHigh == height {
            return bitmap
        }
        
        // Create new bitmap at target size with white background
        guard let newBitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: width * 4,
            bitsPerPixel: 32
        ) else {
            return bitmap
        }
        
        // Fill with white
        for y in 0..<height {
            for x in 0..<width {
                newBitmap.setColor(.white, atX: x, y: y)
            }
        }
        
        // Copy original image
        for y in 0..<bitmap.pixelsHigh {
            for x in 0..<bitmap.pixelsWide {
                if let color = bitmap.colorAt(x: x, y: y) {
                    newBitmap.setColor(color, atX: x, y: y)
                }
            }
        }
        
        return newBitmap
    }
    
    private func colorsAreSimilar(_ c1: NSColor, _ c2: NSColor, threshold: CGFloat) -> Bool {
        guard let rgb1 = c1.usingColorSpace(.deviceRGB),
              let rgb2 = c2.usingColorSpace(.deviceRGB) else {
            return false
        }
        
        let dr = abs(rgb1.redComponent - rgb2.redComponent)
        let dg = abs(rgb1.greenComponent - rgb2.greenComponent)
        let db = abs(rgb1.blueComponent - rgb2.blueComponent)
        let da = abs(rgb1.alphaComponent - rgb2.alphaComponent)
        
        return dr <= threshold && dg <= threshold && db <= threshold && da <= threshold
    }
    
    private func blendWithHighlight(_ color: NSColor, highlightColor: NSColor) -> NSColor {
        guard let rgb = color.usingColorSpace(.deviceRGB),
              let highlight = highlightColor.usingColorSpace(.deviceRGB) else {
            return color
        }
        
        let alpha = highlight.alphaComponent
        let r = rgb.redComponent * (1 - alpha) + highlight.redComponent * alpha
        let g = rgb.greenComponent * (1 - alpha) + highlight.greenComponent * alpha
        let b = rgb.blueComponent * (1 - alpha) + highlight.blueComponent * alpha
        
        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }
    
    private func dimColor(_ color: NSColor, amount: CGFloat) -> NSColor {
        guard let rgb = color.usingColorSpace(.deviceRGB) else {
            return color
        }
        
        let factor = 1 - amount
        return NSColor(
            red: rgb.redComponent * factor + amount,
            green: rgb.greenComponent * factor + amount,
            blue: rgb.blueComponent * factor + amount,
            alpha: rgb.alphaComponent
        )
    }
}








