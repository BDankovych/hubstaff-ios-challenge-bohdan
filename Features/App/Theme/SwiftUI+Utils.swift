//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

/// The purpose of this file is to extend features introduced by the SwiftUI Framework.
import Combine
import Orchestration
import SwiftUI
import UIKit

public func isPreview() -> Bool {
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}

// MARK: - Localized Formatting

public extension String.StringInterpolation {
    mutating func appendInterpolation<Value: BinaryInteger>(_ number: Value, format: String) {
        let formatter = NumberFormatter()
        formatter.negativeFormat = format
        formatter.positiveFormat = format

        if let value = number as? NSNumber, let string = formatter.string(from: value) {
            self.appendLiteral(string)
        }
    }
}

// MARK: - Conditional View Attributes

extension View {
    /// An item in a list that uses separators (but only between the items).
    ///
    /// The default inset is the full standard item inset since it defines the spacing between the item and the separator.
    func listRowInternalSeparators<C: BidirectionalCollection>(
        item: C.Element, in collection: C, inset: EdgeInsets = .hsItem
    )
        -> some View where C.Element: Identifiable {
        self.listRowInternalSeparators(item: item, in: collection, id: \.id, inset: inset)
    }

    /// An item in a list that uses separators (but only between the items).
    ///
    /// The default inset is the full standard item inset since it defines the spacing between the item and the separator.
    func listRowInternalSeparators<ID: Hashable, C: BidirectionalCollection>(
        item: C.Element, in collection: C, id: KeyPath<C.Element, ID>, inset: EdgeInsets = .hsItem
    )
        -> some View {
        self.listRowInternalSeparators(
            isFirst: item[keyPath: id] == collection.first?[keyPath: id],
            isLast: item[keyPath: id] == collection.last?[keyPath: id],
            inset: inset
        )
    }

    /// An item in a list that uses separators (but only between the items).
    ///
    /// The default inset is the full standard item inset since it defines the spacing between the item and the separator.
    @ViewBuilder
    func listRowInternalSeparators(isFirst: Bool, isLast: Bool, inset: EdgeInsets = .hsItem) -> some View {
        self.listRowSeparator(.hidden, edges: (isFirst ? .top : VerticalEdge.Set()).union(isLast ? .bottom : VerticalEdge.Set()))
            .listRowInsets(inset)
    }

    /// An item in a list that has no separators.
    ///
    /// The default inset is the shared (vertically half) standard item inset since it defines the spacing between the item half way down to the next item.
    @ViewBuilder
    func listRowNoSeparators(inset: EdgeInsets = .hsSharedItem) -> some View {
        self.listRowSeparator(.hidden).listRowInsets(inset)
    }
}

extension View {
    /// Modify the view using a view builder.
    func modify<T: View>(@ViewBuilder _ operation: (Self) -> T) -> T {
        operation(self)
    }

    /// Transform the view based on a shared value computed once.
    ///
    /// - Parameters:
    ///   - value: The value that the transformations will be based upon.
    ///   - transform: The transformation apply to this view.
    ///
    /// - Returns: The View resulting from the transformation.
    @ViewBuilder
    func with<V, R: View>(_ value: V, @ViewBuilder apply transform: (Self, V) -> R)
        -> some View {
        transform(self, value)
    }

    /// Execute a block that can transform the view, only if the given value is not `nil`.
    ///
    /// - Parameters:
    ///   - value: The value that whose non-`nil` will trigger the view transformation.
    ///   - then: A transformation to run for the current view, using the non-`nil` value, if present.
    ///
    /// - Warning: SwiftUI cannot animate gracefully between the branches of this conditional & will fall back to a fade transition for the view!
    /// - Returns: The View resulting from the then-transformation if the value is not `nil` or
    ///            the current view, untransformed, otherwise.
    @ViewBuilder
    func `if`<V, R: View>(`let` value: @autoclosure () -> V?,
                          @ViewBuilder then truely: (Self, V) -> R)
        -> some View {
        if let value = value() {
            truely(self, value).tag(1)
        }
        else {
            self.tag(1)
        }
    }

    /// Execute a block that can transform the view, only if both given value are not `nil`.
    ///
    /// - Parameters:
    ///   - value1: The first value whose non-`nil` will trigger the view transformation.
    ///   - value2: The second value whose non-`nil` will trigger the view transformation.
    ///   - then: A transformation to run for the current view, using the non-`nil` values, if present.
    ///
    /// - Warning: SwiftUI cannot animate gracefully between the branches of this conditional & will fall back to a fade transition for the view!
    /// - Returns: The View resulting from the then-transformation if the values are not `nil` or
    ///            the current view, untransformed, otherwise.
    @ViewBuilder
    func `if`<V1, V2, R: View>(`let` value1: @autoclosure () -> V1?, `let` value2: @autoclosure () -> V2?,
                               @ViewBuilder then truely: (Self, V1, V2) -> R)
        -> some View {
        if let value1 = value1(), let value2 = value2() {
            truely(self, value1, value2).tag(1)
        }
        else {
            self.tag(1)
        }
    }

    /// Execute a block that can transform the view, only if the conditions pass.
    ///
    /// - Parameters:
    ///   - condition: This condition must evaluate to `true` to allow the block to execute.
    ///   - available: The given operating system must be available at runtime to allow the block to execute.
    ///   - then: A transformation to run for the current view, only if all conditions pass.
    ///
    /// - Warning: SwiftUI cannot animate gracefully between the branches of this conditional & will fall back to a fade transition for the view!
    /// - Returns: The View resulting from the then-transformation if the conditions pass or
    ///            the current view, untransformed, otherwise.
    @ViewBuilder func `if`<V1: View>(
        _ condition: @autoclosure () -> Bool = true, @ViewBuilder then truely: (Self) -> V1
    )
        -> some View {
        self.if(condition(), then: truely, else: { $0 })
    }

    /// Execute a block that transforms the view if the conditions pass, or another if they do not.
    ///
    /// - Parameters:
    ///   - condition: This condition must evaluate to `true` to allow the block to execute.
    ///   - available: The given operating system must be available at runtime to allow the block to execute.
    ///   - then: A transformation to run for the current view, only if all conditions pass.
    ///   - else: A transformation to run for the current view, only if any conditions fail.
    ///
    /// - Warning: SwiftUI cannot animate gracefully between the branches of this conditional & will fall back to a fade transition for the view!
    /// - Returns: The View resulting from the then-transformation if the conditions pass or
    ///            the View resulting from the else-transformation otherwise.
    @ViewBuilder func `if`<V1: View, V2: View>(
        _ condition: @autoclosure () -> Bool = true, @ViewBuilder then truely: (Self) -> V1, @ViewBuilder else falsely: (Self) -> V2
    )
        -> some View {
        if condition() {
            truely(self).tag(1)
        }
        else {
            falsely(self).tag(1)
        }
    }
}

/// Add fixed-size space between views that may be compressed when there isn't enough space on screen to fit the full layout.
public struct Stud: View {
    /// Compress no more than this amount.
    public var minLength: CGFloat = .hsInternal
    /// The size of the spacer when it isn't limited by available space.
    public var maxLength: CGFloat = .hsBreak

    public var body: some View {
        Path().frame(
            minWidth: self.minLength, maxWidth: self.maxLength,
            minHeight: self.minLength, maxHeight: self.maxLength
        ).layoutPriority(-1)
    }
}

/// Type-erase any view that conforms to Equatable.
public struct AnyEquatableView: View {
    public init() {
        self.init(EmptyView())
    }

    public init<V: View & Equatable>(_ content: V) {
        self.storage = content
        self.body = AnyView(content)
        self.isEqualTo = { content == $0.storage as? V }
    }

    public init<V: View, E: Equatable>(_ content: V, id: E) {
        self.storage = id
        self.body = AnyView(content)
        self.isEqualTo = { id == $0.storage as? E }
    }

    public var  body:      AnyView

    // - Private
    private let storage:   Any
    private let isEqualTo: (AnyEquatableView) -> Bool
}

extension AnyEquatableView: Equatable {
    public static func == (lhs: AnyEquatableView, rhs: AnyEquatableView) -> Bool {
        lhs.isEqualTo(rhs)
    }
}

extension EmptyView: Equatable {
    public static func == (lhs: EmptyView, rhs: EmptyView) -> Bool {
        true
    }
}

extension Image {
    /// Obtain an image asset, falling back to a system symbol.
    init(named name: String) {
        if UIImage(named: name) != nil {
            self.init(name)
        }
        else {
            self.init(systemName: name)
        }
    }
}

// MARK: - View Preferences

public extension PreferenceKey where Value == Self {
    static func reduce(value: inout Self, nextValue: () -> Self) {
        value = nextValue()
    }
}

public extension PreferenceKey where Value == Self? {
    static func reduce(value: inout Self?, nextValue: () -> Self?) {
        nextValue().flatMap { value = $0 }
    }
}

public protocol PreferenceHolder: PreferenceKey {
    var value: Self.Value { get set }
}

/// A preference whose aggregated value is the largest one received from each of the children in the layout.
public protocol MaxValuePreference: PreferenceHolder {}

public extension MaxValuePreference {
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        let currentValue = value, nextValue = nextValue()

        if let currentValue = currentValue {
            if let nextValue = nextValue {
                value = max(currentValue, nextValue)
            }
            else {
                value = currentValue
            }
        }
        else {
            value = nextValue
        }
    }
}

public extension View {
    /// Advertise geometry information from this view through the given preference key.
    func geometryReader<K>(into holder: K.Type, value: @escaping (GeometryProxy) -> K.Value)
        -> some View where K: PreferenceKey {
        self.background(GeometryReader {
            Color.clear.preference(key: holder, value: value($0))
        })
    }

    /// Advertise a geometry anchor from this view through the given preference key.
    func geometryReader<K>(into holder: K.Type, anchor: Anchor<K.Value>.Source)
        -> some View where K: PreferenceKey {
        self.background(GeometryReader { proxy in
            Color.clear.anchorPreference(key: holder, value: anchor, transform: { proxy[$0] })
        })
    }

    /// Advertise a transformed geometry anchor from this view through the given preference key.
    func geometryReader<K, A>(into holder: K.Type, anchor: Anchor<A>.Source, transform: @escaping (A) -> K.Value)
        -> some View where K: PreferenceKey {
        self.background(GeometryReader { proxy in
            Color.clear.anchorPreference(key: holder, value: anchor, transform: { transform(proxy[$0]) })
        })
    }

    /// Store the aggregated preference values on a key that is a holder into a binding for it.
    func onPreferenceChange<H>(into holder: H.Type, update holderBinding: Binding<H>)
        -> some View where H: PreferenceHolder, H.Value: Equatable {
        self.onPreferenceChange(holder) {
            holderBinding.wrappedValue.value = $0
        }
    }
}

struct StatusBarStyleKey: PreferenceKey {
    static func reduce(value: inout UIStatusBarStyle?, nextValue: () -> UIStatusBarStyle?) {
        nextValue().flatMap { value = $0 }
    }
}

struct InterfaceOrientationMaskKey: PreferenceKey {
    static func reduce(value: inout UIInterfaceOrientationMask?, nextValue: () -> UIInterfaceOrientationMask?) {
        nextValue().flatMap { value = $0 }
    }
}

extension View {
    func statusBar(style: UIStatusBarStyle?) -> some View {
        self.preference(key: StatusBarStyleKey.self, value: style)
    }

    func supportedOrientation(mask: UIInterfaceOrientationMask) -> some View {
        self.preference(key: InterfaceOrientationMaskKey.self, value: mask)
    }
}

public extension EnvironmentValues {
    /// Indicates whether the view is currently highlighted as the option that would be selected in a selection control.
    var isOptionHighlighted: Bool {
        get { self[HighlightedKey.self] }
        set { self[HighlightedKey.self] = newValue }
    }

    /// Indicates whether the view is currently the selected option in a selection control.
    var isOptionSelected:    Bool {
        get { self[SelectionKey.self] }
        set { self[SelectionKey.self] = newValue }
    }

    private struct HighlightedKey: EnvironmentKey {
        static let defaultValue = false
    }

    private struct SelectionKey: EnvironmentKey {
        static let defaultValue = false
    }
}

// MARK: - View Features

public extension View {
    /// Specify a corner radius only on certain corners.
    internal func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        self.clipShape(RoundedCorner(radius: radius, corners: corners))
    }

    /// Perform an action with the initial value as well as whenever the value changes.
    @inlinable @ViewBuilder
    func onValue<V: Equatable>(of value: V, perform action: @escaping (_ newValue: V) -> Void) -> some View {
        self.onFirstAppear { action(value) }
            .onChange(of: value, perform: action)
    }

    /// Perform an initial action with the binding as well as whenever its value changes.
    @inlinable @ViewBuilder
    func onValue<V: Equatable>(of binding: Binding<V>, perform action: @escaping (_ binding: Binding<V>) -> Void) -> some View {
        self.onFirstAppear { action(binding) }
            .onChange(of: binding.wrappedValue) { _ in action(binding) }
    }

    @ViewBuilder
    func onFirstAppear(perform action: (() -> Void)? = nil) -> some View {
        self.modifier(OnFirstAppear(action: action))
    }
}

private struct OnFirstAppear: ViewModifier {
    let action: (() -> Void)?

    @State
    private var isAppeared = false

    func body(content: Content) -> some View {
        content.onAppear {
            if !self.isAppeared {
                self.isAppeared = true
                self.action?()
            }
        }
    }
}

public extension EdgeInsets {
    static let zero          = EdgeInsets()

    /// Standard edge spacing around enumerated items.
    static let hsItem        = EdgeInsets(top: .hsRelated, leading: .hsGroup, bottom: .hsRelated, trailing: .hsGroup)
    /// Standard edge spacing for enumerated items that share a vertical edge with adjacent items.
    static let hsSharedItem  = EdgeInsets(top: .hsRelated / 2, leading: .hsGroup, bottom: .hsRelated / 2, trailing: .hsGroup)
    /// Standard edge spacing for enumerated items that internalize their vertical space, such as to fully control the touch area.
    static let hsControlItem = EdgeInsets(top: .zero, leading: .hsGroup, bottom: .zero, trailing: .hsGroup)

    func with(top: CGFloat? = nil, leading: CGFloat? = nil, bottom: CGFloat? = nil, trailing: CGFloat? = nil) -> EdgeInsets {
        EdgeInsets(
            top: top ?? self.top,
            leading: leading ?? self.leading,
            bottom: bottom ?? self.bottom,
            trailing: trailing ?? self.trailing
        )
    }
}

public struct RoundedCorner: Shape {
    var radius:  CGFloat      = .infinity
    var corners: UIRectCorner = .allCorners

    public func path(in rect: CGRect) -> Path {
        Path(
            UIBezierPath(
                roundedRect: rect,
                byRoundingCorners: self.corners,
                cornerRadii: CGSize(width: self.radius, height: self.radius)
            )
            .cgPath
        )
    }
}

public extension Alignment {
    var text: TextAlignment {
        map(from: self.horizontal, where: [
            (if: .leading, then: .leading),
            (if: .center, then: .center),
            (if: .trailing, then: .trailing),
        ]) ?? .center
    }
}

// MARK: - UIKit

class NoSafeAreaHostingController: UIHostingController<AnyView> {
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        self.additionalSafeAreaInsets = .init(
            top: -(self.view.safeAreaInsets.top - self.additionalSafeAreaInsets.top),
            left: -(self.view.safeAreaInsets.left - self.additionalSafeAreaInsets.left),
            bottom: -(self.view.safeAreaInsets.bottom - self.additionalSafeAreaInsets.bottom),
            right: -(self.view.safeAreaInsets.right - self.additionalSafeAreaInsets.right)
        )
    }
}

// MARK: - Boilerplate

public extension Binding {
    /// Get a binding of a different value type that's based on this binding's value.
    func map<V>(_ transform: @escaping (Value) -> V, reverse: @escaping (V) -> Value) -> Binding<V> {
        Binding<V>(
            get: { transform(self.wrappedValue) },
            set: { self.wrappedValue = reverse($0) }
        )
    }

    /// Get a binding for a collection of items of a different value type that's based on the collection values in this binding.
    func map<C>(_ transform: @escaping (Value.Element) -> C.Element, reverse: @escaping (C.Element) -> Value.Element) -> Binding<C>
        where Value: Collection & ExpressibleBySequence, C: Collection & ExpressibleBySequence {
        Binding<C>(
            get: { C(self.wrappedValue.map(transform)) },
            set: { self.wrappedValue = Value($0.map(reverse)) }
        )
    }

    /// Get a binding for a collection of items of a different value type that's based on the collection values in this binding, silently dropping from the collections any values that are not supported by the other type.
    func compactMap<C>(_ transform: @escaping (Value.Element) -> C.Element?, reverse: @escaping (C.Element) -> Value.Element?) -> Binding<C>
        where Value: Collection & ExpressibleBySequence, C: Collection & ExpressibleBySequence {
        Binding<C>(
            get: { C(self.wrappedValue.compactMap(transform)) },
            set: { self.wrappedValue = Value($0.compactMap(reverse)) }
        )
    }

    /// For a binding that represents an element in a collection, get a binding that represents the index of this element in that collection.
    func index<C: Collection>(of collection: C) -> Binding<C.Index?> where Value == C.Element?, C.Element: Equatable {
        Binding<C.Index?>(
            get: { self.wrappedValue.flatMap(collection.firstIndex(of:)) },
            set: { self.wrappedValue = $0.flatMap { $0 >= collection.startIndex && $0 <= collection.endIndex ? collection[$0] : nil } }
        )
    }

    /// For a binding of an optional value, get a non-optional binding that replaces nil with the given value.
    func replaceNil<V>(with nilValue: @escaping @autoclosure () -> V) -> Binding<V> where Value == V? {
        Binding<V>(get: { self.wrappedValue ?? nilValue() }, set: { self.wrappedValue = $0 })
    }

    /// For a binding of a non-optional value, get an optional binding that ignores when nil values are set.
    func optional() -> Binding<Value?> {
        Binding<Value?>(get: { self.wrappedValue }, set: { $0.flatMap { self.wrappedValue = $0 } })
    }
}

// MARK: - Default Implementations

// FIXME: https://gist.github.com/austinzheng/7cd427dd1a87efb1d94481015e5b3828#user-content-conditional-conformances-via-protocol-extensions
extension UIImagePickerController.SourceType: Identifiable {
    public var id: Self {
        self
    }
}
