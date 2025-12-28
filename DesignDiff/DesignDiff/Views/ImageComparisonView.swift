import SwiftUI

struct ImageComparisonView: View {
    @EnvironmentObject var appState: AppState
    @State private var isAddMode: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            comparisonHeader
            
            HStack(alignment: .top, spacing: 20) {
                ComparisonFrame(title: "Before", image: appState.beforeImage)
                AnnotatableAfterFrame(isAddMode: $isAddMode)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.white.opacity(0.02))
    }

    private var comparisonHeader: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle")
                    .foregroundColor(Color(hex: "ff6b35"))
                Text("Visual comparison")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            if let diff = appState.diffResult {
                Text("Change: \(String(format: "%.2f%%", diff.diffPercentage))")
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundColor(diffColor(for: diff.diffPercentage))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.03))
    }

    private func diffColor(for percentage: Double) -> Color {
        if percentage > 10 {
            return Color(hex: "f43f5e")
        } else if percentage > 5 {
            return Color(hex: "f59e0b")
        } else {
            return Color(hex: "10b981")
        }
    }
}

// Checkerboard pattern for transparency
struct CheckerboardBackground: View {
    let squareSize: CGFloat = 8
    let lightColor = Color(white: 0.25)
    let darkColor = Color(white: 0.2)
    
    var body: some View {
        Canvas { context, size in
            let columns = Int(ceil(size.width / squareSize))
            let rows = Int(ceil(size.height / squareSize))
            
            for row in 0..<rows {
                for col in 0..<columns {
                    let isLight = (row + col) % 2 == 0
                    let rect = CGRect(
                        x: CGFloat(col) * squareSize,
                        y: CGFloat(row) * squareSize,
                        width: squareSize,
                        height: squareSize
                    )
                    context.fill(
                        Path(rect),
                        with: .color(isLight ? lightColor : darkColor)
                    )
                }
            }
        }
    }
}

struct ComparisonFrame: View {
    let title: String
    let image: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }
            ZStack {
                // Checkerboard background
                CheckerboardBackground()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                
                // Border
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                
                if let image = image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(16)
                } else {
                    Text("No image")
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AnnotatableAfterFrame: View {
    @EnvironmentObject var appState: AppState
    @Binding var isAddMode: Bool
    @State private var frameSize: CGSize = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("After")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                
                // Add button
                Button(action: { isAddMode.toggle() }) {
                    Image(systemName: isAddMode ? "xmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(isAddMode ? .white.opacity(0.6) : Color(hex: "ff6b35"))
                }
                .buttonStyle(.plain)
                .help(isAddMode ? "Cancel" : "Add annotation")
                
                Spacer()
                
                if isAddMode {
                    Text("Click to add")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "ff6b35").opacity(0.8))
                }
            }
            
            GeometryReader { geometry in
                ZStack {
                    // Checkerboard background
                    CheckerboardBackground()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Border
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isAddMode ? Color(hex: "ff6b35").opacity(0.6) : Color.white.opacity(0.08), lineWidth: isAddMode ? 2 : 1)
                    
                    if let image = appState.afterImage {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(16)
                    }
                    
                    // Draggable annotations
                    ForEach(Array(appState.editableAnnotations.enumerated()), id: \.element.id) { index, annotation in
                        DraggableAnnotationBadge(
                            annotation: annotation,
                            number: index + 1,
                            frameSize: geometry.size,
                            isSelected: appState.selectedAnnotationId == annotation.id,
                            onSelect: {
                                appState.selectedAnnotationId = annotation.id
                            },
                            onDrag: { newX, newY in
                                appState.updateAnnotationPosition(id: annotation.id, x: newX, y: newY)
                            },
                            onDelete: {
                                appState.deleteAnnotation(id: annotation.id)
                            }
                        )
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { location in
                    if isAddMode {
                        let x = location.x / geometry.size.width
                        let y = location.y / geometry.size.height
                        appState.addAnnotation(at: x, y: y)
                        isAddMode = false
                    } else {
                        appState.selectedAnnotationId = nil
                    }
                }
                .onAppear {
                    frameSize = geometry.size
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DraggableAnnotationBadge: View {
    let annotation: EditableAnnotation
    let number: Int
    let frameSize: CGSize
    let isSelected: Bool
    let onSelect: () -> Void
    let onDrag: (Double, Double) -> Void
    let onDelete: () -> Void
    
    @State private var isDragging = false

    var body: some View {
        ZStack {
            // Badge
            Text("\(number)")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(
                    Circle()
                        .fill(Color(hex: "ff6b35"))
                        .shadow(color: .black.opacity(0.4), radius: isDragging ? 8 : 4, y: isDragging ? 4 : 2)
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 1.5)
                )
                .scaleEffect(isDragging ? 1.2 : 1.0)
            
            // Delete button (shown when selected)
            if isSelected {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 12, height: 12)
                        .background(Color.red)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .offset(x: 10, y: -10)
            }
        }
        .position(
            x: frameSize.width * annotation.x,
            y: frameSize.height * annotation.y
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    onSelect()
                    let newX = value.location.x / frameSize.width
                    let newY = value.location.y / frameSize.height
                    onDrag(newX, newY)
                }
                .onEnded { _ in
                    isDragging = false
                }
        )
        .onTapGesture {
            onSelect()
        }
        .animation(.spring(response: 0.3), value: isDragging)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    ImageComparisonView()
        .environmentObject(AppState())
        .frame(width: 800, height: 600)
        .background(Color(hex: "0a0a0b"))
}
