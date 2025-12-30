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
    
    // Editable annotations (user can modify these)
    @Published var editableAnnotations: [EditableAnnotation] = []
    @Published var selectedAnnotationId: UUID?
    
    // Demo version - Daily usage limit
    @Published var showLimitAlert: Bool = false
    @AppStorage("dailyAnalysisCount") private var dailyAnalysisCount: Int = 0
    @AppStorage("lastAnalysisDate") private var lastAnalysisDate: String = ""
    
    // MARK: - Constants
    
    private let dailyAnalysisLimit = 5
    
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
        editableAnnotations = []
        selectedAnnotationId = nil
        status = .idle
    }
    
    func clearAll() {
        beforeImage = nil
        afterImage = nil
        reset()
    }
    
    func cancelAnalysis() {
        // Reset status to idle without clearing images
        diffResult = nil
        analysisResult = nil
        editableAnnotations = []
        selectedAnnotationId = nil
        status = .idle
    }
    
    // MARK: - Annotation Management
    
    func initializeEditableAnnotations() {
        guard let result = analysisResult else { return }
        editableAnnotations = result.changeAnnotations.map { EditableAnnotation(from: $0) }
    }
    
    func updateAnnotationPosition(id: UUID, x: Double, y: Double) {
        if let index = editableAnnotations.firstIndex(where: { $0.id == id }) {
            editableAnnotations[index].x = min(max(x, 0.05), 0.95)
            editableAnnotations[index].y = min(max(y, 0.05), 0.95)
        }
    }
    
    func updateAnnotationDescription(id: UUID, description: String) {
        if let index = editableAnnotations.firstIndex(where: { $0.id == id }) {
            editableAnnotations[index].description = description
        }
    }
    
    func addAnnotation(at x: Double, y: Double) {
        let newAnnotation = EditableAnnotation(
            description: "New annotation",
            x: min(max(x, 0.05), 0.95),
            y: min(max(y, 0.05), 0.95)
        )
        editableAnnotations.append(newAnnotation)
        selectedAnnotationId = newAnnotation.id
    }
    
    func deleteAnnotation(id: UUID) {
        editableAnnotations.removeAll { $0.id == id }
        if selectedAnnotationId == id {
            selectedAnnotationId = nil
        }
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
    
    // MARK: - Daily Limit Management
    
    private func getTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func resetCountIfNewDay() {
        let today = getTodayString()
        if lastAnalysisDate != today {
            dailyAnalysisCount = 0
            lastAnalysisDate = today
        }
    }
    
    private func canAnalyze() -> Bool {
        resetCountIfNewDay()
        return dailyAnalysisCount < dailyAnalysisLimit
    }
    
    private func incrementAnalysisCount() {
        resetCountIfNewDay()
        dailyAnalysisCount += 1
    }
    
    var remainingAnalyses: Int {
        resetCountIfNewDay()
        return max(0, dailyAnalysisLimit - dailyAnalysisCount)
    }
    
    func analyze() async {
        guard let before = beforeImage, let after = afterImage else {
            status = .error("Please upload both before and after images")
            return
        }
        
        // Check daily limit
        if !canAnalyze() {
            showLimitAlert = true
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
                diff: diff.diffImage
            )
            
            analysisResult = analysis
            initializeEditableAnnotations()
            
            // Increment count on successful analysis
            incrementAnalysisCount()
            
            status = .complete
            
        } catch {
            status = .error(error.localizedDescription)
        }
    }
    
    // MARK: - Export Functions
    
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



