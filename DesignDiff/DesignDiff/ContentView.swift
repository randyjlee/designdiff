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
                // Header (minimal drag area)
                HeaderView()
                
                // Main Content
                if appState.isProcessing {
                    LoadingView()
                        .transition(.opacity)
                } else if case .complete = appState.status, appState.analysisResult != nil {
                    ResultsView()
                        .transition(.opacity)
                } else {
                    UploadView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: appState.status)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Header View (Minimal - just for window drag area)

struct HeaderView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack {
            Spacer()
            
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
        }
        .padding(.leading, 80)  // Space for window controls
        .padding(.trailing, 24)
        .frame(height: 28)
    }
}

// MARK: - Upload View

struct UploadView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedZone: DropZoneType? = nil
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Logo and Description
            VStack(spacing: 16) {
                // DesignDiff Logo
                HStack(spacing: 0) {
                    Text("Design")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    +
                    Text("Diff")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(Color(hex: "ff6b35"))
                }
                
                // Description
                VStack(spacing: 8) {
                    Text("Upload before & after designs")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("Get AI-powered change detection, developer specs, and team-ready summaries")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
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

// MARK: - Loading View

struct LoadingView: View {
    @EnvironmentObject var appState: AppState
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Animated loading icon
            ZStack {
                // Outer ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "ff6b35").opacity(0.3),
                                Color(hex: "2dd4bf").opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 120, height: 120)
                
                // Spinning gradient ring
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: "ff6b35"),
                                Color(hex: "2dd4bf")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear {
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    }
                
                // Center icon
                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "ff6b35"), Color(hex: "2dd4bf")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            pulseScale = 1.2
                        }
                    }
            }
            .shadow(color: Color(hex: "ff6b35").opacity(0.3), radius: 30)
            
            // Loading text
            VStack(spacing: 12) {
                Text(loadingTitle)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(loadingSubtitle)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Progress steps
            HStack(spacing: 32) {
                LoadingStep(
                    icon: "photo.stack",
                    title: "Generating Diff",
                    isActive: appState.status == .diffing,
                    isComplete: appState.status == .analyzing || appState.status == .complete
                )
                
                LoadingStep(
                    icon: "brain",
                    title: "AI Analysis",
                    isActive: appState.status == .analyzing,
                    isComplete: appState.status == .complete
                )
            }
            .padding(.horizontal, 60)
            
            // Cancel button
            Button(action: {
                appState.cancelAnalysis()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.6))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .padding(.top, 20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var loadingTitle: String {
        switch appState.status {
        case .diffing:
            return "Generating visual diff..."
        case .analyzing:
            return "AI is analyzing changes..."
        default:
            return "Processing..."
        }
    }
    
    private var loadingSubtitle: String {
        switch appState.status {
        case .diffing:
            return "Comparing before and after images pixel by pixel"
        case .analyzing:
            return "Identifying changes, extracting specs, and generating summaries"
        default:
            return "Please wait while we process your images"
        }
    }
}

// MARK: - Loading Step

struct LoadingStep: View {
    let icon: String
    let title: String
    let isActive: Bool
    let isComplete: Bool
    
    @State private var checkmarkScale: CGFloat = 0.5
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                // Background circle
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 64, height: 64)
                
                if isComplete {
                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(Color(hex: "2dd4bf"))
                        .scaleEffect(checkmarkScale)
                        .onAppear {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                checkmarkScale = 1.0
                            }
                        }
                } else {
                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(iconColor)
                }
            }
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(textColor)
        }
    }
    
    private var backgroundColor: Color {
        if isComplete {
            return Color(hex: "2dd4bf").opacity(0.15)
        } else if isActive {
            return Color(hex: "ff6b35").opacity(0.15)
        } else {
            return Color.white.opacity(0.05)
        }
    }
    
    private var iconColor: Color {
        if isActive {
            return Color(hex: "ff6b35")
        } else {
            return Color.white.opacity(0.3)
        }
    }
    
    private var textColor: Color {
        if isComplete || isActive {
            return .white.opacity(0.9)
        } else {
            return .white.opacity(0.4)
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



