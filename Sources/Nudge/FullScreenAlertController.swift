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
    static let summaryFont = NSFont.systemFont(ofSize: 24, weight: .regular)
    static let summaryColor = NSColor.white.withAlphaComponent(0.9)
    static let summaryMaxWidth: CGFloat = 760
    static let hintFont = NSFont.systemFont(ofSize: 24, weight: .regular)
    static let hintColor = NSColor.white.withAlphaComponent(0.85)
}

/// "Got it" and "Join". Always focusable (plain buttons only take focus with Full Keyboard Access) and reports focus
/// so the view can draw its own ring.
final class WarningButton: NSButton {
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
    let gotItButton = WarningButton()
    let joinButton = WarningButton()
    private let onDismiss: () -> Void
    private let onJoin: (URL) -> Void
    private var joinURL: URL?
    private let headingLabel = NSTextField(labelWithString: "")
    private let countdownLabel = NSTextField(labelWithString: "")
    private let titleLabel = NSTextField(wrappingLabelWithString: "")
    private let detailLabel = NSTextField(labelWithString: "")
    private let summaryLabel = NSTextField(wrappingLabelWithString: "")
    private let hintLabel = NSTextField(labelWithString: FullScreenContent.hint)
    private lazy var gotItRing = ringed(gotItButton)
    private lazy var joinRing = ringed(joinButton)
    private let stack = NSStackView()

    init(frame: NSRect, onDismiss: @escaping () -> Void, onJoin: @escaping (URL) -> Void) {
        self.onDismiss = onDismiss
        self.onJoin = onJoin
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = S02Style.alertRed.cgColor
        build()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    private func build() {
        let padding = S02Style.padding
        for label in [headingLabel, countdownLabel, titleLabel, detailLabel, summaryLabel, hintLabel] {
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
        summaryLabel.font = S02Style.summaryFont
        summaryLabel.textColor = S02Style.summaryColor
        summaryLabel.maximumNumberOfLines = 2
        summaryLabel.lineBreakMode = .byWordWrapping
        summaryLabel.cell?.truncatesLastVisibleLine = true
        summaryLabel.preferredMaxLayoutWidth = min(S02Style.summaryMaxWidth, frame.width - 2 * padding)

        gotItButton.keyEquivalent = "\r"
        gotItButton.setAccessibilityLabel(FullScreenContent.buttonTitle)
        gotItButton.target = self
        gotItButton.action = #selector(gotIt)
        style(gotItButton, title: FullScreenContent.buttonTitle, outlined: false)

        joinButton.setAccessibilityLabel(FullScreenContent.joinTitle)
        joinButton.target = self
        joinButton.action = #selector(join)
        style(joinButton, title: FullScreenContent.joinTitle, outlined: false)

        let buttons = NSStackView(views: [joinRing, gotItRing])
        buttons.orientation = .horizontal
        buttons.spacing = 16

        for view in [headingLabel, countdownLabel, titleLabel, detailLabel, summaryLabel, buttons, hintLabel] {
            stack.addArrangedSubview(view)
        }
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 16
        stack.setCustomSpacing(0, after: headingLabel)
        stack.setCustomSpacing(8, after: countdownLabel)
        stack.setCustomSpacing(16, after: titleLabel)
        stack.setCustomSpacing(32, after: detailLabel)
        stack.setCustomSpacing(32, after: summaryLabel)
        stack.setCustomSpacing(12, after: buttons)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: padding),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -padding),
            stack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: padding),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -padding),
            titleLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -2 * padding),
            detailLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -2 * padding),
            summaryLabel.widthAnchor.constraint(lessThanOrEqualToConstant: S02Style.summaryMaxWidth),
            summaryLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, constant: -2 * padding),
        ])
    }

    /// Wraps a button in a ring view that shows the focus ring.
    private func ringed(_ button: WarningButton) -> NSView {
        let ring = NSView()
        ring.wantsLayer = true
        ring.layer?.cornerRadius = 18
        ring.layer?.borderWidth = 4
        ring.layer?.borderColor = NSColor.clear.cgColor
        ring.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        ring.addSubview(button)
        button.onFocusChange = { [weak ring] focused in
            ring?.layer?.borderColor = (focused ? S02Style.focusRing : NSColor.clear).cgColor
        }
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 160),
            button.heightAnchor.constraint(equalToConstant: 56),
            button.centerXAnchor.constraint(equalTo: ring.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: ring.centerYAnchor),
            ring.widthAnchor.constraint(equalToConstant: 172),
            ring.heightAnchor.constraint(equalToConstant: 68),
        ])
        return ring
    }

    /// White fill with red text, or (outlined) a clear fill with a 2 pt white border and white text.
    private func style(_ button: WarningButton, title: String, outlined: Bool) {
        button.isBordered = false
        button.wantsLayer = true
        button.layer?.backgroundColor = (outlined ? NSColor.clear : NSColor.white).cgColor
        button.layer?.cornerRadius = 12
        button.layer?.borderWidth = outlined ? 2 : 0
        button.layer?.borderColor = NSColor.white.cgColor
        button.attributedTitle = NSAttributedString(string: title, attributes: [
            .font: S02Style.buttonFont,
            .foregroundColor: outlined ? NSColor.white : S02Style.alertRed,
        ])
        button.focusRingType = .none
    }

    @objc private func gotIt() { onDismiss() }

    @objc private func join() {
        if let joinURL { onJoin(joinURL) }
    }

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
        summaryLabel.isHidden = content.summary == nil
        if let summary = content.summary, summaryLabel.stringValue != summary { summaryLabel.stringValue = summary }
        stack.setCustomSpacing(content.summary == nil ? 32 : 16, after: detailLabel)
        joinURL = content.joinURL
        let hasLink = content.joinURL != nil
        joinRing.isHidden = !hasLink
        style(gotItButton, title: FullScreenContent.buttonTitle, outlined: hasLink)
        gotItButton.nextKeyView = hasLink ? joinButton : nil
        joinButton.nextKeyView = hasLink ? gotItButton : nil
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

    init(screen: NSScreen, content: FullScreenContent, onDismiss: @escaping () -> Void,
         onJoin: @escaping (URL) -> Void) {
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
        contentView = WarningView(frame: NSRect(origin: .zero, size: screen.frame.size),
                                  onDismiss: onDismiss, onJoin: onJoin)
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

    /// Opens the link, then closes the warning on every screen.
    func join(_ url: URL) {
        NSWorkspace.shared.open(url)
        dismiss()
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
            WarningWindow(screen: screen, content: content,
                          onDismiss: { [weak self] in self?.dismiss() },
                          onJoin: { [weak self] url in self?.join(url) })
        }
        guard let main = windows.first else { return }   // screens[0] is the menu-bar screen
        NSApp.activate(ignoringOtherApps: true)
        for window in windows.dropFirst() { window.orderFrontRegardless() }
        main.makeKeyAndOrderFront(nil)
        main.makeFirstResponder(main.warningView.gotItButton)
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
