import SwiftUI

enum ResultTab: String, CaseIterable {
    case summary = "Summary"
    case tasks = "Tasks"
    case slack = "Slack"
    case linear = "Linear"
    
    var icon: String {
        switch self {
        case .summary: return "doc.text"
        case .tasks: return "checklist"
        case .slack: return "number"
        case .linear: return "square.and.pencil"
        }
    }
}

struct ResultsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: ResultTab = .summary
    @State private var copiedId: String?
    
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
                        case .summary:
                            SummaryTabView(copiedId: $copiedId)
                        case .tasks:
                            TasksTabView(copiedId: $copiedId)
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
                    Button(action: exportDiffPNG) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.doc")
                            Text("Diff PNG")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: exportJSON) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.doc")
                            Text("Export JSON")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color(hex: "ff6b35"))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(16)
                .background(Color.white.opacity(0.03))
            }
            .frame(width: 450)
        }
    }
    
    private func exportDiffPNG() {
        guard let url = appState.exportDiffImage() else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.png]
        savePanel.nameFieldStringValue = "design-diff.png"
        
        if savePanel.runModal() == .OK, let destination = savePanel.url {
            try? FileManager.default.copyItem(at: url, to: destination)
        }
    }
    
    private func exportJSON() {
        guard let url = appState.exportJSON() else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.nameFieldStringValue = "design-diff-analysis.json"
        
        if savePanel.runModal() == .OK, let destination = savePanel.url {
            try? FileManager.default.copyItem(at: url, to: destination)
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

// MARK: - Summary Tab

struct SummaryTabView: View {
    @EnvironmentObject var appState: AppState
    @Binding var copiedId: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Change Summary")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                CopyButton(
                    text: appState.analysisResult?.changeSummary.map { "• \($0)" }.joined(separator: "\n") ?? "",
                    id: "summary",
                    copiedId: $copiedId
                )
            }
            
            if let summary = appState.analysisResult?.changeSummary {
                VStack(spacing: 8) {
                    ForEach(Array(summary.enumerated()), id: \.offset) { index, change in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(Color(hex: "ff6b35"))
                                .frame(width: 16, height: 16)
                                .padding(.top, 2)
                            
                            Text(change)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.85))
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }
}

// MARK: - Spec Tab

struct SpecTabView: View {
    @EnvironmentObject var appState: AppState
    @Binding var copiedId: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Developer Spec")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                CopyButton(
                    text: formatDevSpec(),
                    id: "spec",
                    copiedId: $copiedId
                )
            }
            
            if let spec = appState.analysisResult?.developerSpec {
                // Components
                ForEach(spec.components) { component in
                    ComponentSpecCard(component: component)
                }
                
                // Layout
                if !spec.layout.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "2dd4bf"))
                            
                            Text("Layout")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.03))
                        
                        VStack(spacing: 4) {
                            ForEach(spec.layout) { item in
                                HStack {
                                    Text(item.property)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.5))
                                        .frame(width: 150, alignment: .leading)
                                    
                                    Text(item.value)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(Color(hex: "2dd4bf"))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
            }
        }
    }
    
    private func formatDevSpec() -> String {
        guard let spec = appState.analysisResult?.developerSpec else { return "" }
        
        var output = ""
        
        for comp in spec.components {
            output += "## \(comp.name)\n"
            for (key, value) in comp.properties.sorted(by: { $0.key < $1.key }) {
                output += "- \(key): \(value)\n"
            }
            output += "\n"
        }
        
        if !spec.layout.isEmpty {
            output += "## Layout\n"
            for item in spec.layout {
                output += "- \(item.property): \(item.value)\n"
            }
        }
        
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct ComponentSpecCard: View {
    let component: ComponentSpec
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "cube")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "ff6b35"))
                
                Text(component.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.03))
            
            VStack(spacing: 4) {
                ForEach(component.properties.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack {
                        Text(key)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 150, alignment: .leading)
                        
                        Text(value)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(Color(hex: "2dd4bf"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color.white.opacity(0.02))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Tasks Tab

struct TasksTabView: View {
    @EnvironmentObject var appState: AppState
    @Binding var copiedId: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Actionable Tasks")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                CopyButton(
                    text: appState.analysisResult?.actionableTasks.map { "- [ ] \($0)" }.joined(separator: "\n") ?? "",
                    id: "tasks",
                    copiedId: $copiedId
                )
            }
            
            if let tasks = appState.analysisResult?.actionableTasks {
                VStack(spacing: 8) {
                    ForEach(Array(tasks.enumerated()), id: \.offset) { _, task in
                        HStack(alignment: .top, spacing: 12) {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                .frame(width: 18, height: 18)
                                .padding(.top, 1)
                            
                            Text(task)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.85))
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(10)
                    }
                }
            }
        }
    }
}

// MARK: - Slack Tab

struct SlackTabView: View {
    @EnvironmentObject var appState: AppState
    @Binding var copiedId: String?
    
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
                    text: appState.analysisResult?.slackFormat ?? "",
                    id: "slack",
                    label: "Copy for Slack",
                    copiedId: $copiedId
                )
            }
            
            if let slackFormat = appState.analysisResult?.slackFormat {
                Text(slackFormat)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
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
}

// MARK: - Linear Tab

struct LinearTabView: View {
    @EnvironmentObject var appState: AppState
    @Binding var copiedId: String?
    
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
                    text: appState.analysisResult?.linearFormat ?? "",
                    id: "linear",
                    label: "Copy for Linear",
                    copiedId: $copiedId
                )
            }
            
            if let linearFormat = appState.analysisResult?.linearFormat {
                Text(linearFormat)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
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

#Preview {
    ResultsView()
        .environmentObject({
            let state = AppState()
            state.analysisResult = AnalysisResult.mock
            return state
        }())
        .frame(width: 1200, height: 800)
        .background(Color(hex: "0a0a0b"))
}



