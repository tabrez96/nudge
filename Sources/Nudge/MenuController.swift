#if os(macOS)
import AppKit
import NudgeCore

private final class ActionBox: NSObject {
    let action: MenuAction
    init(_ action: MenuAction) { self.action = action }
}

/// Builds S01: the menu bar icon and its menu, rebuilt from `MenuModel` each time it opens.
final class MenuController: NSObject, NSMenuDelegate, SyncObserving {
    static let menuWidth: CGFloat = 372
    static let errorRed = NSColor(srgbRed: 0xB3 / 255, green: 0x26 / 255, blue: 0x1E / 255, alpha: 1)
    static let okGreen = NSColor(srgbRed: 0x1E / 255, green: 0x7F / 255, blue: 0x3C / 255, alpha: 1)
    static let amber = NSColor(srgbRed: 0xA3 / 255, green: 0x52 / 255, blue: 0x00 / 255, alpha: 1)

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()
    private unowned let app: AppDelegate
    private var shownIcon: MenuIcon = .normal
    private var shownDot: StatusDot = .green
    private var isOpen = false
    /// Set by the S03 notifier ticket; true until then.
    var notificationsAllowed = true

    init(app: AppDelegate) {
        self.app = app
        super.init()
        menu.delegate = self
        menu.autoenablesItems = false
        menu.minimumWidth = Self.menuWidth
        statusItem.menu = menu
        updateIcon(currentModel())
    }

    func currentModel(now: Date = Date()) -> MenuModel {
        MenuModel.build(status: app.coordinator.status, meetings: app.coordinator.meetings,
                        calendars: app.coordinator.calendars, selectedID: app.coordinator.chosenCalendar?.id,
                        notificationsAllowed: notificationsAllowed, now: now)
    }

    // MARK: SyncObserving / NSMenuDelegate

    func syncDidChange(_ coordinator: SyncCoordinator) {
        let model = currentModel()
        updateIcon(model)
        if isOpen { rebuild(menu, from: model) }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        let model = currentModel()
        updateIcon(model)
        rebuild(menu, from: model)
    }

    func menuWillOpen(_ menu: NSMenu) { isOpen = true }

    func menuDidClose(_ menu: NSMenu) { isOpen = false }

    // MARK: Icon

    private func updateIcon(_ model: MenuModel) {
        shownIcon = model.icon.resolved(previous: shownIcon)
        let image: NSImage?
        if shownIcon == .problem {
            let base = NSImage(systemSymbolName: "bell.badge", accessibilityDescription: nil)
            image = base?.withSymbolConfiguration(NSImage.SymbolConfiguration(paletteColors: [Self.errorRed]))
            image?.isTemplate = false
        } else {
            image = NSImage(systemSymbolName: "bell", accessibilityDescription: nil)
            image?.isTemplate = true
        }
        let label = MenuPresentation.statusItemLabel(icon: shownIcon, status: model.status)
        statusItem.button?.image = image
        statusItem.button?.setAccessibilityLabel(label)
        statusItem.button?.toolTip = label
    }

    // MARK: Menu

    private func rebuild(_ menu: NSMenu, from model: MenuModel) {
        menu.removeAllItems()
        menu.addItem(statusLineItem(model.status))
        menu.addItem(.separator())
        for row in model.rows { menu.addItem(item(for: row)) }
    }

    private func statusLineItem(_ status: StatusLine) -> NSMenuItem {
        shownDot = status.dot.resolved(previous: shownDot)
        let isRed = shownDot == .red
        let font = NSFont.menuFont(ofSize: 13)
        let text = NSMutableAttributedString(
            string: "● ", attributes: [.font: font, .foregroundColor: isRed ? Self.errorRed : Self.okGreen])
        text.append(NSAttributedString(
            string: status.text,
            attributes: [.font: font, .foregroundColor: isRed ? Self.errorRed : NSColor.labelColor]))

        let label = NSTextField(wrappingLabelWithString: "")
        label.attributedStringValue = text
        label.preferredMaxLayoutWidth = Self.menuWidth - 28
        label.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.addSubview(label)
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: Self.menuWidth),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6),
        ])
        container.setFrameSize(container.fittingSize)
        container.setAccessibilityElement(true)
        container.setAccessibilityRole(.staticText)
        container.setAccessibilityLabel(MenuPresentation.statusLineLabel(status))

        let item = NSMenuItem()
        item.view = container
        item.isEnabled = false
        return item
    }

    private func disabledItem(_ text: NSAttributedString) -> NSMenuItem {
        let item = NSMenuItem()
        item.attributedTitle = text
        item.isEnabled = false
        return item
    }

    private func item(for row: MenuRow) -> NSMenuItem {
        switch row {
        case .separator:
            return .separator()
        case .header(let text):
            let item = disabledItem(NSAttributedString(string: text.uppercased(), attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
                .foregroundColor: NSColor.secondaryLabelColor,
            ]))
            item.setAccessibilityLabel(text)
            return item
        case .meeting(let meeting):
            let style = NSMutableParagraphStyle()
            style.tabStops = [NSTextTab(textAlignment: .right, location: Self.menuWidth - 50)]
            let text = NSMutableAttributedString(
                string: MenuPresentation.truncated(meeting.title) + "\t",
                attributes: [.font: NSFont.menuFont(ofSize: 13), .foregroundColor: NSColor.labelColor,
                             .paragraphStyle: style])
            let detailAttributes: [NSAttributedString.Key: Any] = meeting.isSoon
                ? [.font: NSFont.systemFont(ofSize: 13, weight: .bold), .foregroundColor: Self.amber,
                   .paragraphStyle: style]
                : [.font: NSFont.menuFont(ofSize: 13), .foregroundColor: NSColor.secondaryLabelColor,
                   .paragraphStyle: style]
            text.append(NSAttributedString(string: meeting.detail, attributes: detailAttributes))
            let item = disabledItem(text)
            item.setAccessibilityLabel(MenuPresentation.meetingLabel(meeting))
            return item
        case .message(let text):
            return disabledItem(NSAttributedString(string: text, attributes: [
                .font: NSFont.menuFont(ofSize: 13), .foregroundColor: NSColor.secondaryLabelColor,
            ]))
        case .warning(let text):
            return disabledItem(NSAttributedString(string: text, attributes: [
                .font: NSFont.menuFont(ofSize: 13), .foregroundColor: Self.amber,
            ]))
        case .calendarPicker(let title, let options):
            let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            let submenu = NSMenu()
            submenu.autoenablesItems = false
            for option in options {
                let sub = NSMenuItem(title: option.title, action: #selector(chooseCalendar(_:)), keyEquivalent: "")
                sub.target = self
                sub.representedObject = option.id
                sub.state = option.isSelected ? .on : .off
                submenu.addItem(sub)
            }
            item.submenu = submenu
            return item
        case .action(let action, let title, let key):
            let item = NSMenuItem(title: title, action: #selector(perform(_:)), keyEquivalent: key ?? "")
            item.target = self
            item.keyEquivalentModifierMask = .command
            item.representedObject = ActionBox(action)
            return item
        }
    }

    @objc private func perform(_ sender: NSMenuItem) {
        guard let box = sender.representedObject as? ActionBox else { return }
        switch box.action {
        case .refresh, .retry: app.refresh()
        case .quit: NSApp.terminate(nil)
        case .testAlerts: app.testAlerts()
        case .allowCalendarAccess: app.fixCalendarAccess()
        case .openInternetAccounts: app.openInternetAccounts()
        }
    }

    @objc private func chooseCalendar(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        app.selectCalendar(id: id)
    }
}
#endif
