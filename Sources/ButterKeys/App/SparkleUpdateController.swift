import AppKit
import Foundation
import Sparkle

/// Owns the Sparkle updater. Update checks never receive typing data.
@MainActor
final class SparkleUpdateController: NSObject {
    static let shared = SparkleUpdateController()

    let controller: SPUStandardUpdaterController

    private override init() {
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        super.init()
    }

    var canCheckForUpdates: Bool {
        controller.updater.canCheckForUpdates
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
