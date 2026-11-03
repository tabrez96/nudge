import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

/// Geometry of the red problem dot on S01's menu bar bell, in points, AppKit coordinates (origin bottom-left).
/// The dot sits in the image's top-right corner; a clear ring of `gap` around it is cut out of the bell.
public enum MenuBarBadge {
    /// Raise to 7 if the dot doesn't read at 16 px on a real menu bar. Never add a second glyph instead.
    public static let dotDiameter: CGFloat = 6
    public static let gap: CGFloat = 1.5

    public static func dotRect(in size: CGSize) -> CGRect {
        CGRect(x: size.width - dotDiameter, y: size.height - dotDiameter,
               width: dotDiameter, height: dotDiameter)
    }

    /// The dot grown by `gap` on every side; this area is erased from the bell before the dot is drawn.
    public static func knockoutRect(in size: CGSize) -> CGRect {
        dotRect(in: size).insetBy(dx: -gap, dy: -gap)
    }
}
