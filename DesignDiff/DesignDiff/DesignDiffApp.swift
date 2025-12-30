import SwiftUI

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

// Check for Updates menu item
struct CheckForUpdatesView: View {
    let updater: SPUUpdater
    
    var body: some View {
        Button("Check for Updates...") {
            updater.checkForUpdates()
        }
    }
}



