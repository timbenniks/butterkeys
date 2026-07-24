import CoreGraphics
import Foundation

public enum KeyEventType: Sendable, Equatable {
    case keyDown
    case keyUp
    case flagsChanged
}

public struct ModifierFlags: OptionSet, Sendable, Equatable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let shift = ModifierFlags(rawValue: 1 << 0)
    public static let control = ModifierFlags(rawValue: 1 << 1)
    public static let option = ModifierFlags(rawValue: 1 << 2)
    public static let command = ModifierFlags(rawValue: 1 << 3)
    public static let capsLock = ModifierFlags(rawValue: 1 << 4)
    public static let function = ModifierFlags(rawValue: 1 << 5)

    public init(cgFlags: CGEventFlags) {
        var flags = ModifierFlags()
        if cgFlags.contains(.maskShift) { flags.insert(.shift) }
        if cgFlags.contains(.maskControl) { flags.insert(.control) }
        if cgFlags.contains(.maskAlternate) { flags.insert(.option) }
        if cgFlags.contains(.maskCommand) { flags.insert(.command) }
        if cgFlags.contains(.maskAlphaShift) { flags.insert(.capsLock) }
        if cgFlags.contains(.maskSecondaryFn) { flags.insert(.function) }
        self = flags
    }

    public var cgEventFlags: CGEventFlags {
        var flags: CGEventFlags = []
        if contains(.shift) { flags.insert(.maskShift) }
        if contains(.control) { flags.insert(.maskControl) }
        if contains(.option) { flags.insert(.maskAlternate) }
        if contains(.command) { flags.insert(.maskCommand) }
        if contains(.capsLock) { flags.insert(.maskAlphaShift) }
        if contains(.function) { flags.insert(.maskSecondaryFn) }
        return flags
    }
}

public struct NormalizedKeyEvent: Sendable, Equatable {
    public let keyCode: UInt16
    public let characters: String?
    public let modifiers: ModifierFlags
    public let timestamp: TimeInterval
    public let isRepeat: Bool
    public let type: KeyEventType
    public let syntheticGeneration: UInt64?

    public init(
        keyCode: UInt16,
        characters: String? = nil,
        modifiers: ModifierFlags,
        timestamp: TimeInterval,
        isRepeat: Bool,
        type: KeyEventType,
        syntheticGeneration: UInt64? = nil
    ) {
        self.keyCode = keyCode
        self.characters = characters
        self.modifiers = modifiers
        self.timestamp = timestamp
        self.isRepeat = isRepeat
        self.type = type
        self.syntheticGeneration = syntheticGeneration
    }

    static func from(_ event: CGEvent, type: KeyEventType) -> NormalizedKeyEvent {
        let flags = event.flags
        var characters: String?
        if type == .keyDown {
            var length = 0
            var buffer = [UniChar](repeating: 0, count: 8)
            event.keyboardGetUnicodeString(
                maxStringLength: buffer.count,
                actualStringLength: &length,
                unicodeString: &buffer
            )
            if length > 0 {
                characters = String(utf16CodeUnits: buffer, count: length)
            }
        }

        return NormalizedKeyEvent(
            keyCode: UInt16(event.getIntegerValueField(.keyboardEventKeycode)),
            characters: characters,
            modifiers: ModifierFlags(cgFlags: flags),
            timestamp: TimeInterval(event.timestamp) / 1_000_000_000.0,
            isRepeat: event.getIntegerValueField(.keyboardEventAutorepeat) != 0,
            type: type
        )
    }
}
