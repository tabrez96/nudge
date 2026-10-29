#if os(macOS)
import AppKit
import NudgeCore

/// S02 colors, sizes and fonts from design/ux.md.
private enum S02Style {
    static let alertRed = NSColor(srgbRed: 0x7A / 255.0, green: 0x0F / 255.0, blue: 0x0A / 255.0, alpha: 1)
    static let focusRing = NSColor(srgbRed: 0xFF / 255.0, green: 0xD5 / 255.0, blue: 0x4A / 255.0, alpha: 1)
    static let padding: CGFloat = 40
    static let headingFont = NSFont.systemFont(ofSize: 24, weight: .medium)
    static let titleFont = NSFont.systemFont(ofSize: 96, weight: .bold)
    static let detailFont = NSFont.systemFont(ofSize: 28, weight: .regular)
    static let buttonFont = NSFont.systemFont(ofSize: 24, weight: .semibold)
    static let hintFont = NSFont.systemFont(ofSize: 24, weight: .regular)
    static let hintColor = NSColor.white.withAlphaComponent(0.85)
}

/// "Got it". Always focusable (plain buttons only take focus with Full Keyboard Access) and reports focus
/// so the view can draw its own ring.
final class GotItButton: NSButton {
    var onFocusChange: ((Bool) -> Void)?

    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }

    override func becomeFirstResponder() -> Bool {
        let ok = super.becomeFirstResponder()
        if ok { onFocusChange?(true) }
        return ok
    }

    override func resignFirstResponder() -> Bool {
        let ok = super.resignFirstResponder()
        if ok { onFocusChange?(false) }
        return ok
    }
}

final class WarningView: NSView {
    let button = GotItButton()
    private let onDismiss: () -> Void
    private let headingLabel = NSTextField(labelWithString: "")
    private let countdownLabel = NSTextField(labelWithString: "")
    private let titleLabel = NSTextField(wrappingLabelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "")
    private let hintLabel = NSTextField(labelWithString: FullScreenContent.hint)
    private let ringView = NSView()

    init(frame: NSRect, onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = S02Style.alertRed.cgColor
        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    private func build() {
        let padding = S02Style.padding
        for label in [headingLabel, countdownLabel, titleLabel, detailLabel, hintLabel] {
            label.alignment = .center
            label.textColor = .white
        }
        hintLabel.textColor = S02Style.hintColor
        hintLabel.font = S02Style.hintFont
        titleLabel.font = S02Style.titleFont
        titleLabel.maximumNumberOfLines = 2
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.cell?.truncatesLastVisibleLine = true
        titleLabel.preferredMaxLayoutWidth = frame.width - 2 * padding
        detailLabel.font = S02Style.detailFont
        detailLabel.maximumNumberOfLines = 1
        detailLabel.lineBreakMode = .byTruncatingTail

        button.isBordered = false
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor.white.cgColor
        button.layer?.cornerRadius = 12
        button.attributedTitle = NSAttributedString(string: FullScreenContent.buttonTitle, attributes: [
            .font: S02Style.buttonFont,
            .foregroundColor: S02Style.alertRed,
        ])
        button.keyEquivalent = "\r"
        button.focusRingType = .none
        button.setAccessibilityLabel(FullScreenContent.buttonTitle)
        button.target = self
        button.action = #selector(gotIt)
        button.translatesAutoresizingMaskIntoConstraints = false

        ringView.wantsLayer = true
        ringView.layer?.cornerRadius = 18
        ringView.layer?.borderWidth = 4
        ringView.layer?.borderColor = NSColor.clear.cgColor
        ringView.translatesAutoresizingMaskIntoConstraints = false
        ringView.addSubview(button)
        button.onFocusChange = { [weak ringView] focused in
            ringView?.layer?.borderColor = (focused ? S02Style.focusRing : NSColor.clear).cgColor
        }

        let stack = NSStackView(views: [headingLabel, countdownLabel, titleLabel, detailLabel, ringView, hintLabel])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 16
        stack.setCustomSpacing(0, after: headingLabel)
        stack.setCustomSpacing(8, after: countdownLabel)
        stack.setCustomSpacing(16, after: titleLabel)
        stack.setCustomSpacing(32, after: detailLabel)
        stack.setCustomSpacing(12, after: ringView)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 160),
            button.heightAnchor.constraint(equalToConstant: 56),
            button.centerXAnchor.constraint(equalTo: ringView.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: ringView.centerYAnchor),
            ringView.widthAnchor.constraint(equalToConstant: 172),
            ringView.heightAnchor.constraint(equalToConstant: 68),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: padding),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -padding),
            stack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: padding),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -padding),
            titleLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -2 * padding),
            detailLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -2 * padding),
        ])
    }

    @objc private func gotIt() { onDismiss() }

    func update(_ content: FullScreenContent) {
        headingLabel.isHidden = content.heading == nil
        if let heading = content.heading {
            headingLabel.attributedStringValue = NSAttributedString(string: heading.uppercased(), attributes: [
                .font: S02Style.headingFont,
                .foregroundColor: NSColor.white,
                .kern: 3,
            ])
        }
        countdownLabel.stringValue = content.countdown
        countdownLabel.font = countdownFont(for: content.countdown)
        if titleLabel.stringValue != content.title { titleLabel.stringValue = content.title }
        if detailLabel.stringValue != content.detail { detailLabel.stringValue = content.detail }
    }

    /// 200 pt unless the text ("Starting now" on a small screen) would overflow the padded width.
    private func countdownFont(for text: String) -> NSFont {
        let maxWidth = bounds.width - 2 * S02Style.padding
        var size: CGFloat = 200
        while size > 48 {
            let font = NSFont.monospacedDigitSystemFont(ofSize: size, weight: .bold)
            if (text as NSString).size(withAttributes: [.font: font]).width <= maxWidth { return font }
            size -= 8
        }
        return NSFont.monospacedDigitSystemFont(ofSize: 48, weight: .bold)
    }
}

/// Borderless window covering one screen above full-screen apps and on every Space.
final class WarningWindow: NSWindow {
    private let onDismiss: () -> Void

    init(screen: NSScreen, content: FullScreenContent, onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        super.init(contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        setFrame(screen.frame, display: false)
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        isOpaque = true
        backgroundColor = S02Style.alertRed
        isMovable = false
        contentView = WarningView(frame: NSRect(origin: .zero, size: screen.frame.size), onDismiss: onDismiss)
        warningView.update(content)
    }

    var warningView: WarningView { contentView as! WarningView }

    // Borderless windows refuse key by default, which would kill keyboard focus.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func cancelOperation(_ sender: Any?) { onDismiss() }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53, 36, 76: onDismiss()  // Esc, Return, keypad Enter
        default: super.keyDown(with: event)
        }
    }
}

/// S02: covers every screen with the one-minute warning. Ignores other alert kinds.
final class FullScreenAlertController: NSObject, AlertPresenting {
    private let warning = FullScreenWarning()
    private var windows: [WarningWindow] = []

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(screensChanged(_:)),
                                               name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    func present(_ alert: ScheduledAlert, now: Date) {
        guard warning.show(alert) else { return }
        open(now: now, announce: true)   // replaces any open warning
    }

    func tick(now: Date) {
        guard let content = warning.content(now: now) else { return }
        for window in windows { window.warningView.update(content) }
    }

    /// Got it, Return or Esc on any screen.
    func dismiss() {
        guard warning.isOpen else { return }
        warning.dismiss()
        closeWindows()
        NSApp.hide(nil)   // hand focus back to the app the user was in
    }

    private func open(now: Date, announce: Bool) {
        closeWindows()
        guard let content = warning.content(now: now) else { return }
        windows = NSScreen.screens.map { screen in
            WarningWindow(screen: screen, content: content) { [weak self] in self?.dismiss() }
        }
        guard let main = windows.first else { return }   // screens[0] is the menu-bar screen
        NSApp.activate(ignoringOtherApps: true)
        for window in windows.dropFirst() { window.orderFrontRegardless() }
        main.makeKeyAndOrderFront(nil)
        main.makeFirstResponder(main.warningView.button)
        if announce, let text = warning.announcement(now: now) {
            NSAccessibility.post(element: main, notification: .announcementRequested,
                                 userInfo: [.announcement: text,
                                            .priority: NSAccessibilityPriorityLevel.high.rawValue])
        }
    }

    private func closeWindows() {
        for window in windows { window.orderOut(nil); window.close() }
        windows = []
    }

    /// A screen was plugged in or removed while open: rebuild so every screen stays covered. Not re-announced.
    @objc private func screensChanged(_ note: Notification) {
        guard warning.isOpen else { return }
        open(now: Date(), announce: false)
    }
}
#endif
