# Entitlements

ButterKeys targets **direct distribution** (non-sandboxed).

Configured in `Config/ButterKeys.entitlements`:

| Key | Value | Reason |
|---|---|---|
| `com.apple.security.app-sandbox` | `false` | Global `CGEventTap` + input monitoring are impractical in the App Store sandbox for v1 |
| `com.apple.security.automation.apple-events` | `true` | Opening System Settings / limited local automation |

Runtime permissions (not entitlements):

- Input Monitoring
- Accessibility

Hardened Runtime should be enabled for release builds. Do not enable JIT or unsigned executable memory.

Investigate Mac App Store feasibility separately; do not assume sandbox compatibility for global keyboard correction.
