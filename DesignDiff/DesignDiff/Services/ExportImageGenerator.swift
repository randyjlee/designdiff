import AppKit
import SwiftUI

class ExportImageGenerator {
    let beforeImage: NSImage
    let afterImage: NSImage
    let annotations: [EditableAnnotation]
    let diffPercentage: Double
    
    // Layout constants
    private let exportWidth: CGFloat = 1600
    private let padding: CGFloat = 40
    private let imageSpacing: CGFloat = 30
    private let sectionSpacing: CGFloat = 40
    private let backgroundColor = NSColor(red: 0.04, green: 0.04, blue: 0.043, alpha: 1.0)
    private let accentColor = NSColor(red: 1.0, green: 0.42, blue: 0.21, alpha: 1.0)
    
    init(beforeImage: NSImage, afterImage: NSImage, annotations: [EditableAnnotation], diffPercentage: Double) {
        self.beforeImage = beforeImage
        self.afterImage = afterImage
        self.annotations = annotations
        self.diffPercentage = diffPercentage
    }
    
    func generateExportImage() -> NSImage? {
        // Calculate dimensions
        let imageAreaWidth = (exportWidth - padding * 2 - imageSpacing) / 2
        let imageHeight = calculateImageHeight(for: imageAreaWidth)
        
        // Calculate changes section height
        let changesHeight = calculateChangesHeight()
        
        // Total height
        let headerHeight: CGFloat = 60
        let footerHeight: CGFloat = 50
        let totalHeight = padding + headerHeight + imageHeight + sectionSpacing + changesHeight + footerHeight + padding
        
        // 3x scale for high quality
        let scale: CGFloat = 3.0
        let size = NSSize(width: exportWidth, height: totalHeight)
        let scaledSize = NSSize(width: exportWidth * scale, height: totalHeight * scale)
        
        // Create high-resolution bitmap
        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(scaledSize.width),
            pixelsHigh: Int(scaledSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }
        
        let image = NSImage(size: size)
        image.addRepresentation(bitmapRep)
        
        // Set up graphics context with scale
        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: bitmapRep)
        NSGraphicsContext.current = context
        
        // Apply scale transform
        context?.cgContext.scaleBy(x: scale, y: scale)
        
        // Draw background
        backgroundColor.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        var currentY = totalHeight - padding
        
        // Draw header
        currentY = drawHeader(at: currentY)
        
        // Draw images
        currentY -= 20
        drawImages(at: currentY, imageWidth: imageAreaWidth, imageHeight: imageHeight)
        currentY -= imageHeight + sectionSpacing
        
        // Draw changes section
        drawChangesSection(at: currentY)
        
        // Draw footer with logo
        drawFooter()
        
        NSGraphicsContext.restoreGraphicsState()
        
        return image
    }
    
    private func calculateImageHeight(for width: CGFloat) -> CGFloat {
        let aspectRatio = beforeImage.size.height / beforeImage.size.width
        return min(width * aspectRatio, 600)
    }
    
    private func calculateChangesHeight() -> CGFloat {
        let titleHeight: CGFloat = 30
        let itemHeight: CGFloat = 35
        let itemSpacing: CGFloat = 10
        return titleHeight + CGFloat(annotations.count) * (itemHeight + itemSpacing) + 20
    }
    
    private func drawHeader(at y: CGFloat) -> CGFloat {
        // Title
        let title = "Design Comparison"
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let titleSize = title.size(withAttributes: titleAttributes)
        title.draw(at: NSPoint(x: padding, y: y - titleSize.height), withAttributes: titleAttributes)
        
        // Change percentage
        let changeText = String(format: "Change: %.2f%%", diffPercentage)
        let changeAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .medium),
            .foregroundColor: diffPercentage > 10 ? NSColor(red: 0.96, green: 0.25, blue: 0.37, alpha: 1.0) : 
                             diffPercentage > 5 ? NSColor(red: 0.96, green: 0.62, blue: 0.04, alpha: 1.0) :
                             NSColor(red: 0.06, green: 0.73, blue: 0.51, alpha: 1.0)
        ]
        let changeSize = changeText.size(withAttributes: changeAttributes)
        changeText.draw(at: NSPoint(x: exportWidth - padding - changeSize.width, y: y - changeSize.height), withAttributes: changeAttributes)
        
        return y - titleSize.height - 20
    }
    
    private func drawImages(at y: CGFloat, imageWidth: CGFloat, imageHeight: CGFloat) {
        let beforeX = padding
        let afterX = padding + imageWidth + imageSpacing
        
        // Draw "Before" label
        let labelAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: NSColor.white.withAlphaComponent(0.8)
        ]
        "Before".draw(at: NSPoint(x: beforeX, y: y + 5), withAttributes: labelAttributes)
        "After".draw(at: NSPoint(x: afterX, y: y + 5), withAttributes: labelAttributes)
        
        let imageY = y - imageHeight
        
        // Draw checkerboard background
        drawCheckerboard(in: NSRect(x: beforeX, y: imageY, width: imageWidth, height: imageHeight))
        drawCheckerboard(in: NSRect(x: afterX, y: imageY, width: imageWidth, height: imageHeight))
        
        // Draw images
        let beforeRect = NSRect(x: beforeX, y: imageY, width: imageWidth, height: imageHeight)
        let afterRect = NSRect(x: afterX, y: imageY, width: imageWidth, height: imageHeight)
        
        drawImageFit(beforeImage, in: beforeRect)
        drawImageFit(afterImage, in: afterRect)
        
        // Draw annotation badges on after image
        drawAnnotationBadges(in: afterRect)
        
        // Draw borders
        NSColor.white.withAlphaComponent(0.1).setStroke()
        let beforePath = NSBezierPath(roundedRect: beforeRect, xRadius: 12, yRadius: 12)
        beforePath.lineWidth = 1
        beforePath.stroke()
        
        let afterPath = NSBezierPath(roundedRect: afterRect, xRadius: 12, yRadius: 12)
        afterPath.lineWidth = 1
        afterPath.stroke()
    }
    
    private func drawCheckerboard(in rect: NSRect) {
        let squareSize: CGFloat = 10
        let lightColor = NSColor(white: 0.2, alpha: 1.0)
        let darkColor = NSColor(white: 0.15, alpha: 1.0)
        
        let path = NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12)
        path.addClip()
        
        let cols = Int(ceil(rect.width / squareSize))
        let rows = Int(ceil(rect.height / squareSize))
        
        for row in 0..<rows {
            for col in 0..<cols {
                let isLight = (row + col) % 2 == 0
                (isLight ? lightColor : darkColor).setFill()
                let squareRect = NSRect(
                    x: rect.origin.x + CGFloat(col) * squareSize,
                    y: rect.origin.y + CGFloat(row) * squareSize,
                    width: squareSize,
                    height: squareSize
                )
                squareRect.fill()
            }
        }
        
        NSGraphicsContext.current?.cgContext.resetClip()
    }
    
    private func drawImageFit(_ image: NSImage, in rect: NSRect) {
        let imageAspect = image.size.width / image.size.height
        let rectAspect = rect.width / rect.height
        
        var drawRect: NSRect
        if imageAspect > rectAspect {
            let height = rect.width / imageAspect
            drawRect = NSRect(x: rect.origin.x, y: rect.origin.y + (rect.height - height) / 2, width: rect.width, height: height)
        } else {
            let width = rect.height * imageAspect
            drawRect = NSRect(x: rect.origin.x + (rect.width - width) / 2, y: rect.origin.y, width: width, height: rect.height)
        }
        
        // Add padding
        let padding: CGFloat = 16
        drawRect = drawRect.insetBy(dx: padding, dy: padding)
        
        image.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    }
    
    private func drawAnnotationBadges(in rect: NSRect) {
        for (index, annotation) in annotations.enumerated() {
            let x = rect.origin.x + rect.width * annotation.x
            let y = rect.origin.y + rect.height * (1 - annotation.y)
            
            let badgeSize: CGFloat = 20
            let badgeRect = NSRect(x: x - badgeSize/2, y: y - badgeSize/2, width: badgeSize, height: badgeSize)
            
            // Draw badge background
            accentColor.setFill()
            let badgePath = NSBezierPath(ovalIn: badgeRect)
            badgePath.fill()
            
            // Draw number
            let number = "\(index + 1)"
            let numberAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 10, weight: .bold),
                .foregroundColor: NSColor.white
            ]
            let numberSize = number.size(withAttributes: numberAttributes)
            number.draw(at: NSPoint(x: x - numberSize.width/2, y: y - numberSize.height/2), withAttributes: numberAttributes)
        }
    }
    
    private func drawChangesSection(at y: CGFloat) {
        var currentY = y
        
        // Section title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: NSColor.white
        ]
        "Design Changes".draw(at: NSPoint(x: padding, y: currentY), withAttributes: titleAttributes)
        currentY -= 40
        
        // Draw each change item
        for (index, annotation) in annotations.enumerated() {
            drawChangeItem(number: index + 1, description: annotation.description, at: currentY)
            currentY -= 45
        }
    }
    
    private func drawChangeItem(number: Int, description: String, at y: CGFloat) {
        // Badge
        let badgeSize: CGFloat = 24
        let badgeRect = NSRect(x: padding, y: y - badgeSize + 6, width: badgeSize, height: badgeSize)
        
        accentColor.setFill()
        let badgePath = NSBezierPath(ovalIn: badgeRect)
        badgePath.fill()
        
        let numberText = "\(number)"
        let numberAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let numberSize = numberText.size(withAttributes: numberAttributes)
        numberText.draw(at: NSPoint(x: badgeRect.midX - numberSize.width/2, y: badgeRect.midY - numberSize.height/2), withAttributes: numberAttributes)
        
        // Description
        let descAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .regular),
            .foregroundColor: NSColor.white.withAlphaComponent(0.85)
        ]
        description.draw(at: NSPoint(x: padding + badgeSize + 16, y: y - 4), withAttributes: descAttributes)
    }
    
    private func drawFooter() {
        let footerY: CGFloat = padding
        
        // Logo text
        let logoText = "DesignDiff"
        let logoAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: NSColor.white.withAlphaComponent(0.4)
        ]
        let logoSize = logoText.size(withAttributes: logoAttributes)
        
        // Draw logo icon (simplified)
        let iconSize: CGFloat = 16
        let totalWidth = iconSize + 6 + logoSize.width
        let startX = (exportWidth - totalWidth) / 2
        
        // Draw small orange square as icon
        accentColor.withAlphaComponent(0.4).setFill()
        let iconRect = NSRect(x: startX, y: footerY, width: iconSize, height: iconSize)
        let iconPath = NSBezierPath(roundedRect: iconRect, xRadius: 4, yRadius: 4)
        iconPath.fill()
        
        // Draw logo text
        logoText.draw(at: NSPoint(x: startX + iconSize + 6, y: footerY), withAttributes: logoAttributes)
    }
}









