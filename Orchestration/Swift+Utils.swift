//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

/// The purpose of this file is to extend features introduced by the Swift Standard Library.
import Combine
import Foundation

// MARK: - Utilities

/// Modify an object in-place.
///
/// Useful for avoiding creating temporary lvars.
public func using<V>(_ value: V, do: (inout V) -> Void) -> V {
    var value = value
    `do`(&value)
    return value
}

/// Transform an object in-place.
///
/// Useful for avoiding creating temporary lvars or logically splitting up one-liners into procedural steps.
public func map<F, T>(_ from: F, do: (F) -> T) -> T {
    `do`(from)
}

/// Translate a value from one type into another based on a set of translation rules.
public func map<F: Equatable, T>(from: F, where: [(if: F, then: T)]) -> T? {
    for `case` in `where`
        where from == `case`.if {
        return `case`.then
    }

    return nil
}

/// Clamp a value to the given range.
///
/// If the value compares above or below the range's bounds, returns the bound instead.
public func clamp<T: Comparable>(_ value: T, to range: ClosedRange<T>) -> T {
    min(range.upperBound, max(range.lowerBound, value))
}

/// Obtain a hashable representation for any set of values.
///
/// - Attention: The hashable represents exclusively the hashable values or children, ignoring any non-hashable state.
public func hashable(_ values: Any?...) -> AnyHashable {
    values.map {
        $0.flatMap {
            $0 as? AnyHashable // already hashable.
                ?? AnyHashable(Mirror(reflecting: $0).children.map { hashable($0.value) }) // hashable children.
        } ?? AnyHashable(Double.leastNonzeroMagnitude) // nil hashes as special float.
    }
}

/// A debug identification of the object, useful for telling values apart. Shows its type and unique value identifier (pointer) - or nil.
public func describe(_ value: AnyObject?) -> String {
    if let value = value {
        return "\(type(of: value)): \(ObjectIdentifier(value))"
    }
    else {
        return "nil"
    }
}

/// Check to see if the debugger (eg. Xcode) is currently attached.
public func isDebugging() -> Bool {
    var info          = kinfo_proc()
    var infoLength    = MemoryLayout.stride(ofValue: info)
    var name: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    sysctl(&name, UInt32(name.count), &info, &infoLength, nil, 0)
    return (info.kp_proc.p_flag & P_TRACED) != 0
}

// MARK: - Conversion

public protocol AnyIdentifiable {
    var id: AnyHashable { get }
}

public extension AnyHashable {
    init(_ values: AnyHashable?...) {
        self.init(values)
    }
}

public extension ExpressibleByArrayLiteral {
    init(only element: Self.ArrayLiteralElement?) {
        if let element = element {
            self = [element]
        }
        else {
            self = []
        }
    }
}

public extension Sequence {
    /// Arrange the sequence by order based on a comparaible value produced from each element.
    func sorted<T: Comparable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        self.sorted {
            $0[keyPath: keyPath] < $1[keyPath: keyPath]
        }
    }

    /// Arrange the sequence into a dictionary keyed by a value produced from each element.
    func dictionary<K>(by: (Element) -> K) -> [K: Element] {
        Dictionary(self.map { (key: by($0), value: $0) }, uniquingKeysWith: { $1 })
    }

    /// Arrange the sequence into a dictionary keyed by a value produced from each element. Omits all elements that cannot produce a key.
    func compactDictionary<K>(by: (Element) -> K?) -> [K: Element] {
        Dictionary(self.compactMap { value in by(value).flatMap { key in (key: key, value: value) } }, uniquingKeysWith: { $1 })
    }
}

public extension Array {
    /// Makes an Array's elements Non-Optional by silently dropping all nil values.
    ///
    /// - Returns: An array that contains only the elements in this array which are not nil.
    func removeNil<T>() -> [T] where Element == T? {
        self.compactMap { $0 }
    }

    /// Return an array that cannot be empty, or nil if it is.
    var nonEmpty: Self? {
        self.isEmpty ? nil : self
    }
}

public extension Numeric {
    /// Return a number that cannot be zero, or nil if it is.
    var nonEmpty: Self? {
        self == Self(exactly: Int.zero) ? nil : self
    }
}

public extension String {
    /// Return a string that cannot be empty, or nil if it is.
    var nonEmpty: Self? {
        self.isEmpty ? nil : self
    }
}

// MARK: - Formatting

public extension String {
    /// Represent a ratio as a percentage value.
    static func format<F: BinaryFloatingPoint>(percent ratio: F) -> String {
        self.percentFormatter.string(for: ratio) ?? ""
    }

    // - Private

    private static let percentFormatter = using(NumberFormatter()) {
        $0.numberStyle = .percent
    }
}

// MARK: - Associated Keys

public extension NSObjectProtocol {
    private static func key<H: AnyObject>(forAssociation keyPath: PartialKeyPath<H>) -> UnsafeRawPointer {
        unsafeBitCast(H.self, to: UnsafeRawPointer.self) + keyPath.hashValue
    }

    /// Obtain the value associated with this object at the given key path through the other association methods.
    ///
    /// - Parameter keyPath: A key used to resolve the associated value in this object.
    /// - Returns: `nil` if no association has been made yet for this object at the given key path.
    func get<H: AnyObject, V>(forAssociation keyPath: KeyPath<H, V?>) -> V? {
        objc_getAssociatedObject(self, Self.key(forAssociation: keyPath)) as? V
    }

    /// Obtain the value associated with this object at the given key path through this method or the association setters.
    ///
    /// - Note: This operation is performed non-atomically, meaning use in a multi-threaded environment is undefined.
    /// - Parameter keyPath: A key used to resolve the associated value in this object.
    /// - Parameter defaultValue: If no association exists, this value is resolved and associated.
    /// - Returns: `defaultValue` if no association had been made yet for this object at the given key path.
    func get<H: AnyObject, V>(forAssociation keyPath: KeyPath<H, V>, defaultSet defaultValue: @autoclosure () -> V) -> V {
        if let value = objc_getAssociatedObject(self, Self.key(forAssociation: keyPath)) as? V {
            return value
        }

        let value = defaultValue()
        self.set(forAssociation: keyPath, value: value)
        return value
    }

    /// Associate a value with this object at the given key path. Any previous association for this object at the key path is overwritten.
    ///
    /// - Note: This operation is performed non-atomically, meaning use in a multi-threaded environment is undefined.
    /// - Parameter keyPath: A key used to resolve the associated value in this object.
    /// - Parameter value: The value to associate with the object.
    func set<H: AnyObject, V>(forAssociation keyPath: KeyPath<H, V>, value: V) {
        objc_setAssociatedObject(self, Self.key(forAssociation: keyPath), value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// Associate a value with this object at the given key path. Any previous association for this object at the key path is overwritten.
    ///
    /// - Note: This operation is performed non-atomically, meaning use in a multi-threaded environment is undefined.
    /// - Parameter keyPath: A key used to resolve the associated value in this object.
    /// - Parameter value: The value to associate with the object.
    func set<H: AnyObject, V>(forAssociation keyPath: KeyPath<H, V?>, value: V?) {
        objc_setAssociatedObject(self, Self.key(forAssociation: keyPath), value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

/// Expose a value using an (erased) public base type while privately exposing a projected value using a concrete subtype.
@propertyWrapper
public struct ErasedValue<Value, ErasedValue> {
    // swiftlint:disable:next force_cast
    public init(_ projectedValue: Value, eraser: @escaping (Value) -> ErasedValue = { $0 as! ErasedValue }) {
        self.projectedValue = projectedValue
        self.eraser = eraser
    }

    // - propertyWrapper
    public var wrappedValue: ErasedValue {
        self.eraser(self.projectedValue)
    }

    public var  projectedValue: Value

    // - Private
    private var eraser:         (Value) -> ErasedValue
}

extension ErasedValue: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool where Value: Hashable {
        lhs.projectedValue == rhs.projectedValue
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.projectedValue as AnyObject === rhs.projectedValue as AnyObject
    }

    public func hash(into hasher: inout Hasher) where Value: Hashable {
        self.projectedValue.hash(into: &hasher)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self.projectedValue as AnyObject))
    }
}

@propertyWrapper
public struct Instance<O> {
    public var wrappedValue: O?

    public init(_ wrappedValue: O?) {
        self.wrappedValue = wrappedValue
    }
}

extension Instance: Hashable {
    fileprivate var object: AnyObject? {
        self.wrappedValue as AnyObject?
    }

    // - Hashable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.object === rhs.object
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
}

extension Instance: Identifiable {
    public var id: ObjectIdentifier {
        ObjectIdentifier(self.object ?? NSNull.self)
    }
}

// MARK: - Foundation

public extension URLRequest {
    func cachedData(session: URLSession = .shared) -> Data? {
        session.configuration.urlCache?.cachedResponse(for: self)?.data
    }

    func remoteData(session: URLSession = .shared) async throws -> Data {
        let (data, response) = try await session.data(for: self)
        // iOS does not cache redirect responses, making these URLs unavailable when offline.
        session.configuration.urlCache?
            .storeCachedResponse(CachedURLResponse(response: response, data: data), for: self)
        return data
    }
}

public extension Dictionary {
    subscript(key: Key, defaultSet defaultValue: @autoclosure () -> Value) -> Value {
        mutating get {
            if let value = self[key] {
                return value
            }

            let value = defaultValue()
            self[key] = value
            return value
        }
    }

    /// Makes an Dictionary's values Non-Optional by silently dropping all nil values.
    ///
    /// - Returns: A dictionary that contains only the elements in this dictionary whose values are not nil.
    func removeNil<NNValue>() -> [Key: NNValue] where Value == NNValue? {
        self.compactMapValues { $0 }
    }
}

// MARK: - Combine

/// Convenience utility for `Publisher.combineLatest`, putting all publishers at the same level.
public func combineLatest<A, B>(_ a: A, _ b: B)
    -> Publishers.CombineLatest<A, B>
    where A: Publisher, B: Publisher, A.Failure == B.Failure {
    a.combineLatest(b)
}

/// Convenience utility for `Publisher.combineLatest`, putting all publishers at the same level.
public func combineLatest<A, B, C>(_ a: A, _ b: B, _ c: C)
    -> Publishers.CombineLatest3<A, B, C>
    where A: Publisher, B: Publisher, C: Publisher, A.Failure == B.Failure, B.Failure == C.Failure {
    a.combineLatest(b, c)
}

/// Convenience utility for `Publisher.combineLatest`, putting all publishers at the same level.
public func combineLatest<A, B, C, D>(_ a: A, _ b: B, _ c: C, _ d: D)
    -> Publishers.CombineLatest4<A, B, C, D>
    where A: Publisher, B: Publisher, C: Publisher, D: Publisher,
    A.Failure == B.Failure, B.Failure == C.Failure, C.Failure == D.Failure {
    a.combineLatest(b, c, d)
}

/// Convenience utility for `Publisher.combineLatest`, putting all publishers at the same level.
public func combineLatest<A, B, C, D, E>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E)
    -> Publishers.Map<
        Publishers.CombineLatest4<A, B, C, Publishers.CombineLatest<D, E>>,
        (A.Output, B.Output, C.Output, D.Output, E.Output)
    >
    where A: Publisher, B: Publisher, C: Publisher, D: Publisher, E: Publisher,
    A.Failure == B.Failure, B.Failure == C.Failure, C.Failure == D.Failure, D.Failure == E.Failure {
    a.combineLatest(b, c, d.combineLatest(e)) {
        ($0, $1, $2, $3.0, $3.1)
    }
}

/// Convenience utility for `Publisher.combineLatest`, putting all publishers at the same level.
public func combineLatest<A, B, C, D, E, F>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F)
    -> Publishers.Map<
        Publishers.CombineLatest4<A, B, Publishers.CombineLatest<C, D>, Publishers.CombineLatest<E, F>>,
        (A.Output, B.Output, C.Output, D.Output, E.Output, F.Output)
    >
    where A: Publisher, B: Publisher, C: Publisher, D: Publisher, E: Publisher, F: Publisher,
    A.Failure == B.Failure, B.Failure == C.Failure, C.Failure == D.Failure, D.Failure == E.Failure, E.Failure == F.Failure {
    a.combineLatest(b, c.combineLatest(d), e.combineLatest(f)) {
        ($0, $1, $2.0, $2.1, $3.0, $3.1)
    }
}

public extension Publisher {
    /// Makes a Publisher's Output Non-Optional by silently dropping all nil values.
    ///
    /// - Returns: A publisher that emits the upstream result only if it is not nil.
    func removeNil<T>() -> Publishers.CompactMap<Self, T> where Output == T? {
        self.compactMap { $0 }
    }

    /// Only publishes upstream elements when the predicate is `false`, removing elements otherwise.
    func remove(while predicate: @escaping () -> Bool) -> Publishers.Filter<Self> {
        self.filter { _ in !predicate() }
    }

    /// Only publishes upstream elements when the predicate is `false`, removing elements otherwise.
    func remove(while predicate: @escaping (Self.Output) -> Bool) -> Publishers.Filter<Self> {
        self.filter { !predicate($0) }
    }

    /// Transform this publisher into a publisher created from the latest upstream element.
    ///
    /// - Returns: A publisher based on the latest upstream element.
    func latestMap<T: Publisher>(_ transform: @escaping (Self.Output) -> T) -> Publishers.SwitchToLatest<T, Publishers.Map<Self, T>>
        where Self.Failure == T.Failure {
        self.map(transform).switchToLatest()
    }

    /// Makes a Publisher's Output Optional.
    ///
    /// - Returns: A publisher that emits the upstream result using an Optional variant of the Output type.
    func optional() -> Publishers.Map<Self, Output?> {
        self.map(Optional.init)
    }

    /// A sink version that keeps track of the previous value, allowing you to act on changes.
    ///
    /// You will receive no update for the first upstream value, only as soon as a previous value is known.
    func sink(
        receiveCompletion: @escaping (Subscribers.Completion<Self.Failure>) -> Void,
        receiveUpdate: @escaping (Self.Output, Self.Output) -> Void
    )
        -> AnyCancellable {
        var old: Output?
        return self.sink(receiveCompletion: receiveCompletion) { new in
            defer { old = new }

            guard let old = old
            else { return }

            receiveUpdate(old, new)
        }
    }

    func removeDuplicates<A: Equatable, B: Equatable>() -> Publishers.RemoveDuplicates<Self> where Output == (A, B) {
        self.removeDuplicates { $0.0 == $1.0 && $0.1 == $1.1 }
    }

    func removeDuplicates<A: Equatable, B: Equatable, C: Equatable>() -> Publishers.RemoveDuplicates<Self> where Output == (A, B, C) {
        self.removeDuplicates { $0.0 == $1.0 && $0.1 == $1.1 && $0.2 == $1.2 }
    }
}

public extension Publisher where Self.Failure == Never {
    /// A sink version that keeps track of the previous value, allowing you to act on changes.
    ///
    /// You will receive no update for the first upstream value, only as soon as a previous value is known.
    func sink(receiveUpdate: @escaping (Self.Output, Self.Output) -> Void) -> AnyCancellable {
        self.sink(receiveCompletion: { _ in }, receiveUpdate: receiveUpdate)
    }
}

public extension Collection where Element: Publisher {
    /// Translate a Collection of Publishers into a Publisher of Collections.
    ///
    /// - Returns: A publisher that emits a collection every time each of the original collection's publishers have emitted a value.
    func flatten() -> AnyPublisher<[Element.Output], Element.Failure> {
        self.reduce(Just([Element.Output]()).setFailureType(to: Element.Failure.self).eraseToAnyPublisher()) {
            $0.combineLatest($1) { $0 + [$1] }.eraseToAnyPublisher()
        }
    }
}

public extension Optional where Wrapped: Combine.Publisher {
    func or<P>(_ nilPublisher: @autoclosure () -> P) -> AnyPublisher<Wrapped.Output, Wrapped.Failure>
        where P: Combine.Publisher, P.Output == Wrapped.Output, P.Failure == Wrapped.Failure {
        self?.eraseToAnyPublisher() ?? nilPublisher().eraseToAnyPublisher()
    }

    func or(just value: @autoclosure () -> Wrapped.Output) -> AnyPublisher<Wrapped.Output, Wrapped.Failure> {
        self.or(Just(value()).setFailureType(to: Wrapped.Failure.self))
    }

    func orNil() -> AnyPublisher<Wrapped.Output?, Wrapped.Failure> {
        (self?.optional()).or(Just(nil).setFailureType(to: Wrapped.Failure.self))
    }
}

public extension Optional {
    /// If this optional value exists and has a sub-value, yield both in a tuple.
    func with<V>(_ value: (Wrapped) -> V?) -> (Wrapped, V)? {
        guard let wrapped = self, let value = value(wrapped)
        else { return nil }

        return (wrapped, value)
    }
}

// MARK: - Default Implementations

// FIXME: https://gist.github.com/austinzheng/7cd427dd1a87efb1d94481015e5b3828#user-content-conditional-conformances-via-protocol-extensions
public extension RawRepresentable where Self: Identifiable, RawValue: Identifiable {
    var id: RawValue.ID {
        self.rawValue.id
    }
}

extension String: Identifiable {
    public var id: String {
        self
    }
}

public protocol ExpressibleBySequence {
    associatedtype Element

    init<S>(_ elements: S) where S: Sequence, Self.Element == S.Element
}

extension Set: ExpressibleBySequence {}

extension Array: ExpressibleBySequence {}

// MARK: - Property wrappers

@propertyWrapper
public struct IgnoreHashable<Value>: Equatable, Hashable {
    public var wrappedValue: Value

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }

    public static func == (lhs: IgnoreHashable<Value>, rhs: IgnoreHashable<Value>) -> Bool {
        true
    }

    public func hash(into hasher: inout Hasher) {}
}

/// Variant of @Published for use with computed properties.
///
/// Exposes a publisher on computed properties that can be used to monitor the computed property's value as the enclosing object changes.
@propertyWrapper
public struct PublishedComputed<Value, T: ObservableObject> {
    public static subscript(
        _enclosingInstance observed: T,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<T, Self>
    )
        -> Value {
        get {
            observed[keyPath: storageKeyPath].get(observed)
        }
        set {
            // swiftlint:disable:next force_cast
            (observed.objectWillChange as! ObservableObjectPublisher).send()
            observed[keyPath: storageKeyPath].set(observed, newValue)
        }
    }

    public private(set) static subscript(
        _enclosingInstance observed: T,
        projected wrappedKeyPath: ReferenceWritableKeyPath<T, AnyPublisher<Value, Never>>,
        storage storageKeyPath: ReferenceWritableKeyPath<T, Self>
    ) -> AnyPublisher<Value, Never> {
        get {
            // Publish both the initial value (Just) as well as future changes to the object (objectWillChange).
            // Debounce the changes since they are published before the updated value is available from the object (will-change).
            Just(())
                .merge(with: observed.objectWillChange.map { _ in () }.debounce(for: .zero, scheduler: RunLoop.current))
                .map { _ in observed[keyPath: storageKeyPath].get(observed) }
                .eraseToAnyPublisher()
        }
        set { fatalError() }
    }

    public init(get: @escaping (T) -> Value, set: @escaping (T, Value) -> Void) {
        self.get = get
        self.set = set
    }

    @available(*, unavailable, message: "@PublishedComputed can only be used in object types.")
    public var wrappedValue: Value {
        get { fatalError() }
        set { fatalError() /* swiftlint:disable:this unused_setter_value - https://github.com/realm/SwiftLint/issues/3863 */ }
    }

    @available(*, unavailable, message: "@PublishedComputed can only be used in object types.")
    public var  projectedValue: AnyPublisher<Value, Never> {
        get { fatalError() }
        set { fatalError() /* swiftlint:disable:this unused_setter_value - https://github.com/realm/SwiftLint/issues/3863 */ }
    }

    // - Private
    private var get:            (T) -> Value, set: (T, Value) -> Void
}
