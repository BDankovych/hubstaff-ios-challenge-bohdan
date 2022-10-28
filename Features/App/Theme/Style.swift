//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Orchestration
import SwiftUI

public extension CGFloat {
    /// Used to create a visual outline or border around elements or within components.
    static let hsEdge:     Self = 2
    /// Used to separate elements that together contribute to the same semantic context.
    static let hsInternal: Self = 10
    /// Used to separate elements that relate directly to each other.
    static let hsRelated:  Self = 15
    /// Used to separate a set of related elements from a different set of unrelated elements.
    static let hsGroup:    Self = 20
    /// Used to create a strong semantic break between groups of elements.
    static let hsBreak:    Self = 30
    /// Used as the touch size of interactive elements and controls.
    static let hsControl:  Self = 44
    /// Used as the size of a semantic object.
    static let hsShape:    Self = 64
    /// Offset to use for pushing items horizontally beyond the screen boundaries.
    static let offScreen:  Self = -1000
}

public extension Font {
    /// For screens with a singular primary point of interest.
    static let hsDisplay:  Self = .system(size: 54, weight: .semibold, design: .default)
    /// For screens that utilize a title to introduce their content.
    static let hsLarge:    Self = .system(size: 24, weight: .medium, design: .default)
    /// A heading used to open a section for a type of content. Different headings show different types of content.
    static let hsTitle:    Self = .system(size: 18, weight: .semibold, design: .default)
    /// A segment of content. Segments show the same type of content, but a certain portion of it.
    static let hsSubtitle: Self = .system(size: 16, weight: .semibold, design: .default)
    /// Interactive elements and content.
    static let hsControl:  Self = .system(size: 15, weight: .medium, design: .default)
    /// Emphasized content.
    static let hsHeavy:    Self = .system(size: 14, weight: .semibold, design: .default)
    /// Base content.
    static let hsBody:     Self = .system(size: 14, weight: .regular, design: .default)
    /// Subordinate content. Additional information related to the base content.
    static let hsDetails:  Self = .system(size: 13, weight: .regular, design: .default)
    /// Descriptive heading for an object.
    static let hsCaption:  Self = .system(size: 12, weight: .medium, design: .default)
}

public extension UIFont {
    static let hsDisplay:  UIFont = .systemFont(ofSize: 54, weight: .semibold)
    static let hsLarge:    UIFont = .systemFont(ofSize: 24, weight: .medium)
    static let hsTitle:    UIFont = .systemFont(ofSize: 18, weight: .semibold)
    static let hsSubtitle: UIFont = .systemFont(ofSize: 16, weight: .semibold)
    static let hsControl:  UIFont = .systemFont(ofSize: 15, weight: .medium)
    static let hsHeavy:    UIFont = .systemFont(ofSize: 14, weight: .semibold)
    static let hsBody:     UIFont = .systemFont(ofSize: 14, weight: .regular)
    static let hsDetails:  UIFont = .systemFont(ofSize: 13, weight: .regular)
    static let hsCaption:  UIFont = .systemFont(ofSize: 12, weight: .medium)
}

// FIXME: https://bugs.swift.org/browse/SR-15853
public extension Tint where Self == UIColor {
    static var hsTint:        UIColor { UIColor(named: "hubstaff.tint") ?? .systemBlue }
    static var hsPrimary:     UIColor { UIColor(named: "hubstaff.text.primary") ?? .darkText }
    static var hsSecondary:   UIColor { UIColor(named: "hubstaff.text.secondary") ?? .lightText }
    static var hsGrayControl: UIColor { UIColor(named: "hubstaff.gray.control") ?? .systemFill }
    static var hsGrayFill:    UIColor { UIColor(named: "hubstaff.gray.fill") ?? .secondarySystemFill }
    static var hsGreen:       UIColor { UIColor(named: "hubstaff.green") ?? .systemGreen }
    static var hsPurple:      UIColor { UIColor(named: "hubstaff.purple") ?? .systemPurple }
    static var hsBlue:        UIColor { UIColor(named: "hubstaff.blue") ?? .systemBlue }
    static var hsBlueFill:    UIColor { UIColor(named: "hubstaff.blue.fill") ?? .systemBlue.withAlphaComponent(0.1) }
    static var hsOrange:      UIColor { UIColor(named: "hubstaff.orange") ?? .systemOrange }
    static var hsRed:         UIColor { UIColor(named: "hubstaff.red") ?? .systemRed }
    static var hsYellow:      UIColor { UIColor(named: "hubstaff.yellow") ?? .systemYellow }
    static var hsWarning:     UIColor { UIColor(named: "hubstaff.warning") ?? .systemRed }
}

public extension Color {
    static let hsTint        = Self("hubstaff.tint")
    static let hsPrimary     = Self("hubstaff.text.primary")
    static let hsSecondary   = Self("hubstaff.text.secondary")
    static let hsGrayControl = Self("hubstaff.gray.control")
    static let hsGrayFill    = Self("hubstaff.gray.fill")
    static let hsGreen       = Self("hubstaff.green")
    static let hsPurple      = Self("hubstaff.purple")
    static let hsBlue        = Self("hubstaff.blue")
    static let hsBlueFill    = Self("hubstaff.blue.fill")
    static let hsOrange      = Self("hubstaff.orange")
    static let hsRed         = Self("hubstaff.red")
    static let hsYellow      = Self("hubstaff.yellow")
    static let hsWarning     = Self("hubstaff.warning")
}

public extension Gradient {
    static let hsBlue    = Self(colors: [.hsBlue, Color("hubstaff.blue.gradient")])
    static let hsOrange  = Self(colors: [.hsOrange, Color("hubstaff.orange.gradient")])
    static let hsRed     = Self(colors: [.hsRed, Color("hubstaff.red.gradient")])
    static let hsGray    = Self(colors: [.hsGrayFill, .hsGrayControl])
    static let hsWarning = Self(colors: [.hsWarning, Color("hubstaff.warning.gradient")])
}

/// A shape that is a rectangle no smaller than the control size.
public struct ControlShape: Shape {
    public func path(in rect: CGRect) -> Path {
        Path {
            $0.addRect(CGRect(
                x: min(rect.minX, rect.midX - .hsControl / 2),
                y: min(rect.minY, rect.midY - .hsControl / 2),
                width: max(rect.width, .hsControl),
                height: max(rect.height, .hsControl)
            ))
        }
    }
}

public extension View {
    /// Apply the given style to the application UI.
    func style(_ style: Style) -> some View {
        style.apply(to: self)
    }
}

public enum Style {
    /// The standard appearance of the redesigned Hubstaff application.
    case hubstaff

    public func apply<V: View>(to view: V) -> some View {
        UIScrollView.appearance().keyboardDismissMode = .interactive

        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.setBackIndicatorImage(UIImage(named: "arrow.backward"), transitionMaskImage: UIImage(named: "arrow.backward"))
        navBarAppearance.backButtonAppearance.normal.titlePositionAdjustment = .init(horizontal: .offScreen, vertical: .zero)
        navBarAppearance.shadowColor = nil
        navBarAppearance.shadowColor = .white
        navBarAppearance.titleTextAttributes = [.font: UIFont.hsTitle, .foregroundColor: UIColor.hsPrimary]
        navBarAppearance.backgroundEffect = nil
        navBarAppearance.backgroundColor = .white.withAlphaComponent(0.85)
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactScrollEdgeAppearance = navBarAppearance

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = .hsPrimary
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes[.foregroundColor] = UIColor.hsPrimary
        tabBarAppearance.shadowColor = .hsGrayFill.with(brightness: 0.85)
        tabBarAppearance.backgroundEffect = nil
        navBarAppearance.backgroundColor = .white.withAlphaComponent(0.85)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        return view
            .modifier(OpenURLInSheet())
            .preferredColorScheme(.light)
            .environment(\.defaultMinListRowHeight, .zero)
            .environment(\.defaultMinListHeaderHeight, .zero)
            .listStyle(.plain)
            .buttonStyle(.hsClear)
            .foregroundColor(.hsPrimary)
            .accentColor(.hsTint)
            .font(.hsBody)
            .submitLabel(.done)
    }
}

/// Open URLs in a sheet inside the app, rather than leaving the app and opening an external browser.
private struct OpenURLInSheet: ViewModifier {
    @State
    private var showPage: Page?

    func body(content: Content) -> some View {
        content
            .environment(\.openURL, OpenURLAction { url in
                switch url.scheme {
                    case "http", "https":
                        self.showPage = Page(id: url)
                        return .handled
                    default:
                        return .systemAction
                }
            })
            // FIXME: .sheet(item: self.$showPage) { doesn't work; figure out why.
            .sheet(isPresented: .constant(self.showPage != nil)) {
                self.showPage.flatMap {
                    WebPage(url: $0.id) { _ in
                        self.showPage = nil
                    }
                    .style(.hubstaff)
                }
            }
    }

    private struct Page: Identifiable {
        var id: URL
    }
}
