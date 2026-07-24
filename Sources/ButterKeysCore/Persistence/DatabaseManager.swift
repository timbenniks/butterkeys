import Foundation
import GRDB

public final class DatabaseManager: Sendable {
    public static let shared: DatabaseManager = {
        do {
            return try DatabaseManager()
        } catch {
            fatalError("Failed to open ButterKeys database: \(error)")
        }
    }()

    public let dbQueue: DatabaseQueue

    public init(path: String? = nil) throws {
        let databaseURL = path.map { URL(fileURLWithPath: $0) } ?? Self.defaultDatabaseURL
        let directoryURL = databaseURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        dbQueue = try DatabaseQueue(path: databaseURL.path)
        try DatabaseMigrator.migrate(dbQueue)
        try SeedDefaults.seedIfNeeded(dbQueue: dbQueue)
    }

    public static var defaultDatabaseURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport
            .appendingPathComponent("ButterKeys", isDirectory: true)
            .appendingPathComponent("butterkeys.sqlite")
    }
}
