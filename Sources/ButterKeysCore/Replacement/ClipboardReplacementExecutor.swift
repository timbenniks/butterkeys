import AppKit
import Carbon
import Foundation

public struct ClipboardReplacementExecutor: Sendable {
    private let emitter: SyntheticEventEmitter

    public init(emitter: SyntheticEventEmitter) {
        self.emitter = emitter
    }

    /// Optional fallback path. Deletes via synthetic backspaces, then pastes. Never logs clipboard contents.
    public func execute(plan: CorrectionTransactionPlan) -> Bool {
        guard plan.isValid else { return false }

        let pasteboard = NSPasteboard.general
        let snapshot = PasteboardSnapshot.capture(from: pasteboard)
        let insertText = plan.insertText

        guard emitter.emitBackspaces(count: plan.deleteCount) else {
            return false
        }

        pasteboard.clearContents()
        guard pasteboard.setString(insertText, forType: .string) else {
            snapshot.restoreIfUnchanged(on: pasteboard)
            return false
        }

        let changeCountAfterSet = pasteboard.changeCount
        guard emitter.emitCommandKey(CGKeyCode(kVK_ANSI_V)) else {
            snapshot.restoreIfUnchanged(on: pasteboard, expectedChangeCount: changeCountAfterSet)
            return false
        }

        snapshot.restoreIfUnchanged(on: pasteboard, expectedChangeCount: changeCountAfterSet)
        return true
    }
}

private struct PasteboardSnapshot: Sendable {
    let changeCount: Int
    let stringValue: String?
    let propertyListTypes: [NSPasteboard.PasteboardType: Data]

    static func capture(from pasteboard: NSPasteboard) -> PasteboardSnapshot {
        var payloads: [NSPasteboard.PasteboardType: Data] = [:]
        for type in pasteboard.types ?? [] {
            if let data = pasteboard.data(forType: type) {
                payloads[type] = data
            }
        }
        return PasteboardSnapshot(
            changeCount: pasteboard.changeCount,
            stringValue: pasteboard.string(forType: .string),
            propertyListTypes: payloads
        )
    }

    func restoreIfUnchanged(on pasteboard: NSPasteboard, expectedChangeCount: Int? = nil) {
        let expected = expectedChangeCount ?? changeCount
        guard pasteboard.changeCount == expected else { return }

        pasteboard.clearContents()
        if propertyListTypes.isEmpty {
            if let stringValue {
                pasteboard.setString(stringValue, forType: .string)
            }
            return
        }

        for (type, data) in propertyListTypes {
            pasteboard.setData(data, forType: type)
        }
    }
}
