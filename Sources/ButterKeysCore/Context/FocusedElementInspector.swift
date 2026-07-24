import ApplicationServices
import Foundation

public enum FocusedElementSecurity: Sendable, Equatable {
    case unknown
    case secure
    case notSecure
}

public final class FocusedElementInspector: @unchecked Sendable {
    public init() {}

    public func inspectFocusedElement() -> FocusedElementSecurity {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedElement: CFTypeRef?
        let focusedResult = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard focusedResult == .success, let element = focusedElement else {
            return .unknown
        }

        let uiElement = element as! AXUIElement

        if isSecureTextField(uiElement) {
            return .secure
        }

        if hasSecureTextSubrole(uiElement) {
            return .secure
        }

        return .notSecure
    }

    private func isSecureTextField(_ element: AXUIElement) -> Bool {
        guard let role = copyStringAttribute(kAXRoleAttribute as CFString, from: element) else {
            return false
        }
        return role == (kAXTextFieldRole as String) && hasSecureTextSubrole(element)
    }

    private func hasSecureTextSubrole(_ element: AXUIElement) -> Bool {
        guard let subrole = copyStringAttribute(kAXSubroleAttribute as CFString, from: element) else {
            return false
        }
        return subrole == (kAXSecureTextFieldSubrole as String)
    }

    private func copyStringAttribute(_ attribute: CFString, from element: AXUIElement) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success, let value else { return nil }
        return value as? String
    }
}
