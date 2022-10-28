//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

/// The purpose of this file is to describe universal types that can exist at all levels of the architecture.
///
/// Note that it is important to carefully consider which types should be entitled to existing in this file:
/// - Types in this file ignore all layer responsibilities and encapsulation
/// - Types in this file should be generically relevant in all layers (eg. not view / entity data)
/// - Types in this file should be universally useful across multiple use cases (ie. not single / specific purpose)
import Foundation
import SwiftUI
import UIKit

public extension BinaryFloatingPoint {
    /// A ratio value (0-1) which is currently dialed all the way down.
    static var off: Self { Self(0) }
    /// A ratio value (0-1) which is currently dialed all the way up.
    static var on:  Self { Self(1) }
}

public extension Identifiable {
    /// A convenience operator for comparing identifiable identities.
    static func ~= (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

/// A unitary value is any value whose state is uniquely identified by its associated identity.
public protocol Unitary: Identifiable, Hashable {}

/// A tint is used to associate a standard presentable color shade with some entity data.
public protocol Tint {
    /// Components of the tint in the normalized sRGB extended range.
    var extendedSRGB: (red: Double, green: Double, blue: Double) { get }
}

/// An avatar is used to provide a standard cross-platform representation for easily recognizing an entity across the many places and platforms it might appear.
public protocol Avatar {
    var image:   URL? { get }
    var tint:    Tint { get }
    var moniker: String { get }
}

// MARK: - Concrete

/// Unitary types are an easy and convenient way to make any Identifiable type Equatable and Hashable.
public extension Unitary {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

public struct SimpleAvatar: Avatar {
    public let image:   URL?
    public let tint:    Tint
    public let moniker: String

    public init(image: URL? = nil, tint: Tint, moniker: String) {
        self.image = image
        self.tint = tint
        self.moniker = moniker
    }
}

// MARK: - SwiftUI

public extension Tint {
    func color(opacity: Double = .on) -> Color {
        let components = self.extendedSRGB
        return Color(.sRGB, red: components.red, green: components.green, blue: components.blue, opacity: opacity)
    }
}

// MARK: - UIKit

extension UIColor: Tint {
    private static let extendedSRGBSpace = CGColorSpace(name: CGColorSpace.extendedSRGB)!

    public convenience init(_ tint: Tint, alpha: CGFloat = .on) {
        let components = tint.extendedSRGB
        self.init(red: components.red, green: components.green, blue: components.blue, alpha: alpha)
    }

    public var extendedSRGB: (red: Double, green: Double, blue: Double) {
        let components = self.cgColor.converted(to: Self.extendedSRGBSpace, intent: .defaultIntent, options: nil)?.components ?? []
        return (
            red: components.count >= 3 ? components[0] : .off,
            green: components.count >= 3 ? components[1] : .off,
            blue: components.count >= 3 ? components[2] : .off
        )
    }
}

public extension UIColor {
    // Extended sRGB, hex, RRGGBB / RRGGBBAA
    convenience init?(_ hex: String, alpha: CGFloat = .on) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb:   UInt64  = 0
        var red:   CGFloat = 0.0
        var green: CGFloat = 0.0
        var blue:  CGFloat = 0.0
        var alpha: CGFloat = alpha
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb)
        else { return nil }
        if hexSanitized.count == 6 {
            red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            blue = CGFloat(rgb & 0x0000FF) / 255.0
        }
        else if hexSanitized.count == 8 {
            red = CGFloat((rgb & 0xFF00_0000) >> 24) / 255.0
            green = CGFloat((rgb & 0x00FF_0000) >> 16) / 255.0
            blue = CGFloat((rgb & 0x0000_FF00) >> 8) / 255.0
            alpha *= CGFloat(rgb & 0x0000_00FF) / 255.0
        }
        else {
            return nil
        }

        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }

    var hex: String {
        var red = CGFloat(0), green = CGFloat(0), blue = CGFloat(0), alpha = CGFloat(0)
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return String(format: "%0.2lX%0.2lX%0.2lX,%0.2lX", Int(red * 255), Int(green * 255), Int(blue * 255), Int(alpha * 255))
    }

    var hue: CGFloat {
        var hue: CGFloat = 0
        self.getHue(&hue, saturation: nil, brightness: nil, alpha: nil)

        return hue
    }

    var saturation: CGFloat {
        var saturation: CGFloat = 0
        self.getHue(nil, saturation: &saturation, brightness: nil, alpha: nil)

        return saturation
    }

    var brightness: CGFloat {
        var brightness: CGFloat = 0
        self.getHue(nil, saturation: nil, brightness: &brightness, alpha: nil)

        return brightness
    }

    var alpha: CGFloat {
        var alpha: CGFloat = 0
        self.getHue(nil, saturation: nil, brightness: nil, alpha: &alpha)

        return alpha
    }

    func with(
        hue newHue: CGFloat? = nil,
        saturation newSaturation: CGFloat? = nil,
        brightness newBrightness: CGFloat? = nil,
        alpha newAlpha: CGFloat? = nil
    )
        -> UIColor {
        if newHue == nil, newSaturation == nil, newBrightness == nil, let newAlpha = newAlpha {
            return self.withAlphaComponent(newAlpha)
        }

        var hue:        CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha:      CGFloat = 0
        self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        return UIColor(
            hue: newHue ?? hue,
            saturation: newSaturation ?? saturation,
            brightness: newBrightness ?? brightness,
            alpha: newAlpha ?? alpha
        )
    }
}
