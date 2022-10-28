//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import SwiftUI

extension View {
    /// Wrap in a button that opens the web page for a URL.
    func button(link url: @autoclosure @escaping () -> URL?) -> some View {
        self.modifier(LinkURLModifier(url: url))
    }

    /// Wrap in a button that opens the web page for an `async` URL.
    func button(link url: @escaping () async -> URL?) -> some View {
        self.modifier(LinkAsyncURLModifier(url: url))
    }
}

private struct LinkAsyncURLModifier: ViewModifier {
    let url: () async -> URL?

    @Environment(\.openURL)
    private var action: OpenURLAction

    func body(content: Content) -> some View {
        Button {
            Task {
                await self.url().flatMap(self.action.callAsFunction)
            }
        } label: {
            content.foregroundColor(.accentColor)
        }
    }
}

private struct LinkURLModifier: ViewModifier {
    let url: () -> URL?

    @Environment(\.openURL)
    private var action: OpenURLAction

    func body(content: Content) -> some View {
        Button {
            self.url().flatMap(self.action.callAsFunction)
        } label: {
            content.foregroundColor(.accentColor)
        }
    }
}

public extension ButtonStyle where Self == ClearButtonStyle {
    /// A button with no decoration.
    ///
    /// The default font for button labels is control.
    /// The foreground color for button labels is the accent color.
    /// The touch area for button labels is its frame, but either dimension can be no smaller than the control size.
    static var hsClear: Self { Self() }
}

public extension ButtonStyle where Self == ClearControlButtonStyle {
    /// Identical to ClearButtonStyle, but the button's whole layout frame is no smaller than the control size.
    static var hsClearControl: Self { Self() }
}

public extension ButtonStyle where Self == RoundedButtonStyle {
    /// A button with rounded decoration.
    ///
    /// The default font for button labels is control, except for plain style (where it is unchanged).
    /// Primary buttons use the style's body for their label's foreground color. Non-primary buttons use the tint.
    /// Primary buttons use the style's tint for a background fill. Non-primary buttons use the body for a border.
    /// Regular buttons are at least control sized. Inline buttons are at least break-height.
    /// The touch area for button labels is its frame, but either dimension can be no smaller than the control size.
    static func hsRounded(
        isPrimary: Bool = true,
        isInline: Bool = false,
        style: Self.Style = .accented,
        inactiveStyle: Self.Style? = nil
    )
        -> Self {
        Self(isPrimary: isPrimary, isInline: isInline, style: style, inactiveStyle: inactiveStyle)
    }
}

public struct ClearButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: .hsInternal) {
            configuration.label
        }
        .font(.hsControl)
        .foregroundColor(.accentColor)
        .opacity(configuration.isPressed ? 0.3 : .on)
        .contentShape(ControlShape())
    }
}

public struct ClearControlButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(minWidth: .hsControl, minHeight: .hsControl)
    }
}

public struct RoundedButtonStyle: ButtonStyle {
    public var isPrimary:     Bool
    public var isInline:      Bool
    public var style:         Style
    public var inactiveStyle: Style?

    public enum Style {
        /// A very subtly decorated button with a gray tint. Its label properties are inherited from the current view context.
        case plain
        /// A bright decoration based on the context's accent color.
        case accented
        /// A decoration that stands out to alert the user that this action requires special consideration.
        case destructive

        var tint: Color {
            switch self {
                case .plain:
                    return .hsGrayFill
                case .accented:
                    return .accentColor
                case .destructive:
                    return .hsRed
            }
        }

        var body: Color? {
            switch self {
                case .plain:
                    return nil
                default:
                    return .white
            }
        }

        var font: Font? {
            switch self {
                case .plain:
                    return nil
                default:
                    return .hsControl
            }
        }
    }

    @Environment(\.isOptionSelected)
    private var isOptionSelected: Bool

    private var effectiveStyle: Style {
        self.isOptionSelected ? self.style : self.inactiveStyle ?? self.style
    }

    public func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: .hsInternal) {
            configuration.label
        }
        .if(self.isInline) {
            $0.frame(minWidth: .hsControl, minHeight: .hsBreak)
                .padding(.horizontal, .hsRelated)
        } else: {
            $0.frame(minWidth: .hsControl, maxWidth: .infinity, minHeight: .hsControl)
        }
        .font(self.effectiveStyle.font)
        .if(self.isPrimary) {
            $0.foregroundColor(self.effectiveStyle.body).background(self.effectiveStyle.tint)
                .if(self.isInline) {
                    $0.clipShape(Capsule())
                } else: {
                    $0.clipShape(RoundedRectangle(cornerRadius: .hsInternal))
                }
        } else: {
            $0.foregroundColor(self.effectiveStyle.tint)
                .if(self.isInline) {
                    $0.overlay(Capsule().strokeBorder(self.effectiveStyle.tint))
                } else: {
                    $0.overlay(RoundedRectangle(cornerRadius: .hsInternal).strokeBorder(self.effectiveStyle.tint))
                }
        }
        .opacity(configuration.isPressed ? 0.3 : .on)
        .contentShape(ControlShape())
    }
}

#if DEBUG
struct Button_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Button {} label: { Text("clear button") }

            Button {} label: { Text("plain button") }
                .buttonStyle(.hsRounded(style: .plain))
            Button {} label: { Text("primary button") }
                .buttonStyle(.hsRounded())
            Button {} label: { Text("secondary button") }
                .buttonStyle(.hsRounded(isPrimary: false))
            Button {} label: { Text("destructive primary button") }
                .buttonStyle(.hsRounded(isPrimary: true, style: .destructive))
            Button {} label: { Text("destructive secondary button") }
                .buttonStyle(.hsRounded(isPrimary: false, style: .destructive))
            Button {} label: { Text("primary inline") }
                .buttonStyle(.hsRounded(isInline: true))
            Button {} label: { Text("secondary inline") }
                .buttonStyle(.hsRounded(isPrimary: false, isInline: true))
        }
        .previewDisplayName("Button")
        .previewLayout(.sizeThatFits)
        .style(.hubstaff)
    }
}
#endif
