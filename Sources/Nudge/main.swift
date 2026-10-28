import NudgeCore

#if os(macOS)
import AppKit

// Menu-bar-only app: no Dock icon, no main window.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
#else
print("\(AppInfo.name) is a macOS menu bar app and only runs on macOS. On this platform you can build and test NudgeCore with `swift test`.")
#endif
