import SwiftUI

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
                HStack {
                    Spacer()
                    
                    Button(action: exportDiffPNG) {
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
