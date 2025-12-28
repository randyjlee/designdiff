import Foundation
import AppKit

class OpenAIService {
    
    // MARK: - API Key Configuration
    private let apiKey = "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"
    
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

    CRITICAL: Look for ALL types of changes, including:
    - LOGO changes (logo text removed, logo icon changed, logo simplified)
    - HEADER/NAVIGATION changes (nav bar items added/removed/modified)
    - Text content changes (added, removed, or modified text)
    - Element size changes (width increased/decreased, height increased/decreased)
    - Spacing changes (padding, margin, gaps between elements increased or decreased)
    - Position changes (elements moved up, down, left, right)
    - Layout changes (elements rearranged or reflowed)
    - Color changes (background, text, borders)
    - Typography changes (font size, weight, style)
    - Visual style changes (shadows, borders, radius)
    - Elements added or removed entirely
    - Icons changed or simplified
    
    START FROM THE TOP: Always analyze from top to bottom of the screen:
    1. Status bar
    2. Navigation/Header bar (LOGO, menu items, buttons)
    3. Main content area
    4. Footer/Bottom area

    IMPORTANT: 
    - Create a SEPARATE annotation for EACH distinct change
    - Do NOT group multiple changes into one annotation
    - ONLY report REAL changes that you can clearly see - do NOT guess or assume changes
    - Be SPECIFIC and ACCURATE in your descriptions:
      * If something increased, say "increased" not "changed"
      * If something decreased, say "decreased" or "reduced"
      * If something was removed, say "removed" not "changed"
      * If height decreased, say "Height decreased" not "Height increased"
      * If image/video size decreased, say "Image/video height reduced" or "Image size decreased"
      * Always compare BEFORE vs AFTER accurately
    
    DO NOT REPORT:
    - Changes that don't actually exist
    - Spacing changes unless there is CLEAR visible difference
    - Assumed changes based on other changes
    
    FOR SIZE CHANGES:
    - If an image or video section appears smaller, report it as "Image/video section height reduced" or "Element size decreased"
    - If there is new empty space below an element, check if the element itself got smaller (not just spacing increased)

    Analyze these images and provide a comprehensive report in the following JSON format:

    {
      "changeAnnotations": [
        {
          "description": "Brief, clear description of ONE specific change (e.g., 'Removed introductory paragraph text', 'Increased image size by 50%', 'Added 40px spacing below heading')",
          "x": 0.5,
          "y": 0.85
        }
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

    IMPORTANT for changeAnnotations:
    - Create ONE annotation per change - be thorough and detailed
    - Look carefully at EVERY area of the design, even if changes seem subtle
    - "x" and "y" are coordinates as percentages (0.0 to 1.0) indicating WHERE the change is located in the AFTER image
    - x: 0.0 = left edge, 0.5 = center, 1.0 = right edge
    - y: 0.0 = top edge, 0.5 = middle, 1.0 = bottom edge
    
    POSITIONING STRATEGY (VERY IMPORTANT):
    
    The coordinate system is based on the ENTIRE image frame (0.0 to 1.0):
    - x: 0.0 = left edge of frame, 1.0 = right edge of frame
    - y: 0.0 = top edge of frame, 1.0 = bottom edge of frame
    
    MARKER PLACEMENT RULES:
    1. Place markers at the LEFT EDGE of the changed element/area
    2. x coordinate = left edge of the phone screen content (approximately 0.28-0.32)
    3. y coordinate = VERTICAL CENTER of the changed element or area
    
    For mobile app screenshots typically centered in the frame:
    - The phone screen usually spans from x ≈ 0.30 to x ≈ 0.70
    - ALL markers should be placed at x ≈ 0.29-0.31 (left edge of content)
    
    Y-COORDINATE EXAMPLES for a centered mobile screenshot:
    - Navigation bar area: y ≈ 0.18-0.22
    - Below navigation (if text removed): y ≈ 0.42-0.48
    - Main image area: y ≈ 0.55-0.60
    - Empty space / spacing area: y ≈ 0.75-0.80
    - Button at bottom: y ≈ 0.92-0.95
    
    CRITICAL:
    - Place marker at the VERTICAL CENTER of where the change occurred
    - All markers should be aligned on the LEFT side (x ≈ 0.30)
    - If text was removed, place marker where the empty space now is
    - If spacing increased, place marker in the CENTER of the new spacing

    Guidelines:
    - Be specific with measurements (px, rem, hex colors)
    - Identify EVERY visible change, no matter how small
    - Look for negative space changes (spacing, padding, margins)
    - Note when elements are removed or added
    - Infer reasonable values when exact measurements aren't visible
    - Focus on actionable, implementation-ready specifications
    - Use semantic component names developers would recognize
    - Include both structural (layout, spacing) and visual (color, typography) changes
    - For colors, provide hex codes when possible
    - For spacing, estimate based on visual proportions

    Return ONLY valid JSON, no additional text.
    """
    
    func analyzeImages(before: NSImage, after: NSImage, diff: NSImage) async throws -> AnalysisResult {
        // If API key is not set, return mock data
        guard apiKey != "YOUR_OPENAI_API_KEY_HERE" && !apiKey.isEmpty else {
            // Simulate network delay for demo
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
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": """
\(systemPrompt)

Please analyze ALL visual differences between these UI designs. The first image is BEFORE, the second is AFTER, and the third is the DIFF highlighting changes in red. Look carefully at EVERY element: text content, element sizes, spacing between elements, positioning, colors, and any added or removed elements. Create a SEPARATE annotation for EACH distinct change you find. Be thorough and detailed.

REMEMBER: Place annotation markers at the EDGES in a zigzag pattern (odd numbers on left, even numbers on right), NOT in the center!
"""
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
            "max_tokens": 6000,
            "temperature": 0.1
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




