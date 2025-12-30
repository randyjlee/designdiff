import SwiftUI
import Sparkle

@main
struct DesignDiffApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var updateManager = UpdateManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 1200, minHeight: 700)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            
            // Add "Check for Updates" to the app menu
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updateManager.updater)
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

// MARK: - Update Manager

class UpdateManager: ObservableObject {
    private let updaterController: SPUStandardUpdaterController
    
    init() {
        // Initialize Sparkle updater
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }
    
    /// Check for updates manually
    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
    
    /// Get the updater for menu integration
    var updater: SPUUpdater {
        updaterController.updater
    }
    
    /// Check if automatic update checking is enabled
    var automaticallyChecksForUpdates: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set { updaterController.updater.automaticallyChecksForUpdates = newValue }
    }
}

// MARK: - Check for Updates View

struct CheckForUpdatesView: View {
    let updater: SPUUpdater
    
    var body: some View {
        Button("Check for Updates...") {
            updater.checkForUpdates()
        }
    }
}



