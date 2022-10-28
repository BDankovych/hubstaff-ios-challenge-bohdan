//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Combine
import Foundation
import System

/// A cache for obtaining a LookupValue from a specific key.
///
/// This is used to translate from one value (the key) into another value (LookupValue.Output), when the other value may change over time.
///
/// Querying the map for a certain key that doesn't exist yet results in a new LookupValue created from this map's lookup factory.
public class LookupMap<Key: Identifiable, Output>: Updatable {
    public typealias Failure = Never

    public init<P: CurrentValuePublisher>(lookup: @escaping (Key) -> P)
        where P.Output == Output, P.Failure == Failure, Key: Identifiable {
        self.lookup = { key in LookupValue(lookup: { lookup(key) }) }
    }

    public init(constant: @escaping (Key) -> Output, updater: @escaping (Output, @escaping () -> Void) -> Void)
        where Key: Identifiable, Output: AnyObject {
        self.lookup = { key in LookupValue(constant: constant(key), updater: updater) }
    }

    // - Public
    public subscript(key: Key) -> LookupValue<Output> {
        self.values[key.id, defaultSet: self.lookup(key)]
    }

    /// Updating a LookupMap causes all existing LookupValues to get updated.
    public func updated() {
        for id in self.values.keys {
            self.values[id]?.updated()
        }
    }

    /// Updating a LookupMap causes all existing LookupValues to get invalidated.
    public func invalidated() {
        for id in self.values.keys {
            self.values[id]?.invalidated()
        }
    }

    // - Private
    private let lookup: (Key) -> LookupValue<Output>
    private var values = [Key.ID: LookupValue<Output>]()
}

/// A publisher for a value which may need to be updated later.
///
/// Use this to resolve a "current value" from a lookup "factory".
///
/// The factory can either be a reference type that should be re-published whenever one of its internal details change,
/// or it can be a closure that calculates and publishes a "current value", which can be re-generated manually by calling self.update().
public class LookupValue<Output>: CurrentValuePublisher, Updatable {
    public typealias Failure = Never

    public convenience init(constant: Output, updater: @escaping (Output, @escaping () -> Void) -> Void) where Output: AnyObject {
        self.init(lookup: { Just(constant) })
        updater(constant) {
            dbg("\(constant): Model triggered a change callback.")
            time("Callback \(Output.self)") { self.updated() }
        }
    }

    public init<O>() where Output == O? {
        self.lookup = { CurrentValue(Just(nil)) }
        self.upstream = .init(self.lookup())
    }

    public init<C: CurrentValuePublisher>(lookup: @escaping () -> C) where C.Output == Output, C.Failure == Failure {
        self.lookup = { CurrentValue(lookup()) }
        self.upstream = .init(self.lookup())
    }

    /// Sink a publisher into this LookupValue.
    ///
    /// Useful for if you want to update the LookupValue when the publisher changes.
    /// The LookupValue stores the subscription to the publisher and invokes the sink for every publisher update, allowing you to update
    /// the LookupValue however you see fit. Call `updated()` if the LookupValue has been modified and needs to be re-advertised.
    public func sink<P: Publisher>(_ publisher: P, into sink: @escaping (P.Output, LookupValue<Output>) -> Void) -> Self
        where P.Failure == Never {
        publisher.sink { [unowned self] in
            sink($0, self)
        }.store(in: &self.subscriptions)

        return self
    }

    /// Resolve a new lookup publisher or re-publish an updated constant.
    public func updated() {
        self.upstream.send(self.lookup())
    }

    /// Replace the current lookup value with a new constant, updating all LookupValue subscribers.
    public func updated(constant: Output, updater: @escaping (Output, @escaping () -> Void) -> Void) {
        updater(constant) { [weak self] in
            guard let self = self
            else { return }

            dbg("\(self.value): Model triggered a change callback.")
            time("Callback \(Output.self)") { self.updated() }
        }

        self.lookup = { CurrentValue(Just(constant).setFailureType(to: Failure.self)) }
    }

    /// Resolve a new lookup publisher or re-publish an updated constant.
    public func invalidated() {
        // TODO: Communicate to the subscriber that the Output has been invalidated.
    }

    // - CurrentValuePublisher
    public var value: Output {
        self.upstream.value.value
    }

    // - Publisher
    public func receive<S>(subscriber: S)
        where S: Subscriber, S.Failure == Failure, S.Input == Output {
        self.downstream.receive(subscriber: subscriber)
    }

    // - Private
    private var isOutdated = false
    private var lookup: () -> CurrentValue<Output, Failure> {
        didSet {
            self.updated()
        }
    }

    private let upstream: CurrentValueSubject<CurrentValue<Output, Failure>, Failure>
    private lazy var downstream = self.upstream.switchToLatest()
    private var subscriptions = [AnyCancellable]()
}

extension LookupValue: Subject {
    public func send(_ constant: Output) {
        self.lookup = { CurrentValue(Just(constant).setFailureType(to: Failure.self)) }
    }

    public func send(completion: Subscribers.Completion<Never>) {
        self.upstream.send(completion: completion)
    }

    public func send(subscription: Subscription) {
        self.upstream.send(subscription: subscription)
    }
}

public extension Publisher {
    /// Transforms a publisher of model configurations into a publisher of model objects.
    ///
    /// - Parameters:
    ///   - create: A factory for creating a model object for the given configuration.
    ///   - recreate: Comparator to see if the configuration change from old to new will require the factory to recreate the model object.
    ///   - configure: Apply the given configuration parameters to the previously created model object.
    ///   - updater: Install the given updater into the given model for signalling to the publisher when the model has received an update.
    ///
    /// - Returns: A publisher which emits a model object when the configuration changes or the model has received an internal update.
    func lookup<M: AnyObject>(
        create: @escaping (Self.Output) -> M,
        recreate: @escaping (Self.Output, Self.Output) -> Bool = { _, _ in false },
        configure: @escaping (M, Self.Output) -> Void = { _, _ in },
        updater: @escaping (M, @escaping () -> Void) -> Void = { _, _ in }
    )
        -> CurrentValue<M, Never> where Self.Failure == Never {
        var old: Self.Output?
        return CurrentValue(self.combineLatest(Just(LookupValue<M?>())).map { new, lookup -> LookupValue<M?> in
            defer { old = new }

            if let model = lookup.value, let old = old, !recreate(old, new) {
                // A backing model exists and can be re-used. Update its configuration.
                dbg("\(model): Re-configuring model since model configuration was updated: \(new)")
                time("Configure \(M.self)") { configure(model, new) }
                time("Configure Update \(M.self)") { lookup.updated() }
                return lookup
            }

            // There is no backing model yet or the configuration update requires recreation of the model.
            if let model = lookup.value {
                dbg("\(model): Replacing model since model configuration was updated: \(new)")
            }
            else {
                dbg("\(M.self): Creating model with initial configuration: \(new)")
            }
            let model = create(new)
            time("Configure \(M.self)") { configure(model, new) }

            // Update our existing publisher with the new backing model, if one exists already.
            time("Creation Update \(M.self)") { lookup.updated(constant: model, updater: { updater($0!, $1) }) }
            return lookup
        }.removeDuplicates(by: { $0 === $1 }).switchToLatest().removeNil())
    }
}

public protocol Updatable: AnyObject {
    func updated()
    func invalidated()
}
