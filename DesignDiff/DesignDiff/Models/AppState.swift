import Foundation
import AppKit
import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    // MARK: - Published Properties
    
    @Published var beforeImage: NSImage?
    @Published var afterImage: NSImage?
    @Published var diffResult: DiffResult?
    @Published var analysisResult: AnalysisResult?
    @Published var status: AnalysisStatus = .idle
    
    // MARK: - Settings
    
    @AppStorage("openAIAPIKey") var apiKey: String = ""
    
    // MARK: - Services
    
    private let diffEngine = ImageDiffEngine()
    private let openAIService = OpenAIService()
    
    // MARK: - Computed Properties
    
    var isReadyToAnalyze: Bool {
        beforeImage != nil && afterImage != nil && status == .idle
    }
    
    var isProcessing: Bool {
        status == .diffing || status == .analyzing
    }
    
    // MARK: - Actions
    
    func setBeforeImage(_ image: NSImage?) {
        beforeImage = image
        reset()
    }
    
    func setAfterImage(_ image: NSImage?) {
        afterImage = image
        reset()
    }
    
    func reset() {
        diffResult = nil
        analysisResult = nil
        status = .idle
    }
    
    func clearAll() {
        beforeImage = nil
        afterImage = nil
        reset()
    }
    
    func pasteImageFromClipboard() {
        guard let image = getImageFromClipboard() else {
            return
        }
        
        // Smart placement: fill before first, then after
        if beforeImage == nil {
            setBeforeImage(image)
        } else if afterImage == nil {
            setAfterImage(image)
        } else {
            // Both filled, replace after
            setAfterImage(image)
        }
    }
    
    private func getImageFromClipboard() -> NSImage? {
        let pasteboard = NSPasteboard.general
        
        // Try different image types
        if let image = NSImage(pasteboard: pasteboard) {
            return image
        }
        
        // Try file URL (for copied files)
        if let url = pasteboard.readObjects(forClasses: [NSURL.self], options: nil)?.first as? URL {
            return NSImage(contentsOf: url)
        }
        
        return nil
    }
    
    func analyze() async {
        guard let before = beforeImage, let after = afterImage else {
            status = .error("Please upload both before and after images")
            return
        }
        
        status = .diffing
        
        do {
            // Step 1: Generate visual diff
            let diff = try await diffEngine.generateDiff(before: before, after: after)
            diffResult = diff
            
            status = .analyzing
            
            // Step 2: AI Analysis
            let analysis = try await openAIService.analyzeImages(
                before: before,
                after: after,
                diff: diff.diffImage,
                apiKey: apiKey
            )
            
            analysisResult = analysis
            status = .complete
            
        } catch {
            status = .error(error.localizedDescription)
        }
    }
    
    // MARK: - Export Functions
    
    func exportJSON() -> URL? {
        guard let analysis = analysisResult else { return nil }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let data = try encoder.encode(analysis)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("design-diff-analysis.json")
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to export JSON: \(error)")
            return nil
        }
    }
    
    func exportDiffImage() -> URL? {
        guard let diffImage = diffResult?.diffImage else { return nil }
        
        guard let tiffData = diffImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("design-diff.png")
        
        do {
            try pngData.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to export diff image: \(error)")
            return nil
        }
    }
}



