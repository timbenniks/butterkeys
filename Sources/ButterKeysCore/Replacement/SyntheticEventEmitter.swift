import Carbon
import CoreGraphics
import Foundation

public struct SyntheticEventEmitter: Sendable {
    private let syntheticGuard: SyntheticEventGuard
    private let interEventDelayNanoseconds: UInt64

    public init(
        syntheticGuard: SyntheticEventGuard,
        interEventDelayNanoseconds: UInt64 = 1_000_000
    ) {
        self.syntheticGuard = syntheticGuard
        self.interEventDelayNanoseconds = interEventDelayNanoseconds
    }

    @discardableResult
    public func emitBackspaces(count: Int) -> Bool {
        guard count > 0 else { return true }

        let generation = syntheticGuard.nextGeneration()
        let source = CGEventSource(stateID: .hidSystemState)

        for _ in 0..<count {
            guard postKey(source: source, virtualKey: CGKeyCode(kVK_Delete), generation: generation) else {
                return false
            }
            pauseBetweenEvents()
        }
        return true
    }

    @discardableResult
    public func emitUnicodeString(_ text: String) -> Bool {
        guard !text.isEmpty else { return true }

        let generation = syntheticGuard.nextGeneration()
        let source = CGEventSource(stateID: .hidSystemState)
        let utf16 = Array(text.utf16)

        guard postUnicode(source: source, utf16: utf16, generation: generation) else {
            return false
        }
        return true
    }

    @discardableResult
    public func emitReplacement(original: String, replacement: String, boundary: Character?) -> Bool {
        let deleteCount = original.count + (boundary != nil ? 1 : 0)
        guard emitBackspaces(count: deleteCount) else { return false }

        var insert = replacement
        if let boundary {
            insert.append(boundary)
        }
        return emitUnicodeString(insert)
    }

    private func postKey(source: CGEventSource?, virtualKey: CGKeyCode, generation: UInt64) -> Bool {
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: false) else {
            return false
        }

        let timestamp = markSynthetic(generation: generation)
        keyDown.timestamp = timestamp
        keyUp.timestamp = timestamp

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }

    private func postUnicode(source: CGEventSource?, utf16: [UniChar], generation: UInt64) -> Bool {
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
            return false
        }

        keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
        keyUp.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)

        let timestamp = markSynthetic(generation: generation)
        keyDown.timestamp = timestamp
        keyUp.timestamp = timestamp

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }

    @discardableResult
    public func emitCommandKey(_ virtualKey: CGKeyCode) -> Bool {
        let generation = syntheticGuard.nextGeneration()
        let source = CGEventSource(stateID: .hidSystemState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: false) else {
            return false
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        let timestamp = markSynthetic(generation: generation)
        keyDown.timestamp = timestamp
        keyUp.timestamp = timestamp

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }

    private func markSynthetic(generation: UInt64) -> CGEventTimestamp {
        let timestamp = TimeInterval(DispatchTime.now().uptimeNanoseconds) / 1_000_000_000.0
        syntheticGuard.markSynthetic(timestamp: timestamp, generation: generation)
        return CGEventTimestamp(timestamp * 1_000_000_000.0)
    }

    private func pauseBetweenEvents() {
        guard interEventDelayNanoseconds > 0 else { return }
        var spec = timespec(tv_sec: 0, tv_nsec: Int(interEventDelayNanoseconds))
        nanosleep(&spec, nil)
    }
}
