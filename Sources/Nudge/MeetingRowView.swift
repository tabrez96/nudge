#if os(macOS)
import AppKit
import NudgeCore

/// One S01 meeting row: title, optional Join pill, right-aligned detail and an optional two-line description.
/// Drawn in one pass so the highlight can recolour everything.
final class MeetingRowView: NSView {
    static let accent = NSColor(srgbRed: 0x0B / 255, green: 0x57 / 255, blue: 0xD0 / 255, alpha: 1)

    private static let inset: CGFloat = 14
    private static let titleFont = NSFont.menuFont(ofSize: 13)
    private static let summaryFont = NSFont.systemFont(ofSize: 12)
    private static let pillFont = NSFont.systemFont(ofSize: 11, weight: .semibold)

    private let row: MeetingRow
    private let lineHeight: CGFloat
    private let summaryHeight: CGFloat

    init(row: MeetingRow, width: CGFloat) {
        self.row = row
        let font = Self.titleFont
        lineHeight = ceil(font.ascender - font.descender + font.leading)
        if let summary = row.summary {
            let measured = Self.summaryString(summary, color: .labelColor).boundingRect(
                with: NSSize(width: width - 2 * Self.inset, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin])
            let cap = 2 * ceil(Self.summaryFont.ascender - Self.summaryFont.descender + Self.summaryFont.leading)
            summaryHeight = min(ceil(measured.height), cap)
        } else {
            summaryHeight = 0
        }
        let height = 3 + lineHeight + (row.summary == nil ? 0 : 1 + summaryHeight) + 3
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: height))
        setAccessibilityElement(true)
        setAccessibilityRole(row.joinURL == nil ? .staticText : .button)
        setAccessibilityLabel(MenuPresentation.meetingLabel(row))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override var isFlipped: Bool { true }

    private static func summaryString(_ text: String, color: NSColor) -> NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        return NSAttributedString(string: text, attributes: [
            .font: summaryFont, .foregroundColor: color, .paragraphStyle: style,
        ])
    }

    override func draw(_ dirtyRect: NSRect) {
        let item = enclosingMenuItem
        let lit = item?.isHighlighted == true && item?.isEnabled == true
        if lit {
            NSColor.selectedContentBackgroundColor.setFill()
            NSBezierPath(roundedRect: bounds.insetBy(dx: 5, dy: 0), xRadius: 4, yRadius: 4).fill()
        }
        let primary: NSColor = lit ? .white : .labelColor
        let secondary: NSColor = lit ? .white : .secondaryLabelColor

        let detailFont = row.isSoon ? NSFont.systemFont(ofSize: 13, weight: .bold) : Self.titleFont
        let detailColor: NSColor = lit ? .white : (row.isSoon ? MenuController.amber : .secondaryLabelColor)
        let detail = NSAttributedString(string: row.detail, attributes: [.font: detailFont, .foregroundColor: detailColor])
        let detailSize = detail.size()
        let detailX = bounds.width - Self.inset - ceil(detailSize.width)
        detail.draw(at: NSPoint(x: detailX, y: 3 + (lineHeight - detailSize.height) / 2))

        var titleRight = detailX - 8
        if row.joinURL != nil {
            let label = NSAttributedString(string: "Join", attributes: [
                .font: Self.pillFont, .foregroundColor: lit ? Self.accent : NSColor.white,
            ])
            let pillWidth = ceil(label.size().width) + 16
            let pill = NSRect(x: detailX - 6 - pillWidth, y: 3 + (lineHeight - 18) / 2, width: pillWidth, height: 18)
            (lit ? NSColor.white : Self.accent).setFill()
            NSBezierPath(roundedRect: pill, xRadius: 5, yRadius: 5).fill()
            let size = label.size()
            label.draw(at: NSPoint(x: pill.minX + 8, y: pill.midY - size.height / 2))
            titleRight = pill.minX - 8
        }

        let titleStyle = NSMutableParagraphStyle()
        titleStyle.lineBreakMode = .byTruncatingTail
        let title = NSAttributedString(string: row.title, attributes: [
            .font: Self.titleFont, .foregroundColor: primary, .paragraphStyle: titleStyle,
        ])
        title.draw(in: NSRect(x: Self.inset, y: 3, width: max(0, titleRight - Self.inset), height: lineHeight))

        if let summary = row.summary {
            Self.summaryString(summary, color: secondary).draw(
                with: NSRect(x: Self.inset, y: 3 + lineHeight + 1, width: bounds.width - 2 * Self.inset,
                             height: summaryHeight),
                options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])
        }
    }

    override func mouseUp(with event: NSEvent) {
        guard let item = enclosingMenuItem, item.isEnabled, let menu = item.menu else { return }
        menu.cancelTracking()
        menu.performActionForItem(at: menu.index(of: item))
    }
}
#endif
