import ApplicationServices
import Foundation

public struct TextSelectionDiagnostics: Sendable, Equatable {
    public let selectedTextLength: Int

    public init(selectedTextLength: Int) {
        self.selectedTextLength = selectedTextLength
    }
}

public protocol TextContextProviding: Sendable {
    func selectedTextDiagnostics() -> TextSelectionDiagnostics?
    func selectedText() -> String?
}

public struct TextContextProvider: TextContextProviding {
    public init() {}

    public func selectedTextDiagnostics() -> TextSelectionDiagnostics? {
        nil
    }

    public func selectedText() -> String? {
        nil
    }
}

public final class AccessibilityTextContextProvider: @unchecked Sendable, TextContextProviding {
    public init() {}

    public func selectedText() -> String? {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedElement: CFTypeRef?
        guard
            AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success,
            let focusedElement
        else {
            return nil
        }

        var selectedText: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            focusedElement as! AXUIElement,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )

        guard result == .success, let text = selectedText as? String else {
            return nil
        }
        return text
    }

    public func selectedTextDiagnostics() -> TextSelectionDiagnostics? {
        guard let text = selectedText() else { return nil }
        return TextSelectionDiagnostics(selectedTextLength: text.count)
    }
}
