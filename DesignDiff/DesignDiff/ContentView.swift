import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "0a0a0b"),
                    Color(hex: "111113"),
                    Color(hex: "0a0a0b")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Gradient orbs
            GeometryReader { geo in
                Circle()
                    .fill(Color(hex: "2dd4bf").opacity(0.1))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: geo.size.width - 200, y: geo.size.height / 2)
            }
            
            VStack(spacing: 0) {
                // Header
                HeaderView()
                
                Divider()
                    .background(Color.white.opacity(0.1))
                
                // Main Content
                if case .complete = appState.status, appState.analysisResult != nil {
                    ResultsView()
                } else {
                    UploadView()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Header View

struct HeaderView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 16) {
            // Logo
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "ff6b35"), Color(hex: "e55a2b")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "square.3.layers.3d")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text("Design")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                +
                Text("Diff")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: "ff6b35"))
            }
            
            Spacer()
            
            // Status indicator
            if appState.isProcessing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "ff6b35")))
                    
                    Text(appState.status == .diffing ? "Generating diff..." : "Analyzing...")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.05))
                .cornerRadius(20)
            }
            
            // New Analysis button (when showing results)
            if case .complete = appState.status {
                Button(action: { appState.clearAll() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("New Analysis")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            // Settings
            SettingsLink {
                Image(systemName: "gearshape")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}

// MARK: - Upload View

struct UploadView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedZone: DropZoneType? = nil
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Description
            VStack(spacing: 8) {
                Text("Upload before & after designs")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Get AI-powered change detection, developer specs, and team-ready summaries")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            // Upload zones
            HStack(spacing: 24) {
                ImageDropZone(
                    type: .before,
                    image: appState.beforeImage,
                    onDrop: { appState.setBeforeImage($0) },
                    isSelected: selectedZone == .before,
                    onSelect: { selectedZone = .before }
                )
                
                ImageDropZone(
                    type: .after,
                    image: appState.afterImage,
                    onDrop: { appState.setAfterImage($0) },
                    isSelected: selectedZone == .after,
                    onSelect: { selectedZone = .after }
                )
            }
            .padding(.horizontal, 40)
            
            // Error message
            if case .error(let message) = appState.status {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "ef4444"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: "ef4444").opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Analyze button
            Button(action: {
                Task { await appState.analyze() }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                    Text("Analyze Changes")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(width: 200, height: 50)
                .background(
                    Group {
                        if appState.isReadyToAnalyze {
                            LinearGradient(
                                colors: [Color(hex: "ff6b35"), Color(hex: "e55a2b")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Color.white.opacity(0.1)
                        }
                    }
                )
                .cornerRadius(14)
                .shadow(color: appState.isReadyToAnalyze ? Color(hex: "ff6b35").opacity(0.3) : .clear, radius: 20, y: 10)
            }
            .buttonStyle(.plain)
            .disabled(!appState.isReadyToAnalyze || appState.isProcessing)
            .opacity(appState.isReadyToAnalyze ? 1 : 0.5)
            
            // Instructions
            if appState.beforeImage == nil && appState.afterImage == nil {
                VStack(spacing: 4) {
                    Text("Drag & drop, click Upload, or press ⌘V to paste")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))
                    Text("Supports PNG, JPG, TIFF and other image formats")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            
            Spacer()
        }
    }
    
    private func pasteToSelectedZone(_ image: NSImage) {
        switch selectedZone {
        case .before:
            appState.setBeforeImage(image)
        case .after:
            appState.setAfterImage(image)
        case nil:
            // No selection - default behavior: fill before first, then after
            if appState.beforeImage == nil {
                appState.setBeforeImage(image)
            } else {
                appState.setAfterImage(image)
            }
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .frame(width: 1200, height: 800)
}



