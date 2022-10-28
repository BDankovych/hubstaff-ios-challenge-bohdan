// swiftformat:disable fileHeader
// Copyright (c) 2019–20 Adam Sharp and thoughtbot, inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Combine

/// Declares a type that can transmit a sequence of values over time, and
/// always has a current value.
public protocol CurrentValuePublisher: Publisher {
    /// The current value of this publisher.
    var value: Output { get }
}

// MARK: Conforming Types

extension CurrentValueSubject: CurrentValuePublisher {}

extension Just: CurrentValuePublisher {}

extension Published.Publisher: CurrentValuePublisher {}

extension Publishers.Map: CurrentValuePublisher where Upstream: CurrentValuePublisher, Failure == Never {}

extension Publishers.CompactMap: CurrentValuePublisher where Upstream: CurrentValuePublisher, Failure == Never {}

extension Publishers.Filter: CurrentValuePublisher where Upstream: CurrentValuePublisher, Failure == Never {}

extension Publishers.SwitchToLatest: CurrentValuePublisher where P: CurrentValuePublisher, Failure == Never {}

extension Publishers.Multicast: CurrentValuePublisher where SubjectType: CurrentValuePublisher, Failure == Never {}

extension Publishers.Autoconnect: CurrentValuePublisher where Upstream: CurrentValuePublisher, Failure == Never {}

extension Publishers.HandleEvents: CurrentValuePublisher where Upstream: CurrentValuePublisher, Failure == Never {}

extension Publishers.RemoveDuplicates: CurrentValuePublisher where Upstream: CurrentValuePublisher, Failure == Never {}

extension Publishers.Print: CurrentValuePublisher where Upstream: CurrentValuePublisher, Failure == Never {}

extension Result.Publisher: CurrentValuePublisher where Failure == Never {
    public var value: Success {
        // swiftlint:disable:next force_try - checked by where clause.
        try! self.result.get()
    }
}

// MARK: Concrete Type

/// A publisher that wraps an upstream `CurrentValuePublisher`, transforming
/// its current value and all values published by it.
public struct CurrentValue<Output, Failure: Error>: CurrentValuePublisher {
    public init<P>(_ upstream: P, initial: Output)
        where P: Publisher, P.Output == Output, P.Failure == Failure {
        var value = initial
        self.upstreamValue = { value }
        self.upstreamPublisher = upstream.handleEvents(receiveOutput: {
            value = $0
        }).eraseToAnyPublisher()
    }

    public init<P>(_ upstream: P)
        where P: CurrentValuePublisher, P.Output == Output, P.Failure == Failure {
        self.upstreamValue = { upstream.value }
        self.upstreamPublisher = upstream.eraseToAnyPublisher()
    }

    public init<P>(_ upstream: P, _ transform: @escaping (P.Output) -> Output)
        where P: CurrentValuePublisher, P.Failure == Failure {
        self.init(
            unsafeValueProvider: upstream,
            value: { transform(upstream.value) },
            transform: transform
        )
    }

    public init<P>(_ upstream: P, keyPath: KeyPath<P.Output, Output>)
        where P: CurrentValuePublisher, P.Failure == Failure {
        self.init(
            unsafeValueProvider: upstream,
            value: { upstream.value[keyPath: keyPath] },
            transform: { $0[keyPath: keyPath] }
        )
    }

    public init<P>(unsafeValueProvider upstream: P, value: @escaping () -> Output, transform: @escaping (P.Output) -> Output)
        where P: Publisher, P.Failure == Failure {
        self.upstreamValue = value
        self.upstreamPublisher = upstream.map(transform).eraseToAnyPublisher()
    }

    // - CurrentValuePublisher
    public var value: Output {
        self.upstreamValue()
    }

    // - Publisher
    public func receive<S: Subscriber>(subscriber: S) where S.Failure == Failure, S.Input == Output {
        self.upstreamPublisher.receive(subscriber: subscriber)
    }

    // - Private
    private let upstreamValue:     () -> Output
    private let upstreamPublisher: AnyPublisher<Output, Failure>
}

/// Wrap a subject, erasing it into a publisher and privately exposing the subject as a projected value.
///
/// A property with type `AnyPublisher` can be annotated to create an internal subject you can use to set that publisher's value:
///
///     @ErasedSubject(CurrentValueSubject("foo"))
///     public var text: AnyPublisher<String, Never>
///
/// Then update the value using the projected value:
///
///     self.$text.send("bar")
@propertyWrapper
public struct ErasedSubject<S: Subject> {
    public init(_ value: S) {
        self.projectedValue = value
        self.wrappedValue = value.eraseToAnyPublisher()
    }

    // - propertyWrapper
    public let wrappedValue:   AnyPublisher<S.Output, S.Failure>
    public let projectedValue: S
}

/// Publish the value in the property and expose a private subject as the projected value, used for emitting value updates to the publisher.
///
/// The public publisher can use a base (erased) type while the private subject can used a concrete subtype
/// which is automatically mapped to the base type by the public publisher.
///
/// A property with type `CurrentValue` can be annotated to create an internal subject you can use to set that publisher's value:
///
///     @ErasedCurrentSubject("foo")
///     public var text: CurrentValue<StringProtocol, Never>
///
/// Then update the value using the projected value:
///
///     self.$text.send("bar")
@propertyWrapper
// FIXME: https://forums.swift.org/t/pitch-generalized-supertype-constraints/7121/14
public struct ErasedCurrentSubject<Output/* : ErasedOutput*/, ErasedOutput> {
    public init(_ value: Output) {
        self.init(projectedValue: CurrentValueSubject<Output, Never>(value))
    }

    public init(projectedValue: CurrentValueSubject<Output, Never>) {
        self.projectedValue = projectedValue
        // FIXME: swiftlint:disable:next force_cast - Make Output: ErasedOutput
        self.wrappedValue = CurrentValue(projectedValue.map { $0 as! ErasedOutput })
    }

    // - propertyWrapper
    public let wrappedValue:   CurrentValue<ErasedOutput, Never>
    public let projectedValue: CurrentValueSubject<Output, Never>
}

extension ErasedCurrentSubject: ExpressibleByArrayLiteral where Output: RangeReplaceableCollection {
    public init(arrayLiteral elements: Output.Element...) {
        self.init(Output(elements))
    }
}

extension ErasedCurrentSubject: ExpressibleByBooleanLiteral where Output == Bool {
    public init(booleanLiteral value: Output) {
        self.init(value)
    }
}

extension ErasedCurrentSubject: ExpressibleByFloatLiteral where Output == Float {
    public init(floatLiteral value: Output) {
        self.init(value)
    }
}

extension ErasedCurrentSubject: ExpressibleByIntegerLiteral where Output == Int {
    public init(integerLiteral value: Output) {
        self.init(value)
    }
}

// MARK: Public

public extension CurrentValuePublisher where Failure == Never {
    @inlinable
    var value: Output {
        _getValue()
    }
}

// MARK: Internal

extension Publisher {
    /// Subscribes and synchronously returns the first value output from this
    /// publisher.
    ///
    /// - Warning: Must only be called on a `CurrentValuePublisher`, otherwise
    ///   this will unconditionally trap.
    @usableFromInline
    func _getValue() -> Output {
        var value: Output!
        _ = first().sink(
            receiveCompletion: { _ in },
            receiveValue: { value = $0 }
        )
        return value
    }
}
