import Foundation

public struct ModifierState: Sendable, Equatable {
    public private(set) var shift: Bool = false
    public private(set) var capsLock: Bool = false
    public private(set) var command: Bool = false
    public private(set) var control: Bool = false
    public private(set) var option: Bool = false

    public init() {}

    public var commandOrControlDown: Bool {
        command || control
    }

    public mutating func apply(_ event: NormalizedKeyEvent) {
        guard event.type == .flagsChanged || event.type == .keyDown || event.type == .keyUp else { return }
        shift = event.modifiers.contains(.shift)
        capsLock = event.modifiers.contains(.capsLock)
        command = event.modifiers.contains(.command)
        control = event.modifiers.contains(.control)
        option = event.modifiers.contains(.option)
    }

    public mutating func reset() {
        shift = false
        capsLock = false
        command = false
        control = false
        option = false
    }
}
