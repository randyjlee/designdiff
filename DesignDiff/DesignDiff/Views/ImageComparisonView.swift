import SwiftUI

struct ImageComparisonView: View {
    @EnvironmentObject var appState: AppState
    private let annotationPositions: [CGPoint] = [
        CGPoint(x: 0.2, y: 0.3),
        CGPoint(x: 0.65, y: 0.25),
        CGPoint(x: 0.4, y: 0.65),
        CGPoint(x: 0.75, y: 0.6)
    ]

    var body: some View {
        VStack(spacing: 0) {
            comparisonHeader
            HStack(alignment: .top, spacing: 16) {
                ComparisonFrame(title: "Before", image: appState.beforeImage)
                AfterComparisonFrame(
                    image: appState.afterImage,
                    annotations: appState.analysisResult?.changeSummary ?? [],
                    positions: annotationPositions
                )
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)

            if let summary = appState.analysisResult?.changeSummary, !summary.isEmpty {
                ChangeAnnotationPanel(entries: summary)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.top, 0)
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
        .padding(.vertical, 10)
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

struct ComparisonFrame: View {
    let title: String
    let image: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.black.opacity(0.3))
                    )
                if let image = image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(12)
                } else {
                    Text("No image")
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .frame(height: 540)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AfterComparisonFrame: View {
    let image: NSImage?
    let annotations: [String]
    let positions: [CGPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("After")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            GeometryReader { geometry in
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.black.opacity(0.3))
                        )
                    if let image = image {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(12)
                    }
                    ForEach(Array(annotations.enumerated()), id: \.offset) { index, _ in
                        if !positions.isEmpty {
                            let anchor = positions[index % positions.count]
                            let clampedX = min(max(anchor.x, 0.05), 0.95)
                            let clampedY = min(max(anchor.y, 0.05), 0.95)
                            AnnotationBadge(number: index + 1)
                                .position(
                                    x: geometry.size.width * clampedX,
                                    y: geometry.size.height * clampedY
                                )
                        }
                    }
                }
            }
            .frame(height: 540)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AnnotationBadge: View {
    let number: Int

    var body: some View {
        Text("\(number)")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 28, height: 28)
            .background(Color(hex: "ff6b35"))
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
    }
}

struct ChangeAnnotationPanel: View {
    let entries: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Visual change annotations")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "list.number")
                    .foregroundColor(Color(hex: "ff6b35"))
            }

            ForEach(Array(entries.enumerated()), id: \.offset) { index, change in
                HStack(alignment: .top, spacing: 8) {
                    Text("(\(index + 1))")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "ff6b35"))
                        .frame(width: 28, alignment: .trailing)

                    Text(change)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.vertical, 6)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    ImageComparisonView()
        .environmentObject(AppState())
        .frame(width: 600, height: 500)
        .background(Color(hex: "0a0a0b"))
}
