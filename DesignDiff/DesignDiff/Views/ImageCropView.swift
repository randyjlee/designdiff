import SwiftUI
import AppKit

struct ImageCropView: View {
    let image: NSImage
    let onComplete: (NSImage) -> Void
    let onCancel: () -> Void
    
    @State private var cropRect: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    @State private var imageFrame: CGRect = .zero
    @FocusState private var isFocused: Bool
    
    private let handleSize: CGFloat = 16
    private let minCropSize: CGFloat = 0.15
    
    var body: some View {
        ZStack {
            // Fully opaque dark background
            Color(hex: "0a0a0b")
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Text("Crop Image")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 32)
                .padding(.top, 32)
                
                // Crop area
                GeometryReader { geometry in
                    ZStack {
                        // Image
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        // Crop overlay
                        CropOverlayView(
                            cropRect: cropRect,
                            imageFrame: calculateImageFrame(in: geometry.size)
                        )
                        .onAppear {
                            imageFrame = calculateImageFrame(in: geometry.size)
                        }
                        .onChange(of: geometry.size) { _, newSize in
                            imageFrame = calculateImageFrame(in: newSize)
                        }
                        
                        // Drag handles
                        CropHandles(
                            cropRect: $cropRect,
                            imageFrame: imageFrame,
                            handleSize: handleSize,
                            minCropSize: minCropSize
                        )
                    }
                    .focusable(false)
                    .focusEffectDisabled()
                }
                .padding(.horizontal, 32)
                
                // Instructions & Actions
                VStack(spacing: 16) {
                    Text("Drag to adjust crop area")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                    
                    HStack(spacing: 16) {
                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 120, height: 44)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.escape, modifiers: [])
                        
                        Button(action: performCrop) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14))
                                Text("Done")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(width: 120, height: 44)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "ff6b35"), Color(hex: "e55a2b")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.return, modifiers: [])
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .focusable()
        .focused($isFocused)
        .onAppear {
            // Auto-focus when crop view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFocused = true
            }
        }
        .onKeyPress { keyPress in
            switch keyPress.key {
            case .escape:
                onCancel()
                return .handled
            case .return:
                // Handle Enter/Return key - check for modifiers
                let modifiers = keyPress.modifiers
                // Only handle if no command/control/option modifiers
                if modifiers.intersection([.command, .control, .option]).isEmpty {
                    performCrop()
                    return .handled
                }
                return .ignored
            default:
                return .ignored
            }
        }
    }
    
    private func calculateImageFrame(in containerSize: CGSize) -> CGRect {
        guard let imageRep = image.representations.first else {
            return CGRect(origin: .zero, size: containerSize)
        }
        
        let imageWidth = CGFloat(imageRep.pixelsWide)
        let imageHeight = CGFloat(imageRep.pixelsHigh)
        let imageAspect = imageWidth / imageHeight
        let containerAspect = containerSize.width / containerSize.height
        
        var frame = CGRect.zero
        
        if imageAspect > containerAspect {
            // Image is wider
            frame.size.width = containerSize.width
            frame.size.height = containerSize.width / imageAspect
            frame.origin.x = 0
            frame.origin.y = (containerSize.height - frame.size.height) / 2
        } else {
            // Image is taller
            frame.size.height = containerSize.height
            frame.size.width = containerSize.height * imageAspect
            frame.origin.x = (containerSize.width - frame.size.width) / 2
            frame.origin.y = 0
        }
        
        return frame
    }
    
    private func performCrop() {
        guard let imageRep = image.representations.first else {
            onCancel()
            return
        }
        
        let imageWidth = CGFloat(imageRep.pixelsWide)
        let imageHeight = CGFloat(imageRep.pixelsHigh)
        
        // Convert normalized coordinates to pixel coordinates
        let x = cropRect.origin.x * imageWidth
        let y = cropRect.origin.y * imageHeight
        let width = cropRect.size.width * imageWidth
        let height = cropRect.size.height * imageHeight
        
        let cropRectPixels = CGRect(x: x, y: y, width: width, height: height)
        
        if let croppedImage = cropImage(image, to: cropRectPixels) {
            onComplete(croppedImage)
        } else {
            onCancel()
        }
    }
    
    private func cropImage(_ image: NSImage, to rect: CGRect) -> NSImage? {
        guard let imageRep = image.representations.first,
              let cgImage = imageRep.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let imageWidth = CGFloat(cgImage.width)
        let imageHeight = CGFloat(cgImage.height)
        
        // Ensure crop rect is within bounds
        let clampedRect = CGRect(
            x: max(0, min(rect.origin.x, imageWidth)),
            y: max(0, min(rect.origin.y, imageHeight)),
            width: min(rect.size.width, imageWidth - rect.origin.x),
            height: min(rect.size.height, imageHeight - rect.origin.y)
        )
        
        guard let croppedCGImage = cgImage.cropping(to: clampedRect) else {
            return nil
        }
        
        let croppedImage = NSImage(cgImage: croppedCGImage, size: NSSize(width: clampedRect.width, height: clampedRect.height))
        return croppedImage
    }
}

// MARK: - Crop Overlay View

struct CropOverlayView: View {
    let cropRect: CGRect
    let imageFrame: CGRect
    
    var body: some View {
        GeometryReader { geometry in
            let cropX = imageFrame.origin.x + cropRect.origin.x * imageFrame.width
            let cropY = imageFrame.origin.y + cropRect.origin.y * imageFrame.height
            let cropWidth = cropRect.width * imageFrame.width
            let cropHeight = cropRect.height * imageFrame.height
            let actualCropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
            
            ZStack {
                // Darkened overlay outside crop area
                Path { path in
                    path.addRect(CGRect(origin: .zero, size: geometry.size))
                    path.addRect(actualCropRect)
                }
                .fill(style: FillStyle(eoFill: true))
                .foregroundColor(Color.black.opacity(0.6))
                
                // Crop border
                Rectangle()
                    .stroke(Color(hex: "ff6b35"), lineWidth: 2)
                    .frame(width: cropWidth, height: cropHeight)
                    .position(x: cropX + cropWidth / 2, y: cropY + cropHeight / 2)
                
                // Grid lines (rule of thirds)
                Path { path in
                    // Vertical lines
                    for i in 1...2 {
                        let x = cropX + cropWidth * CGFloat(i) / 3
                        path.move(to: CGPoint(x: x, y: cropY))
                        path.addLine(to: CGPoint(x: x, y: cropY + cropHeight))
                    }
                    
                    // Horizontal lines
                    for i in 1...2 {
                        let y = cropY + cropHeight * CGFloat(i) / 3
                        path.move(to: CGPoint(x: cropX, y: y))
                        path.addLine(to: CGPoint(x: cropX + cropWidth, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Crop Handles

struct CropHandles: View {
    @Binding var cropRect: CGRect
    let imageFrame: CGRect
    let handleSize: CGFloat
    let minCropSize: CGFloat
    
    @State private var dragStartRect: CGRect = .zero
    @State private var dragStartLocation: CGPoint = .zero
    @State private var activeHandle: HandlePosition? = nil
    
    enum HandlePosition {
        case topLeft, topRight, bottomLeft, bottomRight
        case top, bottom, left, right
        case center
    }
    
    var body: some View {
        GeometryReader { geometry in
            let cropX = imageFrame.origin.x + cropRect.origin.x * imageFrame.width
            let cropY = imageFrame.origin.y + cropRect.origin.y * imageFrame.height
            let cropWidth = cropRect.width * imageFrame.width
            let cropHeight = cropRect.height * imageFrame.height
            
            ZStack {
                // Corner handles
                handleView(at: CGPoint(x: cropX, y: cropY))
                    .gesture(dragGesture(for: .topLeft, in: geometry.size))
                
                handleView(at: CGPoint(x: cropX + cropWidth, y: cropY))
                    .gesture(dragGesture(for: .topRight, in: geometry.size))
                
                handleView(at: CGPoint(x: cropX, y: cropY + cropHeight))
                    .gesture(dragGesture(for: .bottomLeft, in: geometry.size))
                
                handleView(at: CGPoint(x: cropX + cropWidth, y: cropY + cropHeight))
                    .gesture(dragGesture(for: .bottomRight, in: geometry.size))
                
                // Edge handles
                handleView(at: CGPoint(x: cropX + cropWidth / 2, y: cropY))
                    .gesture(dragGesture(for: .top, in: geometry.size))
                
                handleView(at: CGPoint(x: cropX + cropWidth / 2, y: cropY + cropHeight))
                    .gesture(dragGesture(for: .bottom, in: geometry.size))
                
                handleView(at: CGPoint(x: cropX, y: cropY + cropHeight / 2))
                    .gesture(dragGesture(for: .left, in: geometry.size))
                
                handleView(at: CGPoint(x: cropX + cropWidth, y: cropY + cropHeight / 2))
                    .gesture(dragGesture(for: .right, in: geometry.size))
            }
            // Invisible full-area gesture for center dragging
            .background(
                GeometryReader { _ in
                    Color.clear
                        .contentShape(Rectangle())
                }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        // Check if we're dragging inside the crop area
                        let location = value.location
                        if location.x >= cropX && location.x <= cropX + cropWidth &&
                           location.y >= cropY && location.y <= cropY + cropHeight {
                            
                            if dragStartRect == .zero {
                                dragStartRect = cropRect
                                dragStartLocation = value.startLocation
                                activeHandle = .center
                            }
                            
                            let delta = CGPoint(
                                x: (value.location.x - dragStartLocation.x) / imageFrame.width,
                                y: (value.location.y - dragStartLocation.y) / imageFrame.height
                            )
                            
                            updateCropRect(for: .center, delta: delta)
                        }
                    }
                    .onEnded { _ in
                        if activeHandle == .center {
                            dragStartRect = .zero
                            dragStartLocation = .zero
                            activeHandle = nil
                        }
                    }
            )
        }
        .focusable(false)
        .focusEffectDisabled()
    }
    
    private func handleView(at position: CGPoint) -> some View {
        Circle()
            .fill(Color(hex: "ff6b35"))
            .frame(width: handleSize, height: handleSize)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
            .position(position)
            .focusable(false)
            .focusEffectDisabled()
    }
    
    private func dragGesture(for handle: HandlePosition, in containerSize: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if dragStartRect == .zero {
                    dragStartRect = cropRect
                    dragStartLocation = value.startLocation
                    activeHandle = handle
                }
                
                let delta = CGPoint(
                    x: (value.location.x - dragStartLocation.x) / imageFrame.width,
                    y: (value.location.y - dragStartLocation.y) / imageFrame.height
                )
                
                updateCropRect(for: handle, delta: delta)
            }
            .onEnded { _ in
                dragStartRect = .zero
                dragStartLocation = .zero
                activeHandle = nil
            }
    }
    
    private func updateCropRect(for handle: HandlePosition, delta: CGPoint) {
        var newRect = dragStartRect
        
        switch handle {
        case .center:
            newRect.origin.x = dragStartRect.origin.x + delta.x
            newRect.origin.y = dragStartRect.origin.y + delta.y
            
            // Clamp to bounds
            newRect.origin.x = max(0, min(newRect.origin.x, 1 - newRect.width))
            newRect.origin.y = max(0, min(newRect.origin.y, 1 - newRect.height))
            
        case .topLeft:
            let newX = max(0, min(dragStartRect.origin.x + delta.x, dragStartRect.maxX - minCropSize))
            let newY = max(0, min(dragStartRect.origin.y + delta.y, dragStartRect.maxY - minCropSize))
            newRect.origin.x = newX
            newRect.origin.y = newY
            newRect.size.width = dragStartRect.maxX - newX
            newRect.size.height = dragStartRect.maxY - newY
            
        case .topRight:
            let newY = max(0, min(dragStartRect.origin.y + delta.y, dragStartRect.maxY - minCropSize))
            let newWidth = max(minCropSize, min(dragStartRect.width + delta.x, 1 - dragStartRect.origin.x))
            newRect.origin.y = newY
            newRect.size.width = newWidth
            newRect.size.height = dragStartRect.maxY - newY
            
        case .bottomLeft:
            let newX = max(0, min(dragStartRect.origin.x + delta.x, dragStartRect.maxX - minCropSize))
            let newHeight = max(minCropSize, min(dragStartRect.height + delta.y, 1 - dragStartRect.origin.y))
            newRect.origin.x = newX
            newRect.size.width = dragStartRect.maxX - newX
            newRect.size.height = newHeight
            
        case .bottomRight:
            let newWidth = max(minCropSize, min(dragStartRect.width + delta.x, 1 - dragStartRect.origin.x))
            let newHeight = max(minCropSize, min(dragStartRect.height + delta.y, 1 - dragStartRect.origin.y))
            newRect.size.width = newWidth
            newRect.size.height = newHeight
            
        case .top:
            let newY = max(0, min(dragStartRect.origin.y + delta.y, dragStartRect.maxY - minCropSize))
            newRect.origin.y = newY
            newRect.size.height = dragStartRect.maxY - newY
            
        case .bottom:
            let newHeight = max(minCropSize, min(dragStartRect.height + delta.y, 1 - dragStartRect.origin.y))
            newRect.size.height = newHeight
            
        case .left:
            let newX = max(0, min(dragStartRect.origin.x + delta.x, dragStartRect.maxX - minCropSize))
            newRect.origin.x = newX
            newRect.size.width = dragStartRect.maxX - newX
            
        case .right:
            let newWidth = max(minCropSize, min(dragStartRect.width + delta.x, 1 - dragStartRect.origin.x))
            newRect.size.width = newWidth
        }
        
        cropRect = newRect
    }
}

#Preview {
    ImageCropView(
        image: NSImage(systemSymbolName: "photo", accessibilityDescription: nil)!,
        onComplete: { _ in },
        onCancel: {}
    )
    .frame(width: 900, height: 700)
}
