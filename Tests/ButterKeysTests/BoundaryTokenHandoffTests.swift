import Foundation
import Testing
@testable import ButterKeysCore

@Suite("Boundary token handoff")
struct BoundaryTokenHandoffTests {
    @Test("Completed word is passed as currentToken after space")
    func completedWordSurvivesBoundary() throws {
        final class Capture: @unchecked Sendable {
            let lock = NSLock()
            var token: String?
            var boundary: Character?
        }
        let capture = Capture()

        let processor = KeyboardEventProcessor(
            translator: KeyboardLayoutTranslator(),
            syntheticGuard: SyntheticEventGuard(),
            onCorrectionRequest: { request in
                capture.lock.lock()
                capture.token = request.currentToken
                capture.boundary = request.boundary
                capture.lock.unlock()
            }
        )

        let now = Date().timeIntervalSince1970
        for ch in ["s", "o", "e", "m"] {
            processor.enqueue(
                NormalizedKeyEvent(
                    keyCode: 0,
                    characters: ch,
                    modifiers: [],
                    timestamp: now,
                    isRepeat: false,
                    type: .keyDown
                )
            )
        }
        processor.enqueue(
            NormalizedKeyEvent(
                keyCode: 49,
                characters: " ",
                modifiers: [],
                timestamp: now,
                isRepeat: false,
                type: .keyDown
            )
        )

        // Processor work is async on its serial queue.
        let deadline = Date().addingTimeInterval(1)
        while Date() < deadline {
            capture.lock.lock()
            let token = capture.token
            capture.lock.unlock()
            if token != nil { break }
            Thread.sleep(forTimeInterval: 0.01)
        }

        capture.lock.lock()
        let token = capture.token
        let boundary = capture.boundary
        capture.lock.unlock()

        #expect(token == "soem")
        #expect(boundary == " ")
    }
}
