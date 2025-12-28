import Foundation
import AppKit

class OpenAIService {
    
    enum OpenAIError: LocalizedError {
        case invalidAPIKey
        case networkError(String)
        case invalidResponse
        case parseError(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidAPIKey:
                return "Invalid or missing OpenAI API key. Please set it in Settings."
            case .networkError(let message):
                return "Network error: \(message)"
            case .invalidResponse:
                return "Invalid response from OpenAI"
            case .parseError(let message):
                return "Failed to parse response: \(message)"
            }
        }
    }
    
    private let systemPrompt = """
    You are a senior UI/UX designer and frontend developer expert. Your task is to analyze visual differences between two UI designs (before and after) and provide detailed, actionable specifications for developers.

    You will receive three images:
    1. BEFORE - The original design
    2. AFTER - The updated design  
    3. DIFF - A visual diff highlighting changed areas in red

    Analyze these images and provide a comprehensive report in the following JSON format:

    {
      "changeSummary": [
        "Brief, clear descriptions of each visual change (e.g., 'Button height increased from 44px to 48px')",
        "Include specific values when visible or inferable"
      ],
      "developerSpec": {
        "components": [
          {
            "name": "Component Name (e.g., Primary Button, Card, Header)",
            "properties": {
              "height": "48px",
              "padding": "16px 12px",
              "border-radius": "12px",
              "background-color": "#1F5BFF",
              "font-size": "16px",
              "font-weight": "600"
            }
          }
        ],
        "layout": [
          {"property": "section-spacing", "value": "24px"},
          {"property": "card-padding", "value": "20px"}
        ]
      },
      "actionableTasks": [
        "Update PrimaryButton component with new height and padding",
        "Change Card border-radius to 16px",
        "Update header text from 'Settings' to 'Account'"
      ],
      "slackFormat": "Markdown formatted summary suitable for Slack with emoji and clear sections",
      "linearFormat": "Clean markdown formatted for Linear issue comments with task checkboxes"
    }

    Guidelines:
    - Be specific with measurements (px, rem, hex colors)
    - Group related changes by component
    - Infer reasonable values when exact measurements aren't visible
    - Focus on actionable, implementation-ready specifications
    - Use semantic component names developers would recognize
    - Include both structural (layout, spacing) and visual (color, typography) changes
    - For colors, provide hex codes when possible
    - For spacing, estimate based on visual proportions

    Return ONLY valid JSON, no additional text.
    """
    
    func analyzeImages(before: NSImage, after: NSImage, diff: NSImage, apiKey: String) async throws -> AnalysisResult {
        // If no API key, return mock data
        guard !apiKey.isEmpty else {
            // Simulate network delay
            try await Task.sleep(nanoseconds: 1_500_000_000)
            return AnalysisResult.mock
        }
        
        // Convert images to base64
        guard let beforeBase64 = imageToBase64(before),
              let afterBase64 = imageToBase64(after),
              let diffBase64 = imageToBase64(diff) else {
            throw OpenAIError.invalidResponse
        }
        
        // Build request
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "Please analyze the visual differences between these UI designs. The first image is BEFORE, the second is AFTER, and the third is the DIFF highlighting changes."
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/png;base64,\(beforeBase64)",
                                "detail": "high"
                            ]
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/png;base64,\(afterBase64)",
                                "detail": "high"
                            ]
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/png;base64,\(diffBase64)",
                                "detail": "high"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 4096,
            "temperature": 0.3
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIError.networkError(message)
            }
            throw OpenAIError.networkError("HTTP \(httpResponse.statusCode)")
        }
        
        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        
        // Extract JSON from response (handle potential markdown code blocks)
        var jsonString = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code blocks if present
        if let range = jsonString.range(of: "```json") {
            jsonString = String(jsonString[range.upperBound...])
        } else if let range = jsonString.range(of: "```") {
            jsonString = String(jsonString[range.upperBound...])
        }
        
        if let range = jsonString.range(of: "```", options: .backwards) {
            jsonString = String(jsonString[..<range.lowerBound])
        }
        
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Parse JSON
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw OpenAIError.parseError("Invalid JSON string")
        }
        
        do {
            let analysis = try JSONDecoder().decode(AnalysisResult.self, from: jsonData)
            return analysis
        } catch {
            throw OpenAIError.parseError(error.localizedDescription)
        }
    }
    
    private func imageToBase64(_ image: NSImage) -> String? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return nil
        }
        return pngData.base64EncodedString()
    }
}



