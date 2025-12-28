import SwiftUI
import AppKit

// MARK: - Export Image Generator

class ExportImageGenerator {
    let beforeImage: NSImage
    let afterImage: NSImage
    let annotations: [EditableAnnotation]
    let diffPercentage: Double
    let includeAnnotations: Bool
    
    init(beforeImage: NSImage, afterImage: NSImage, annotations: [EditableAnnotation], diffPercentage: Double, includeAnnotations: Bool = true) {
        self.beforeImage = beforeImage
        self.afterImage = afterImage
        self.annotations = annotations
        self.diffPercentage = diffPercentage
        self.includeAnnotations = includeAnnotations
    }
    
    func generateExportImage() -> NSImage? {
        // Adjust width based on whether annotations are included
        let annotationPanelWidth: CGFloat = includeAnnotations ? 280 : 0
        let panelSpacing: CGFloat = includeAnnotations ? 24 : 0
        let exportWidth: CGFloat = includeAnnotations ? 1400 : 1120
        let imageHeight: CGFloat = 550
        let headerHeight: CGFloat = 50
        let padding: CGFloat = 24
        
        // Calculate annotation heights (max 2 lines per annotation)
        let annotationFont = NSFont.systemFont(ofSize: 12)
        let lineHeight: CGFloat = 18
        let maxLines: CGFloat = 2
        let annotationRowHeight: CGFloat = lineHeight * maxLines + 12
        let totalAnnotationsHeight = CGFloat(annotations.count) * annotationRowHeight + 50
        
        let contentHeight = includeAnnotations ? max(imageHeight, totalAnnotationsHeight) : imageHeight
        let totalHeight = headerHeight + contentHeight + padding
        
        let size = CGSize(width: exportWidth, height: totalHeight)
        
        let image = NSImage(size: size)
        image.lockFocus()
        
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }
        
        let orangeColor = NSColor(hex: "ff6b35") ?? NSColor.orange
        let redColor = NSColor(hex: "ef4444") ?? NSColor.red
        let greenColor = NSColor(hex: "22c55e") ?? NSColor.green
        
        // Background
        NSColor(hex: "0a0a0b")?.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()
        
        // Header with integrated logo
        let headerRect = NSRect(x: 0, y: size.height - headerHeight, width: size.width, height: headerHeight)
        NSColor(hex: "0a0a0b")?.setFill()
        NSBezierPath(rect: headerRect).fill()
        
        // Logo + Title in header
        let logoFont = NSFont.systemFont(ofSize: 18, weight: .bold)
        let designAttrs: [NSAttributedString.Key: Any] = [
            .font: logoFont,
            .foregroundColor: NSColor.white
        ]
        let diffAttrs: [NSAttributedString.Key: Any] = [
            .font: logoFont,
            .foregroundColor: orangeColor
        ]
        let designStr = NSAttributedString(string: "Design", attributes: designAttrs)
        let diffStr = NSAttributedString(string: "Diff", attributes: diffAttrs)
        
        designStr.draw(at: NSPoint(x: padding, y: size.height - headerHeight + 14))
        diffStr.draw(at: NSPoint(x: padding + designStr.size().width, y: size.height - headerHeight + 14))
        
        // Content area
        let contentY = padding
        let imageAreaWidth = exportWidth - annotationPanelWidth - padding * (includeAnnotations ? 3 : 2)
        
        // Draw Before image with RED label
        let beforeTitleFont = NSFont.systemFont(ofSize: 11, weight: .bold)
        let beforeTitleAttrs: [NSAttributedString.Key: Any] = [
            .font: beforeTitleFont,
            .foregroundColor: redColor
        ]
        "Before".draw(at: NSPoint(x: padding, y: contentY + contentHeight - 18), withAttributes: beforeTitleAttrs)
        
        let singleImageWidth = (imageAreaWidth - 16) / 2
        let beforeRect = NSRect(x: padding, y: contentY, width: singleImageWidth, height: contentHeight - 26)
        drawCheckerboard(in: beforeRect, context: context)
        drawImageWithBorder(beforeImage, in: beforeRect, borderColor: redColor)
        
        // Draw After image with GREEN label
        let afterTitleAttrs: [NSAttributedString.Key: Any] = [
            .font: beforeTitleFont,
            .foregroundColor: greenColor
        ]
        "After".draw(at: NSPoint(x: padding + singleImageWidth + 16, y: contentY + contentHeight - 18), withAttributes: afterTitleAttrs)
        
        let afterRect = NSRect(x: padding + singleImageWidth + 16, y: contentY, width: singleImageWidth, height: contentHeight - 26)
        drawCheckerboard(in: afterRect, context: context)
        drawImageWithBorder(afterImage, in: afterRect, borderColor: greenColor)
        
        // Draw annotation badges on after image (always show numbers)
        for (index, annotation) in annotations.enumerated() {
            let badgeX = afterRect.origin.x + afterRect.width * CGFloat(annotation.x)
            let badgeY = afterRect.origin.y + afterRect.height * (1 - CGFloat(annotation.y))
            drawAnnotationBadge(number: index + 1, at: NSPoint(x: badgeX, y: badgeY))
        }
        
        // Draw annotations panel (only if includeAnnotations is true)
        if includeAnnotations {
            // Draw annotations panel
            let panelX = exportWidth - annotationPanelWidth - padding
            let panelRect = NSRect(x: panelX, y: contentY, width: annotationPanelWidth, height: contentHeight - 26)
            
            // Panel background
            NSColor.white.withAlphaComponent(0.03).setFill()
            let panelPath = NSBezierPath(roundedRect: panelRect, xRadius: 10, yRadius: 10)
            panelPath.fill()
            
            // Panel title
            let panelTitleFont = NSFont.systemFont(ofSize: 14, weight: .semibold)
            let panelTitleAttrs: [NSAttributedString.Key: Any] = [
                .font: panelTitleFont,
                .foregroundColor: NSColor.white
            ]
            "Design Changes".draw(at: NSPoint(x: panelX + 16, y: panelRect.maxY - 28), withAttributes: panelTitleAttrs)
            
            // Draw annotations list (max 2 lines per item)
            let numberFont = NSFont.systemFont(ofSize: 11, weight: .bold)
            let maxTextWidth = annotationPanelWidth - 50
            
            var currentY = panelRect.maxY - 48
            
            for (index, annotation) in annotations.enumerated() {
                let numberAttrs: [NSAttributedString.Key: Any] = [
                    .font: numberFont,
                    .foregroundColor: orangeColor
                ]
                
                let descAttrs: [NSAttributedString.Key: Any] = [
                    .font: annotationFont,
                    .foregroundColor: NSColor.white.withAlphaComponent(0.85)
                ]
                
                // Create attributed string with number and description
                let numberStr = NSMutableAttributedString(string: "(\(index + 1)) ", attributes: numberAttrs)
                let truncatedText = truncateToLines(annotation.description, maxLines: 2, font: annotationFont, maxWidth: maxTextWidth - 40)
                let descStr = NSAttributedString(string: truncatedText, attributes: descAttrs)
                numberStr.append(descStr)
                
                // Draw combined text with proper line wrapping
                let textRect = NSRect(x: panelX + 12, y: currentY - lineHeight * maxLines, width: maxTextWidth, height: lineHeight * maxLines + 4)
                numberStr.draw(with: textRect, options: [.usesLineFragmentOrigin, .usesFontLeading])
                
                currentY -= annotationRowHeight
            }
        }
        
        image.unlockFocus()
        return image
    }
    
    private func drawImageWithBorder(_ image: NSImage, in rect: NSRect, borderColor: NSColor) {
        // Draw border
        borderColor.withAlphaComponent(0.6).setStroke()
        let borderPath = NSBezierPath(roundedRect: rect, xRadius: 10, yRadius: 10)
        borderPath.lineWidth = 2
        borderPath.stroke()
        
        // Draw image
        drawImage(image, in: rect)
    }
    
    private func truncateToLines(_ text: String, maxLines: Int, font: NSFont, maxWidth: CGFloat) -> String {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let words = text.split(separator: " ")
        var result = ""
        var currentLine = ""
        var lineCount = 1
        
        for word in words {
            let testLine = currentLine.isEmpty ? String(word) : currentLine + " " + word
            let testSize = testLine.size(withAttributes: attrs)
            
            if testSize.width > maxWidth {
                if lineCount >= maxLines {
                    // Truncate with ellipsis
                    while !currentLine.isEmpty {
                        let truncated = currentLine + "..."
                        if truncated.size(withAttributes: attrs).width <= maxWidth {
                            return result.isEmpty ? truncated : result + "\n" + truncated
                        }
                        currentLine = String(currentLine.dropLast())
                    }
                    return result + "..."
                }
                result = result.isEmpty ? currentLine : result + "\n" + currentLine
                currentLine = String(word)
                lineCount += 1
            } else {
                currentLine = testLine
            }
        }
        
        if !currentLine.isEmpty {
            result = result.isEmpty ? currentLine : result + "\n" + currentLine
        }
        
        return result
    }
    
    private func calculateTextHeight(_ text: String, font: NSFont, maxWidth: CGFloat) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let attrString = NSAttributedString(string: text, attributes: attrs)
        let textStorage = NSTextStorage(attributedString: attrString)
        let textContainer = NSTextContainer(containerSize: NSSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude))
        let layoutManager = NSLayoutManager()
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        textContainer.lineFragmentPadding = 0
        layoutManager.glyphRange(for: textContainer)
        
        return layoutManager.usedRect(for: textContainer).height
    }
    
    private func drawWrappedText(_ text: String, in rect: NSRect, attributes: [NSAttributedString.Key: Any]) {
        let attrString = NSAttributedString(string: text, attributes: attributes)
        attrString.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
    }
    
    private func drawCheckerboard(in rect: NSRect, context: CGContext) {
        let squareSize: CGFloat = 8
        let lightColor = NSColor(white: 0.25, alpha: 1)
        let darkColor = NSColor(white: 0.2, alpha: 1)
        
        context.saveGState()
        let path = NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12)
        path.addClip()
        
        var y = rect.origin.y
        var rowIndex = 0
        while y < rect.maxY {
            var x = rect.origin.x
            var colIndex = rowIndex % 2
            while x < rect.maxX {
                let color = (colIndex % 2 == 0) ? lightColor : darkColor
                color.setFill()
                NSBezierPath(rect: NSRect(x: x, y: y, width: squareSize, height: squareSize)).fill()
                x += squareSize
                colIndex += 1
            }
            y += squareSize
            rowIndex += 1
        }
        
        context.restoreGState()
    }
    
    private func drawImage(_ image: NSImage, in rect: NSRect) {
        let imageAspect = image.size.width / image.size.height
        let rectAspect = rect.width / rect.height
        
        var drawRect: NSRect
        if imageAspect > rectAspect {
            let height = rect.width / imageAspect
            drawRect = NSRect(
                x: rect.origin.x,
                y: rect.origin.y + (rect.height - height) / 2,
                width: rect.width,
                height: height
            )
        } else {
            let width = rect.height * imageAspect
            drawRect = NSRect(
                x: rect.origin.x + (rect.width - width) / 2,
                y: rect.origin.y,
                width: width,
                height: rect.height
            )
        }
        
        let insetRect = drawRect.insetBy(dx: 12, dy: 12)
        image.draw(in: insetRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    }
    
    private func drawAnnotationBadge(number: Int, at point: NSPoint) {
        let size: CGFloat = 20
        let rect = NSRect(x: point.x - size/2, y: point.y - size/2, width: size, height: size)
        
        let orangeColor = NSColor(hex: "ff6b35") ?? NSColor.orange
        orangeColor.setFill()
        let path = NSBezierPath(ovalIn: rect)
        path.fill()
        
        let font = NSFont.systemFont(ofSize: 9, weight: .bold)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.white
        ]
        let numStr = "\(number)"
        let strSize = numStr.size(withAttributes: attrs)
        numStr.draw(at: NSPoint(x: point.x - strSize.width/2, y: point.y - strSize.height/2), withAttributes: attrs)
    }
    
}

// Helper extension for NSColor
extension NSColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

enum ResultTab: String, CaseIterable {
    case annotations = "Annotations"
    case slack = "Slack"
    case linear = "Linear"
    
    var icon: String {
        switch self {
        case .annotations: return "list.number"
        case .slack: return "number"
        case .linear: return "square.and.pencil"
        }
    }
}

struct ResultsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: ResultTab = .annotations
    @State private var copiedId: String?
    @State private var resultsViewID = UUID()
    @State private var includeDesignChanges: Bool = true
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left: Image Comparison
            ImageComparisonView()
                .frame(maxWidth: .infinity, alignment: .top)
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Right: Analysis Results
            VStack(spacing: 0) {
                // Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(ResultTab.allCases, id: \.self) { tab in
                            TabButton(
                                tab: tab,
                                isSelected: selectedTab == tab,
                                action: { selectedTab = tab }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .frame(height: 48)
                .background(Color.white.opacity(0.03))
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Tab Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        switch selectedTab {
                        case .annotations:
                            AnnotationsTabView(copiedId: $copiedId)
                        case .slack:
                            SlackTabView(copiedId: $copiedId)
                        case .linear:
                            LinearTabView(copiedId: $copiedId)
                        }
                    }
                    .padding(20)
                }
                
                // Bottom Actions
                HStack(spacing: 12) {
                    // Checkbox for including Design Changes
                    Toggle(isOn: $includeDesignChanges) {
                        Text("Include Design Changes")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .toggleStyle(GreenCheckboxToggleStyle())
                    
                    Spacer()
                    
                    Button(action: exportFullScreenshot) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 14))
                            Text("Save Diff PNG")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "ff6b35"), Color(hex: "e55a2b")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                        .shadow(color: Color(hex: "ff6b35").opacity(0.3), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(Color.white.opacity(0.03))
            }
            .frame(width: 450)
        }
        .id(resultsViewID)
    }
    
    private func exportFullScreenshot() {
        guard let beforeImage = appState.beforeImage,
              let afterImage = appState.afterImage else { return }
        
        // Create export image generator
        let generator = ExportImageGenerator(
            beforeImage: beforeImage,
            afterImage: afterImage,
            annotations: appState.editableAnnotations,
            diffPercentage: appState.diffResult?.diffPercentage ?? 0,
            includeAnnotations: includeDesignChanges
        )
        
        guard let exportImage = generator.generateExportImage() else { return }
        
        // Convert to PNG data
        guard let tiffData = exportImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: NSBitmapImageRep.FileType.png, properties: [:]) else { return }
        
        // Show save panel
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "design-diff-\(Int(Date().timeIntervalSince1970)).png"
        
        if savePanel.runModal() == .OK, let destination = savePanel.url {
            do {
                try pngData.write(to: destination)
            } catch {
                print("Failed to save: \(error)")
            }
        }
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let tab: ResultTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 12))
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? Color(hex: "ff6b35") : .white.opacity(0.5))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? Color(hex: "ff6b35").opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Annotations Tab

struct AnnotationsTabView: View {
    @EnvironmentObject var appState: AppState
    @Binding var copiedId: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Design Changes")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                CopyButton(
                    text: appState.editableAnnotations.enumerated().map { "(\($0.offset + 1)) \($0.element.description)" }.joined(separator: "\n"),
                    id: "annotations",
                    copiedId: $copiedId
                )
            }
            
            if appState.editableAnnotations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "plus.circle.dashed")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.3))
                    Text("No annotations yet")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                    Text("Click 'Add' button and click on the image to add annotations")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(appState.editableAnnotations.enumerated()), id: \.element.id) { index, annotation in
                        AnnotationRow(
                            annotation: annotation,
                            number: index + 1,
                            isSelected: appState.selectedAnnotationId == annotation.id,
                            onSelect: {
                                appState.selectedAnnotationId = annotation.id
                            },
                            onUpdate: { newDescription in
                                appState.updateAnnotationDescription(id: annotation.id, description: newDescription)
                            },
                            onDelete: {
                                appState.deleteAnnotation(id: annotation.id)
                            }
                        )
                    }
                }
            }
        }
    }
}

struct AnnotationRow: View {
    let annotation: EditableAnnotation
    let number: Int
    let isSelected: Bool
    let onSelect: () -> Void
    let onUpdate: (String) -> Void
    let onDelete: () -> Void
    
    @State private var isEditing: Bool = false
    @State private var editText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                // Number badge
                Text("\(number)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Color(hex: "ff6b35"))
                    .clipShape(Circle())
                
                // Description (editable)
                if isEditing {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Enter description", text: $editText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(6)
                            .focused($isFocused)
                            .onAppear {
                                editText = annotation.description
                                isFocused = true
                            }
                        
                        // Save/Cancel buttons
                        HStack(spacing: 8) {
                            Button(action: {
                                editText = annotation.description
                                isEditing = false
                            }) {
                                Text("Cancel")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: {
                                onUpdate(editText)
                                isEditing = false
                            }) {
                                Text("Save")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "ff6b35"))
                                    .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .disabled(editText.trimmingCharacters(in: .whitespaces).isEmpty)
                            .opacity(editText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
                            
                            Spacer()
                        }
                    }
                } else {
                    Text(annotation.description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture(count: 2) {
                            isEditing = true
                        }
                        .onTapGesture {
                            onSelect()
                        }
                    
                    Spacer()
                    
                    // Actions (only show when not editing)
                    HStack(spacing: 4) {
                        Button(action: {
                            editText = annotation.description
                            isEditing = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                                .frame(width: 24, height: 24)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundColor(.red.opacity(0.7))
                                .frame(width: 24, height: 24)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(12)
            
            // Editing mode indicator
            if isEditing {
                HStack(spacing: 6) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "ff6b35"))
                    Text("Editing mode")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "ff6b35"))
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
        .background(
            Group {
                if isEditing {
                    Color(hex: "ff6b35").opacity(0.15)
                } else if isSelected {
                    Color(hex: "ff6b35").opacity(0.1)
                } else {
                    Color.white.opacity(0.03)
                }
            }
        )
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isEditing ? Color(hex: "ff6b35").opacity(0.8) :
                    isSelected ? Color(hex: "ff6b35").opacity(0.5) :
                    Color.clear,
                    lineWidth: isEditing ? 2 : 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isEditing)
    }
}

// MARK: - Slack Tab

struct SlackTabView: View {
    @EnvironmentObject var appState: AppState
    @Binding var copiedId: String?
    
    private var slackContent: String {
        var content = "🎨 *Design Update Summary*\n\n*Visual Changes:*\n"
        for (index, annotation) in appState.editableAnnotations.enumerated() {
            content += "(\(index + 1)) \(annotation.description)\n"
        }
        content += "\n_Generated by DesignDiff_ ✨"
        return content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "number")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "4A154B"))
                    
                    Text("Slack Format")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                CopyButton(
                    text: slackContent,
                    id: "slack",
                    label: "Copy for Slack",
                    copiedId: $copiedId
                )
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("🎨 *Design Update Summary*")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("*Visual Changes:*")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                
                ForEach(Array(appState.editableAnnotations.enumerated()), id: \.element.id) { index, annotation in
                    HStack(alignment: .top, spacing: 8) {
                        Text("(\(index + 1))")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "ff6b35"))
                        Text(annotation.description)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Text("_Generated by DesignDiff_ ✨")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 8)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
}

// MARK: - Linear Tab

struct LinearTabView: View {
    @EnvironmentObject var appState: AppState
    @Binding var copiedId: String?
    
    private var linearContent: String {
        var content = "## Design Diff Analysis\n\n### Visual Changes\n"
        for (index, annotation) in appState.editableAnnotations.enumerated() {
            content += "(\(index + 1)) \(annotation.description)\n"
        }
        content += "\n### Developer Notes\nSee attached images for visual reference."
        return content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "5E6AD2"))
                    
                    Text("Linear Format")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                CopyButton(
                    text: linearContent,
                    id: "linear",
                    label: "Copy for Linear",
                    copiedId: $copiedId
                )
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("## Design Diff Analysis")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                
                Text("### Visual Changes")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 4)
                
                ForEach(Array(appState.editableAnnotations.enumerated()), id: \.element.id) { index, annotation in
                    HStack(alignment: .top, spacing: 8) {
                        Text("(\(index + 1))")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "ff6b35"))
                        Text(annotation.description)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Text("### Developer Notes")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 8)
                
                Text("See attached images for visual reference.")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.03))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
}

// MARK: - Copy Button

struct CopyButton: View {
    let text: String
    let id: String
    var label: String = "Copy"
    @Binding var copiedId: String?
    
    var body: some View {
        Button(action: {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            copiedId = id
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                if copiedId == id {
                    copiedId = nil
                }
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: copiedId == id ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 11))
                Text(copiedId == id ? "Copied!" : label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(copiedId == id ? Color(hex: "10b981") : .white.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.08))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Green Checkbox Toggle Style

struct GreenCheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            HStack(spacing: 8) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(configuration.isOn ? Color(hex: "22c55e") : .white.opacity(0.3))
                
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ResultsView()
        .environmentObject({
            let state = AppState()
            state.analysisResult = AnalysisResult.mock
            state.initializeEditableAnnotations()
            return state
        }())
        .frame(width: 1200, height: 800)
        .background(Color(hex: "0a0a0b"))
}
