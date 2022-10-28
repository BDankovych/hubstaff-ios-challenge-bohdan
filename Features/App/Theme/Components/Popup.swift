//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Foundation
import Orchestration
import SwiftUI

public extension View {
    /// Present a pop-up sheet when the `item` binding's value is set.
    ///
    /// The alignment values will determine the pop-up's appearance transition: edge alignment will create a slide transition.
    /// If an alignment axis is unset, the pop-up will fill the available space on that axis.
    ///
    /// - Parameters:
    ///   - title: A short string introducing the pop-up's purpose to the user.
    ///   - item: The item value to pass into the pop-up's content. The pop-up appears only when this value is set and disappears when it is cleared.
    ///   - horizontal: How to present the pop-up horizontally within the available space.
    ///   - vertical: How to present the pop-up vertically within the available space.
    ///   - cancelable: A cancelable pop-up can be dismissed by the user when tapping the shroud or through a default close control.
    ///   - content: The content that the pop-up was created to host; it appears within the padded alignment area after the title.
    ///   - control: A custom view that has access to the entire alignment area. If unspecified and cancelable, pop-ups will provide a close button.
    func popup<Item, Content: View>(
        title: String, item: Binding<Item?>,
        horizontal: HorizontalAlignment? = nil, vertical: VerticalAlignment? = .bottom, cancelable: Bool = true,
        @ViewBuilder content: @escaping (Item) -> Content,
        control: (() -> AnyView)? = nil
    )
        -> some View {
        self.popup(title: title, isPresented: Binding(
            get: { item.wrappedValue != nil },
            set: { item.wrappedValue = $0 ? item.wrappedValue : nil }
        ), horizontal: horizontal, vertical: vertical, cancelable: cancelable, content: {
            content(item.wrappedValue!)
        }, control: control)
    }

    /// Present a pop-up sheet when the `isPresented` binding is `true`.
    ///
    /// The alignment values will determine the pop-up's appearance transition: edge alignment will create a slide transition.
    /// If an alignment axis is unset, the pop-up will fill the available space on that axis.
    ///
    /// - Parameters:
    ///   - title: A short string introducing the pop-up's purpose to the user.
    ///   - isPresented: The pop-up appears only when this value is `true` and disappears when it is `false`.
    ///   - horizontal: How to present the pop-up horizontally within the available space.
    ///   - vertical: How to present the pop-up vertically within the available space.
    ///   - cancelable: A cancelable pop-up can be dismissed by the user when tapping the shroud or through a default close control.
    ///   - content: The content that the pop-up was created to host; it appears within the padded alignment area after the title.
    ///   - control: A custom view that has access to the entire alignment area. If unspecified and cancelable, pop-ups will provide a close button.
    func popup<Content: View>(
        title: String, isPresented: Binding<Bool>,
        horizontal: HorizontalAlignment? = nil, vertical: VerticalAlignment? = .bottom, cancelable: Bool = true,
        @ViewBuilder content: @escaping () -> Content,
        control: (() -> AnyView)? = nil
    )
        -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity)
            // Shroud
            .overlay(
                Color.black.opacity(isPresented.wrappedValue ? 0.4 : .off)
                    .animation(.default, value: isPresented.wrappedValue)
                    .edgesIgnoringSafeArea(.all)
                    .contentShape(Rectangle())
                    .allowsHitTesting(isPresented.wrappedValue && cancelable)
                    .onTapGesture { isPresented.wrappedValue = false }
            )
            // Pop-up
            .overlay(!isPresented.wrappedValue ? nil : PopupView(
                title: title, isPresented: isPresented, horizontal: horizontal, vertical: vertical, cancelable: cancelable,
                content: { AnyView(content()) }, control: control
            ))
    }

    /// Present a pop-up alert when the `item` binding's value is set.
    ///
    /// Alerts are a type of pop-up that always appears center-aligned and provides a convenient API for supplying action buttons.
    /// They have no close button, instead the user interacts with the alert through a set of actions.
    ///
    /// - Parameters:
    ///   - title: A short string introducing the alert's purpose to the user.
    ///   - item: The item value to pass into the alert's actions and content. The alert appears only when this value is set and disappears when it is cleared.
    ///   - cancelable: A cancelable alert can be dismissed by the user when tapping the shroud.
    ///   - actions: A set of controls for the user to act upon the alert. `Button`s will be styled to match the alert.
    ///   - content: The content that the alert was created to host; it appears within the padded alignment area after the title.
    func popup<Item, Actions: View, Content: View>(
        alert title: String, item: Binding<Item?>, cancelable: Bool = true,
        @ViewBuilder actions: @escaping (Item) -> Actions, // = { _ in Button("OK") },
        @ViewBuilder content: @escaping (Item) -> Content
    )
        -> some View {
        self.popup(alert: title, isPresented: Binding(
            get: { item.wrappedValue != nil },
            set: { item.wrappedValue = $0 ? item.wrappedValue : nil }
        ), cancelable: cancelable) {
            actions(item.wrappedValue!)
        } content: {
            content(item.wrappedValue!)
        }
    }

    /// Present a pop-up alert when the `isPresented` binding is `true`.
    ///
    /// Alerts are a type of pop-up that always appears center-aligned and provides a convenient API for supplying action buttons.
    /// They have no close button, instead the user interacts with the pop-up through a set of actions.
    ///
    /// - Parameters:
    ///   - title: A short string introducing the alert's purpose to the user.
    ///   - isPresented: The alert appears only when this value is `true` and disappears when it is `false`.
    ///   - cancelable: A cancelable alert can be dismissed by the user when tapping the shroud.
    ///   - actions: A set of controls for the user to act upon the alert. `Button`s will be styled to match the alert.
    ///   - content: The content that the alert was created to host; it appears within the padded alignment area after the title.
    func popup<Actions: View, Content: View>(
        alert title: String, isPresented: Binding<Bool>, cancelable: Bool = true,
        @ViewBuilder actions: @escaping () -> Actions,
        @ViewBuilder content: @escaping () -> Content
    )
        -> some View {
        self.popup(title: title, isPresented: isPresented, horizontal: .center, vertical: .center, cancelable: cancelable) {
            content()
            Spacer().frame(height: .hsControl - .hsGroup)
        } control: {
            AnyView(
                HStack {
                    actions()
                }
                .padding(.trailing, -1)
                .buttonStyle(AlertButtonStyle(isPresented: isPresented))
                .overlay(Divider(), alignment: .top)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            )
        }
    }
}

private struct PopupView: View {
    var title:       String
    var isPresented: Binding<Bool>
    var horizontal:  HorizontalAlignment?
    var vertical:    VerticalAlignment?
    var cancelable:  Bool
    var content:     () -> AnyView
    var control:     (() -> AnyView)?

    @State
    private var contentHeight = ContentHeightPreference()

    var body: some View {
        VStack(spacing: .zero) {
            Text(self.title)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .hsControl)
                .padding(.vertical, .hsRelated)
                .font(.hsTitle)

            ScrollView {
                VStack(spacing: .hsGroup) {
                    self.content()
                }
                .padding(.horizontal, .hsGroup)
                .padding(.bottom, .hsRelated)
                .geometryReader(into: ContentHeightPreference.self) { $0.size.height }
                .onPreferenceChange(into: ContentHeightPreference.self, update: self.$contentHeight)
            }
            .frame(maxHeight: self.contentHeight.value)
        }
        .buttonStyle(.hsRounded())
        .frame(
            maxWidth: self.horizontal == nil ? .infinity : nil,
            maxHeight: self.vertical == nil ? .infinity : nil
        )
        .overlay(self.control?() ?? (self.cancelable ? AnyView(PopupCloseButton(isPresented: self.isPresented)) : AnyView(EmptyView())))
        .background(Color.white)
        .cornerRadius(.hsGroup)
        .padding(.hsInternal)
        .frame(
            maxWidth: .infinity, maxHeight: .infinity,
            alignment: .init(horizontal: self.horizontal ?? .center, vertical: self.vertical ?? .center)
        )
        .transition(self.transition)
    }

    private var transition: AnyTransition {
        map(from: self.horizontal, where: [
            (if: .leading, then: .move(edge: .leading)),
            (if: .trailing, then: .move(edge: .trailing)),
        ]) ?? map(from: self.vertical, where: [
            (if: .top, then: .move(edge: .top)),
            (if: .bottom, then: .move(edge: .bottom)),
        ]) ?? .scale.combined(with: .opacity).animation(.interactiveSpring())
    }

    struct ContentHeightPreference: MaxValuePreference {
        var value: CGFloat?
    }
}

private struct PopupCloseButton: View {
    let isPresented: Binding<Bool>

    var body: some View {
        Button {
            self.isPresented.wrappedValue = false
        } label: {
            Image(named: "xmark")
                .resizable()
                .frame(width: .hsInternal, height: .hsInternal)
                .foregroundColor(.black)
                .frame(width: .hsControl, height: .hsControl)
                .background(
                    Circle()
                        .frame(width: .hsGroup, height: .hsGroup)
                        .foregroundColor(Color(UIColor.systemGray5))
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
    }
}

private struct AlertButtonStyle: PrimitiveButtonStyle {
    let isPresented: Binding<Bool>

    func makeBody(configuration: Configuration) -> some View {
        Button {
            self.isPresented.wrappedValue = false
            configuration.trigger()
        } label: {
            configuration.label
                .font(.hsControl)
                .foregroundColor(.hsPrimary)
                .frame(maxWidth: .infinity, minHeight: .hsControl)
                .overlay(HStack { Divider() }, alignment: .trailing)
                .contentShape(Rectangle())
        }
    }
}

#if DEBUG
struct Popup_Previews: PreviewProvider {
    static var isPresented: Binding<Bool> = .constant(false)

    static var previews: some View {
        NavigationView {
            PopupScreen(model: .init(
                background: .white,
                content: "How do you feel?",
                happy: "🤩", sad: "🤯"
            ), configuration: (true, nil, nil))
                .navigationBarTitle("Popups")
        }
        .previewDisplayName("Alert")
        .style(.hubstaff)
    }

    struct PopupScreen: View {
        struct Model {
            var background: Color
            var content:    String
            var happy:      String
            var sad:        String
        }

        @State
        var model:         Model
        @State
        var configuration: (cancelable: Bool, vertical: VerticalAlignment?, horizontal: HorizontalAlignment?)

        @State private var isSheetPresented = false
        @State private var presentedSheet: Model?
        @State private var isAlertPresented = false
        @State private var presentedAlert: Model?
        @State private var text             = ""

        var body: some View {
            VStack {
                // Direction
                Text("Configuration")
                    .font(.hsTitle)
                Toggle("Cancelable", isOn: self.$configuration.cancelable)
                Text("Horizontal")
                    .font(.hsSubtitle)
                HStack {
                    Button {
                        self.configuration.horizontal = nil
                    } label: {
                        Image(named: "text.justify")
                    }
                    .buttonStyle(.hsRounded(isInline: true))
                    Button {
                        self.configuration.horizontal = .leading
                    } label: {
                        Image(named: "text.alignleft")
                    }
                    .buttonStyle(.hsRounded(isInline: true))
                    Button {
                        self.configuration.horizontal = .center
                    } label: {
                        Image(named: "text.aligncenter")
                    }
                    .buttonStyle(.hsRounded(isInline: true))
                    Button {
                        self.configuration.horizontal = .trailing
                    } label: {
                        Image(named: "text.alignright")
                    }
                    .buttonStyle(.hsRounded(isInline: true))
                }
                Text("Vertical")
                    .font(.hsSubtitle)
                HStack {
                    Button {
                        self.configuration.vertical = nil
                    } label: {
                        Image(named: "rectangle.fill")
                    }
                    .buttonStyle(.hsRounded(isInline: true))
                    Button {
                        self.configuration.vertical = .top
                    } label: {
                        Image(named: "square.tophalf.fill")
                    }
                    .buttonStyle(.hsRounded(isInline: true))
                    Button {
                        self.configuration.vertical = .center
                    } label: {
                        Image(named: "rectangle.center.inset.fill")
                    }
                    .buttonStyle(.hsRounded(isInline: true))
                    Button {
                        self.configuration.vertical = .bottom
                    } label: {
                        Image(named: "square.bottomhalf.fill")
                    }
                    .buttonStyle(.hsRounded(isInline: true))
                }

                VStack {
                    // Popups
                    Text("Popup")
                        .font(.hsTitle)
                    Button {
                        self.isSheetPresented = true
                    } label: {
                        Text("Simple Sheet")
                    }
                    .buttonStyle(.hsRounded(isInline: true))
                    Button {
                        self.presentedSheet = self.model
                    } label: {
                        Text("Dynamic Sheet")
                    }
                    .buttonStyle(.hsRounded(isInline: true))

                    // Alerts
                    Text("Alert")
                        .font(.hsTitle)
                    Button {
                        self.isAlertPresented = true
                    } label: {
                        Text("Simple Alert")
                    }
                    .buttonStyle(.hsRounded(isInline: true))
                    Button {
                        self.presentedAlert = self.model
                    } label: {
                        Text("Dynamic Alert")
                    }
                    .buttonStyle(.hsRounded(isInline: true))
                }
            }
            .padding(.hsGroup)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(self.model.background.edgesIgnoringSafeArea(.all))

            .popup(
                title: "Simple Sheet",
                isPresented: self.$isSheetPresented,
                horizontal: self.configuration.horizontal,
                vertical: self.configuration.vertical,
                cancelable: self.configuration.cancelable
            ) {
                Text(self.model.content)
                Button {
                    self.model.background = .hsGreen
                } label: {
                    Text(self.model.happy)
                }
                .buttonStyle(.hsRounded(isInline: true))
                Button {
                    self.model.background = .hsRed
                } label: {
                    Text(self.model.sad)
                }
                .buttonStyle(.hsRounded(isInline: true))
                Group {
                    ForEach(0 ..< 10) { i in
                        Button {} label: {
                            Text(Array(repeating: "Badger", count: i).joined(separator: " "))
                        }
                        .buttonStyle(.hsRounded(isInline: true))
                    }
                }
            }

            .popup(
                title: "Dynamic Sheet",
                item: self.$presentedSheet,
                horizontal: self.configuration.horizontal,
                vertical: self.configuration.vertical,
                cancelable: self.configuration.cancelable
            ) { item in
                Text(item.content)
                Button {
                    self.model.background = .hsGreen
                    self.presentedSheet?.background = .hsGreen
                    self.text += item.happy
                } label: {
                    Text(item.happy)
                }
                .buttonStyle(.hsRounded(isInline: true))
                Button {
                    self.model.background = .hsRed
                    self.presentedSheet?.background = .hsRed
                    self.text += item.sad
                } label: {
                    Text(item.sad)
                }
                .buttonStyle(.hsRounded(isInline: true))
                TextField("Tell us how you really feel", text: self.$text)
            }

            .popup(
                alert: "Simple Alert",
                isPresented: self.$isAlertPresented,
                cancelable: self.configuration.cancelable
            ) {
                Button {
                    self.model.background = .hsGreen
                } label: {
                    Text(self.model.happy)
                }
                Button {
                    self.model.background = .hsRed
                } label: {
                    Text(self.model.sad)
                }
            } content: {
                Text(self.model.content)
                Button {} label: {
                    Text(self.model.happy)
                }
                .buttonStyle(.hsRounded(isInline: true))
                Button {} label: {
                    Text(self.model.sad)
                }
                .buttonStyle(.hsRounded(isInline: true))
            }

            .popup(
                alert: "Dynamic Alert",
                item: self.$presentedAlert,
                cancelable: self.configuration.cancelable
            ) { item in
                Button {
                    self.model.background = .hsGreen
                } label: {
                    Text(item.happy)
                }
                Button {
                    self.model.background = .hsRed
                } label: {
                    Text(item.sad)
                }
            } content: { item in
                Text(item.content)
                Button {
                    self.presentedAlert?.background = .hsGreen
                    self.text += item.happy
                } label: {
                    Text(item.happy)
                }
                .buttonStyle(.hsRounded(isInline: true))
                Button {
                    self.presentedAlert?.background = .hsRed
                    self.text += item.sad
                } label: {
                    Text(item.sad)
                }
                .buttonStyle(.hsRounded(isInline: true))
                TextField("Tell us how you really feel", text: self.$text)
            }
        }
    }
}
#endif
