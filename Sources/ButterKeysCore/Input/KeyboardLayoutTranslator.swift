import Carbon
import Foundation
import OSLog

public final class KeyboardLayoutTranslator: @unchecked Sendable {
    private let lock = NSLock()
    private let logger = Logger(subsystem: "com.timbeniks.ButterKeys", category: "KeyboardLayoutTranslator")

    public init() {}

    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        logger.debug("Keyboard layout translator reset")
    }

    public func translate(keyCode: UInt16, modifiers: ModifierFlags) -> String? {
        lock.lock()
        defer { lock.unlock() }

        guard
            let inputSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
            let layoutDataPointer = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData)
        else {
            return nil
        }

        let layoutData = unsafeBitCast(layoutDataPointer, to: CFData.self)
        guard let keyLayout = CFDataGetBytePtr(layoutData) else { return nil }

        var deadKeyState: UInt32 = 0
        let maxChars = 8
        var length = 0
        var chars = [UniChar](repeating: 0, count: maxChars)

        let modifierKeyState = UInt32((modifiers.cgEventFlags.rawValue >> 16) & 0xFF)
        let keyboardType = UInt32(LMGetKbdType())
        let layout = UnsafePointer<UCKeyboardLayout>(OpaquePointer(keyLayout))

        let status = UCKeyTranslate(
            layout,
            keyCode,
            UInt16(kUCKeyActionDisplay),
            modifierKeyState,
            keyboardType,
            OptionBits(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState,
            maxChars,
            &length,
            &chars
        )

        guard status == noErr, length > 0 else { return nil }

        return String(utf16CodeUnits: chars, count: length)
    }
}
