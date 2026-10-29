import SwiftUI
import UIKit

// A 0xRRGGBB color with a shade for each appearance.
struct ColorPair: Hashable, Sendable {
    let light: UInt32
    let dark: UInt32

    var color: Color {
        Color(
            uiColor: UIColor { traits in
                UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
            })
    }

    // White text on the fill, or black where white wouldn't reach the WCAG 3:1 minimum.
    var textOnFill: ColorPair {
        ColorPair(light: ColorContrast.textColor(onFill: light), dark: ColorContrast.textColor(onFill: dark))
    }
}

// WCAG 2 contrast for 0xRRGGBB colors.
enum ColorContrast {
    static let white: UInt32 = 0xFFFFFF
    static let black: UInt32 = 0x000000
    static let minimum = 3.0

    static func ratio(_ first: UInt32, _ second: UInt32) -> Double {
        let (lighter, darker) = (max(luminance(first), luminance(second)), min(luminance(first), luminance(second)))
        return (lighter + 0.05) / (darker + 0.05)
    }

    static func textColor(onFill fill: UInt32) -> UInt32 {
        ratio(white, fill) >= minimum ? white : black
    }

    static func luminance(_ hex: UInt32) -> Double {
        let (red, green, blue) = hex.rgbComponents
        return 0.2126 * linearized(red) + 0.7152 * linearized(green) + 0.0722 * linearized(blue)
    }

    private static func linearized(_ value: Double) -> Double {
        value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
}

extension UInt32 {
    fileprivate var rgbComponents: (Double, Double, Double) {
        (Double((self >> 16) & 0xFF) / 255, Double((self >> 8) & 0xFF) / 255, Double(self & 0xFF) / 255)
    }
}

extension UIColor {
    fileprivate convenience init(hex: UInt32) {
        let (red, green, blue) = hex.rgbComponents
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}
