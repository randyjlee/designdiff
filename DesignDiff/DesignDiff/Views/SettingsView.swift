import SwiftUI

struct SettingsView: View {
    @AppStorage("openAIAPIKey") private var apiKey: String = ""
    @State private var showAPIKey: Bool = false
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("OpenAI API Key")
                        .font(.system(size: 13, weight: .medium))
                    
                    HStack {
                        Group {
                            if showAPIKey {
                                TextField("sk-...", text: $apiKey)
                            } else {
                                SecureField("sk-...", text: $apiKey)
                            }
                        }
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 13, design: .monospaced))
                        
                        Button(action: { showAPIKey.toggle() }) {
                            Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text("Get your API key at [platform.openai.com](https://platform.openai.com/api-keys)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    if apiKey.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 11))
                            Text("Without an API key, the app will use demo data")
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.orange)
                        .padding(.top, 4)
                    }
                }
            } header: {
                Text("API Configuration")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("About DesignDiff")
                        .font(.system(size: 13, weight: .medium))
                    
                    Text("AI-powered visual design diff tool for seamless designer-developer handoff.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        FeatureRow(icon: "photo.stack", text: "Compare before & after PNG designs")
                        FeatureRow(icon: "sparkles", text: "AI-powered change detection")
                        FeatureRow(icon: "doc.text", text: "Developer-ready specifications")
                        FeatureRow(icon: "square.and.arrow.up", text: "Export to Slack, Linear, JSON")
                    }
                }
            } header: {
                Text("Information")
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 380)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "ff6b35"))
                .frame(width: 16)
            
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView()
}



