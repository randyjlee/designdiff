import SwiftUI
import UniformTypeIdentifiers

enum DropZoneType: Equatable {
    case before
    case after
    
    var label: String {
        switch self {
        case .before: return "Before"
        case .after: return "After"
        }
    }
    
    var icon: String {
        switch self {
        case .before: return "arrow.left"
        case .after: return "arrow.right"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .before: return Color(hex: "f43f5e") // Rose
        case .after: return Color(hex: "10b981") // Emerald
        }
    }
}

struct ImageDropZone: View {
    let type: DropZoneType
    let image: NSImage?
    let onDrop: (NSImage?) -> Void
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isTargeted = false
    @State private var isHovering = false
    private let dropZoneHeight: CGFloat = 280 * 1.3
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Label
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(type.accentColor.opacity(0.2))
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: type.icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(type.accentColor)
                }
                
                Text("\(type.label) Design")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                if image != nil {
                    Text("⌘V to replace")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            
            // Drop Zone
            ZStack {
                // Border
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? type.accentColor : (isTargeted ? type.accentColor : Color.white.opacity(0.15)),
                        style: StrokeStyle(lineWidth: isSelected ? 3 : 2, dash: image == nil ? [8, 4] : [])
                    )
                
                // Background
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ? type.accentColor.opacity(0.05) : (isTargeted ? type.accentColor.opacity(0.1) : Color.white.opacity(0.03))
                    )
                
                if let image = image {
                    // Image preview
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(16)
                    
                    // Hover overlay with upload button
                    if isHovering {
                        ZStack {
                            Color.black.opacity(0.6)
                            
                            VStack(spacing: 12) {
                                Image(systemName: "arrow.up.doc")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                
                                Button(action: {
                                    openFilePicker()
                                }) {
                                    Text("Replace Image")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(type.accentColor)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .cornerRadius(16)
                    }
                    
                    // Remove button
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { onDrop(nil) }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 24, height: 24)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .opacity(isHovering ? 1 : 0)
                        }
                        Spacer()
                    }
                    .padding(12)
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(type.accentColor.opacity(0.1))
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundColor(type.accentColor)
                        }
                        .scaleEffect(isTargeted ? 1.1 : 1)
                        .animation(.spring(response: 0.3), value: isTargeted)
                        
                        VStack(spacing: 4) {
                            Text("Drop \(type.label.lowercased()) design here")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("or press ⌘V to paste")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        
                        // Upload Button
                        Button(action: {
                            openFilePicker()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.doc")
                                    .font(.system(size: 12))
                                Text("Upload Image")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(type.accentColor)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        
                        Text("PNG, JPG, TIFF")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
            }
            .frame(height: dropZoneHeight)
            .contentShape(Rectangle())
            .focusable()
            .focused($isFocused)
            .onTapGesture {
                onSelect()
                isFocused = true
            }
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovering = hovering
                }
            }
            .onDrop(of: [.png, .jpeg, .tiff, .image, .fileURL], isTargeted: $isTargeted) { providers in
                handleDrop(providers: providers)
            }
            .onPasteCommand(of: [.png, .jpeg, .tiff, .image, .fileURL]) { providers in
                _ = handleDrop(providers: providers)
            }
            .onChange(of: isSelected) { _, newValue in
                if newValue {
                    isFocused = true
                }
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        // Try loading as file URL first
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil),
                      let image = NSImage(contentsOf: url) else {
                    return
                }
                
                DispatchQueue.main.async {
                    onDrop(image)
                }
            }
            return true
        }
        
        // Try loading as image data (PNG, JPEG, TIFF)
        let imageTypes = [UTType.png.identifier, UTType.jpeg.identifier, UTType.tiff.identifier, UTType.image.identifier]
        
        for imageType in imageTypes {
            if provider.hasItemConformingToTypeIdentifier(imageType) {
                provider.loadDataRepresentation(forTypeIdentifier: imageType) { data, error in
                    guard let data = data, let image = NSImage(data: data) else { return }
                    
                    DispatchQueue.main.async {
                        onDrop(image)
                    }
                }
                return true
            }
        }
        
        return false
    }
    
    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp, .gif]
        panel.message = "Select an image file"
        
        if panel.runModal() == .OK, let url = panel.url, let image = NSImage(contentsOf: url) {
            onDrop(image)
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        ImageDropZone(type: .before, image: nil, onDrop: { _ in }, isSelected: false, onSelect: {})
        ImageDropZone(type: .after, image: nil, onDrop: { _ in }, isSelected: true, onSelect: {})
    }
    .padding(40)
    .background(Color(hex: "0a0a0b"))
}



