//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

// MARK: - Type Declarations

/// A choice provides a container for the selection of a value.
///
/// Its purpose is to anonymously communicate between two entities about a chosen value of a certain type.
/// The PRODUCER creates a choice and offers it to the CONSUMER, which can populate it.
/// The producer typically monitors the choice to act upon it.
///
/// Note: A Choice is observable and emits a notification whenever any of its public properties are modified.
public protocol Choice: ObservableObject {
    associatedtype Value

    /// The values that have currently been chosen.
    var selection: [Value] { get set }
    /// A convenience interface for single-value choices.
    ///
    /// Provides any single value from the selection, or `nil` if the selection is empty.
    /// Changing this value replaces the entire selection with the single given element (or none if `nil`).
    var selected:  Value? { get set }
}

/// Associated types allow for obtaining ancillary information on the values they manage.
public protocol Associated: ObservableObject {
    associatedtype Value
    associatedtype Association = Void

    /// Associated values are how the provider can supply ancillary information on any value.
    func association(for value: Value) -> Association?
}

/// A source provides a list of values and the ability to select from them.
///
/// Its purpose is to hide:
/// 1. The origin of these values,
/// 2. The details of how selection is applied
///
/// The goal is to separate the value PRODUCER from the CONSUMER, resulting in a clean interface between them.
///
/// Note: A Source is observable and emits a notification whenever any of its public properties are modified.
public protocol Source: Choice {
    /// The values currently made available by the source.
    var values: [Value] { get }
}

// MARK: - Type Extensions

public extension Choice {
    /// Hide the implementation details of this choice from a consumer.
    func eraseToAnyChoice()
        -> AnyChoice<Value> {
        AnyChoice(self)
    }

    /// Hide the implementation details of this associated choice from a consumer.
    func eraseToAnyChoice()
        -> AnyChoice<Value>.Associated<Self.Association> where Self: Associated {
        AnyChoice.Associated(self, association: self.association(for:))
    }

    /// Add an association to a choice by supplying the missing capabilities.
    func with<Association>(association: @escaping (Value) -> Association?)
        -> AnyChoice<Value>.Associated<Association> {
        AnyChoice.Associated<Association>(self, association: association)
    }

    /// Create a new choice based on this choice with modified values.
    func map<V>(value transform: @escaping (Value) -> V, reverse: @escaping (V) -> Value?)
        -> AnyChoice<V> {
        AnyChoice<V>(
            getSelection: { self.selection.map(transform) },
            setSelection: { self.selection = $0.compactMap(reverse) }
        ).observes(upstream: self)
    }

    /// Create a new choice based on this associated choice with modified values.
    func map<V>(value transform: @escaping (Value) -> V, reverse: @escaping (V) -> Value?)
        -> AnyChoice<V>.Associated<Self.Association> where Self: Associated {
        AnyChoice(self).map(value: transform, reverse: reverse).with {
            reverse($0).flatMap(self.association(for:))
        }
    }
}

public extension Source {
    /// Hide the implementation details of this source from a consumer.
    func eraseToAnySource()
        -> AnySource<Value> {
        AnySource(self)
    }

    /// Hide the implementation details of this associated source from a consumer.
    func eraseToAnySource()
        -> AnySource<Value>.Associated<Self.Association> where Self: Associated {
        AnySource.Associated(self, association: self.association(for:))
    }

    /// Add an association to a source by supplying the missing capabilities.
    func with<Association>(association: @escaping (Value) -> Association?)
        -> AnySource<Value>.Associated<Association> {
        AnySource.Associated<Association>(self, association: association)
    }
}

public func + <S1: Source, S2: Source>(lhs: S1, rhs: S2)
    -> AnySource<S1.Value> where S1.Value == S2.Value {
    AnySource(values: { lhs.values + rhs.values }, getSelection: { lhs.selection + rhs.selection }, setSelection: { selection in
        let lhsIdentities = lhs.values.map(S1.identity(for:))
        let rhsIdentities = rhs.values.map(S2.identity(for:))
        lhs.selection = selection.filter { lhsIdentities.contains(S1.identity(for: $0)) }
        rhs.selection = selection.filter { rhsIdentities.contains(S2.identity(for: $0)) }
    }).observes(upstream: lhs).observes(upstream: rhs)
}

public func + <Value, Association>(lhs: AnySource<Value>.Associated<Association>, rhs: AnySource<Value>.Associated<Association>)
    -> AnySource<Value>.Associated<Association> {
    AnySource<Value>.Associated(lhs as AnySource<Value> + rhs as AnySource<Value>) {
        lhs.association(for: $0) ?? rhs.association(for: $0)
    }
}

// MARK: - Concrete Implementations

/// A concrete choice which hides its underlying implementation.
public class AnyChoice<Value>: Choice {
    /// Create an inline custom choice implementation.
    public init(getSelection: @escaping () -> [Value], setSelection: @escaping ([Value]) -> Void) {
        var objectWillChange: Combine.ObservableObjectPublisher?
        self.upstream = (getSelection: getSelection, setSelection: { objectWillChange?.send(); setSelection($0) })
        objectWillChange = self.objectWillChange
    }

    /// Print debugging output whenever this object changes.
    public func print(_ prefix: String) -> Self {
        self.printPrefix = prefix
        return self
    }

    /// Update this source when the given upstream changes.
    @discardableResult
    func observes<O: ObservableObject>(upstream: O) -> Self {
        upstream.objectWillChange.sink { [unowned self] _ in self.objectWillChange.send() }.store(in: &self.subscriptions)
        return self
    }

    // - Choice
    public var selection: [Value] {
        get { self.upstream.getSelection() }
        set {
            self.printPrefix.flatMap { Swift.print("\($0): setSelection: \(newValue)") }
            self.upstream.setSelection(newValue)
        }
    }

    // - Private
    fileprivate init<C: Choice>(_ upstream: C) where C.Value == Value {
        self.upstream = (getSelection: { upstream.selection }, setSelection: { upstream.selection = $0 })
        self.observes(upstream: upstream)
    }

    private let upstream: (
        getSelection: () -> [Value],
        setSelection: ([Value]) -> Void
    )
    private var subscriptions = [AnyCancellable]()
    var printPrefix: String?

    public class Associated<Association>: AnyChoice<Value>, Orchestration.Associated {
        fileprivate init<C: Choice>(_ upstream: C, association: @escaping (Value) -> Association?) where C.Value == Value {
            self.association = association
            super.init(upstream)
        }

        // - Association
        public func association(for value: Value) -> Association? {
            self.association(value)
        }

        // - Private
        private let association: (Value) -> Association?
    }
}

/// A concrete source which hides its underlying implementation.
public class AnySource<Value>: AnyChoice<Value>, Source {
    /// Create an inline custom source implementation.
    public init(values: @escaping () -> [Value], getSelection: @escaping () -> [Value], setSelection: @escaping ([Value]) -> Void) {
        self.upstream = values
        super.init(getSelection: getSelection, setSelection: setSelection)
    }

    // - Source
    public var values: [Value] {
        using(self.upstream()) { values in
            self.printPrefix.flatMap { Swift.print("\($0): values: \(values)") }
        }
    }

    // - Private
    init<S: Source>(_ upstream: S) where S.Value == Value {
        self.upstream = { upstream.values }
        super.init(upstream)
    }

    private let upstream: () -> [Value]

    public class Associated<Association>: AnySource<Value>, Orchestration.Associated {
        fileprivate init<S: Source>(_ upstream: S, association: @escaping (Value) -> Association?) where S.Value == Value {
            self.association = association
            super.init(upstream)
        }

        // - Association
        public func association(for value: Value) -> Association? {
            self.association(value)
        }

        // - Private
        private let association: (Value) -> Association?
    }
}

/// A choice which exposes the latest values from an upstream subject.
public class SubjectChoice<Value>: Choice {
    public init(upstream: CurrentValueSubject<Value, Never>) {
        self.upstream = (
            getSelection: { Array(only: upstream.value) },
            setSelection: { $0.first.flatMap { upstream.send($0) } }
        )
    }

    public init(upstream: CurrentValueSubject<Value?, Never>) {
        self.upstream = (
            getSelection: { Array(only: upstream.value) },
            setSelection: { upstream.send($0.first) }
        )
    }

    public init(upstream: CurrentValueSubject<[Value], Never>) {
        self.upstream = (
            getSelection: { upstream.value },
            setSelection: { upstream.send($0) }
        )
    }

    public init<H>(published: inout Published<H>.Publisher, _ keyPath: WritableKeyPath<H, Value>) {
        let writer = using(PassthroughSubject<H, Never>()) { $0.assign(to: &published) }, published = published
        self.upstream = (
            getSelection: { Array(only: published.value[keyPath: keyPath]) },
            setSelection: { $0.first.flatMap { var host = published.value; host[keyPath: keyPath] = $0; writer.send(host) } }
        )
    }

    public init<H>(published: inout Published<H>.Publisher, _ keyPath: WritableKeyPath<H, Value?>) {
        let writer = using(PassthroughSubject<H, Never>()) { $0.assign(to: &published) }, published = published
        self.upstream = (
            getSelection: { Array(only: published.value[keyPath: keyPath]) },
            setSelection: { var host = published.value; host[keyPath: keyPath] = $0.first; writer.send(host) }
        )
    }

    public init<H>(published: inout Published<H>.Publisher, _ keyPath: ReferenceWritableKeyPath<H, [Value]>) {
        let writer = using(PassthroughSubject<H, Never>()) { $0.assign(to: &published) }, published = published
        self.upstream = (
            getSelection: { published.value[keyPath: keyPath] },
            setSelection: { let host = published.value; host[keyPath: keyPath] = $0; writer.send(host) }
        )
    }

    // - Choice
    public typealias _Self = SubjectChoice
    @PublishedComputed<[Value], _Self>(get: { $0.upstream.getSelection() }, set: { $0.upstream.setSelection($1) })
    public var selection: [Value]
    @PublishedComputed<Value?, _Self>(get: { $0.upstream.getSelection().first }, set: { $0.upstream.setSelection(Array(only: $1)) })
    public var selected: Value?

    // - Private
    private var subscriptions = [AnyCancellable]()
    private let upstream: (
        getSelection: () -> [Value],
        setSelection: ([Value]) -> Void
    )
}

/// A simple choice owns and manages an in-memory store of the chosen value.
public class SimpleChoice<Value>: Choice {
    public convenience init(selected: Value?) {
        self.init(selection: Array(only: selected))
    }

    public init(selection: [Value] = []) {
        self.selection = selection
    }

    // - Choice
    public typealias _Self = SimpleChoice
    @Published
    public var selection: [Value]
    @PublishedComputed<Value?, _Self>(get: { $0.selection.first }, set: { $0.selection = Array(only: $1) })
    public var selected: Value?

    // - Private
    private var subscriptions = [AnyCancellable]()
}

// MARK: - Boilerplate

public extension Choice {
    var selected: Value? {
        get { self.selection.first }
        set { self.selection = Array(only: newValue) }
    }

    func isSelected(value: Value) -> Bool {
        self.selection.map(Self.identity(for:)).contains(Self.identity(for: value))
    }

    static func identity(for value: Value) -> AnyHashable where Value: Identifiable {
        value.id
    }

    @_disfavoredOverload
    static func identity(for value: Value) -> AnyHashable {
        (value as? Entity)?.id ?? (value as? AnyIdentifiable)?.id ?? hashable(value)
    }
}
