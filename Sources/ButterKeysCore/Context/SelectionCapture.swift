import ApplicationServices
import Foundation

/// Snapshot of the focused field's selected text for teach-from-selection.
public struct SelectionSnapshot: Sendable {
    public let text: String

    public init(text: String) {
        self.text = text
    }
}

/// Reads / replaces selected text via Accessibility. Call only off the event-tap thread.
public final class SelectionCapture: @unchecked Sendable {
    private var retainedElement: AXUIElement?

    public init() {}

    public func snapshot() -> SelectionSnapshot? {
        retainedElement = nil
        guard let element = focusedElement() else { return nil }

        var selectedText: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )
        guard result == .success, let text = selectedText as? String else { return nil }

        let trimmed = TeachCapture.normalize(text)
        guard !trimmed.isEmpty else { return nil }

        retainedElement = element
        return SelectionSnapshot(text: trimmed)
    }

    @discardableResult
    public func replaceRetainedSelection(with replacement: String) -> Bool {
        guard let element = retainedElement else { return false }
        let value = replacement as CFTypeRef
        let result = AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            value
        )
        retainedElement = nil
        return result == .success
    }

    public func clear() {
        retainedElement = nil
    }

    private func focusedElement() -> AXUIElement? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?
        guard
            AXUIElementCopyAttributeValue(
                systemWide,
                kAXFocusedUIElementAttribute as CFString,
                &focusedElement
            ) == .success,
            let focusedElement
        else {
            return nil
        }
        return (focusedElement as! AXUIElement)
    }
}
