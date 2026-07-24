import Foundation
import Testing
@testable import ButterKeysCore

@Suite("Network isolation")
struct NetworkIsolationTests {
    @Test("Correction engine modules do not import networking frameworks")
    func noNetworkingImportsInEngineSources() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Sources/ButterKeysCore")

        let forbidden = ["import Network", "import NetworkExtension", "URLSession", "CFNetwork"]
        var offenders: [String] = []

        let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)!
        for case let file as URL in enumerator where file.pathExtension == "swift" {
            // Skip nothing — entire core must stay offline for typing data.
            let source = try String(contentsOf: file, encoding: .utf8)
            for token in forbidden where source.contains(token) {
                offenders.append("\(file.lastPathComponent): \(token)")
            }
        }

        #expect(offenders.isEmpty, "Found networking usage: \(offenders)")
    }
}
