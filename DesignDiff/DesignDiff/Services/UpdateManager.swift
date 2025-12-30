//
//  UpdateManager.swift
//  DesignDiff
//
//  Auto-update manager using Sparkle framework
//

import Foundation
import Sparkle

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

