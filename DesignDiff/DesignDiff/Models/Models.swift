import Foundation
import AppKit

// MARK: - Analysis Result Models

struct ComponentSpec: Codable, Identifiable {
    var id: String { name }
    let name: String
    let properties: [String: String]
}

struct LayoutSpec: Codable, Identifiable {
    var id: String { property }
    let property: String
    let value: String
}

struct DeveloperSpec: Codable {
    let components: [ComponentSpec]
    let layout: [LayoutSpec]
}

struct AnalysisResult: Codable {
    let changeSummary: [String]
    let developerSpec: DeveloperSpec
    let actionableTasks: [String]
    let slackFormat: String
    let linearFormat: String
}

// MARK: - Diff Result

struct DiffResult {
    let diffImage: NSImage
    let diffPercentage: Double
    let changedPixels: Int
    let totalPixels: Int
}

// MARK: - App Status

enum AnalysisStatus: Equatable {
    case idle
    case diffing
    case analyzing
    case complete
    case error(String)
}

// MARK: - Mock Data

extension AnalysisResult {
    static var mock: AnalysisResult {
        AnalysisResult(
            changeSummary: [
                "Primary button height increased (44px → 48px)",
                "Button border radius changed (8px → 12px)",
                "Primary color updated (#2D6BFF → #1F5BFF)",
                "Card shadow increased for more elevation",
                "Header text weight changed (500 → 600)",
                "Section spacing increased (16px → 24px)",
                "Input field border color lightened"
            ],
            developerSpec: DeveloperSpec(
                components: [
                    ComponentSpec(
                        name: "Primary Button",
                        properties: [
                            "height": "48px",
                            "padding": "12px 24px",
                            "border-radius": "12px",
                            "background-color": "#1F5BFF",
                            "font-size": "16px",
                            "font-weight": "600",
                            "text-color": "#FFFFFF"
                        ]
                    ),
                    ComponentSpec(
                        name: "Card",
                        properties: [
                            "padding": "24px",
                            "border-radius": "16px",
                            "background-color": "#FFFFFF",
                            "box-shadow": "0 4px 24px rgba(0, 0, 0, 0.08)",
                            "border": "1px solid #EAEAEA"
                        ]
                    ),
                    ComponentSpec(
                        name: "Input Field",
                        properties: [
                            "height": "44px",
                            "padding": "12px 16px",
                            "border-radius": "8px",
                            "border": "1px solid #E5E5E5",
                            "font-size": "14px"
                        ]
                    )
                ],
                layout: [
                    LayoutSpec(property: "section-spacing", value: "24px"),
                    LayoutSpec(property: "card-gap", value: "16px"),
                    LayoutSpec(property: "container-padding", value: "32px"),
                    LayoutSpec(property: "form-field-gap", value: "12px")
                ]
            ),
            actionableTasks: [
                "Update PrimaryButton component height to 48px",
                "Change button border-radius to 12px in design tokens",
                "Update $primary-color variable to #1F5BFF",
                "Increase Card component shadow depth",
                "Update heading font-weight to 600",
                "Adjust section spacing from 16px to 24px",
                "Update input border color to #E5E5E5"
            ],
            slackFormat: """
            🎨 *Design Update Summary*
            
            *Visual Changes:*
            • Primary button height: 44px → 48px
            • Border radius updated: 8px → 12px  
            • Primary color: `#2D6BFF` → `#1F5BFF`
            • Card shadow increased
            • Section spacing: 16px → 24px
            
            *Action Items:*
            ☐ Update button tokens
            ☐ Adjust card shadow
            ☐ Update spacing variables
            
            _Full spec in thread_ 👇
            """,
            linearFormat: """
            ## Design Diff Analysis
            
            ### Summary
            Visual changes detected in the following areas:
            - Button styling (height, radius, color)
            - Card elevation
            - Layout spacing
            
            ### Tasks
            - [ ] Update PrimaryButton component height to 48px
            - [ ] Change button border-radius to 12px
            - [ ] Update primary color to #1F5BFF
            - [ ] Increase Card shadow
            - [ ] Adjust section spacing to 24px
            
            ### Developer Spec
            See attached JSON for complete specifications.
            """
        )
    }
}



