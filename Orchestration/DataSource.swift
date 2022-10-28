//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Combine
import Foundation

// MARK: - Type Declarations

/// A data source is a source for items with specialized handling.
///
/// The data source producer can provide item-specific filtering and provide specialized associated values.
///
/// In addition to a Source, its purpose is to also hide:
/// 1. The details of how a query filters the visible values,
/// 2. The work of calculating additional information for a value (eg. a view).
///
/// Example:
/// Let's imagine a consumer that is a user interface for presenting projects to the user and letting him:
/// 1. Browse the projects,
/// 2. Search for a project by filtering it with a query string,
/// 3. Render a special view for each project with project information,
/// 4. Pick one or more projects to use.
///
/// Now the consumer simply requests a `DataSource<Project, String, AnyView>` without needing to know all the details about:
/// 1. How to fetch the projects and keep them updated,
/// 2. Which project values are still available for a certain string query,
/// 3. How to make a view with project information,
/// 4. How to activate the projects that the user wants to use.
///
/// All of these details are instead implemented on the producer's side, and the interface between the two remains very simple.
///
/// Note: A DataSource is observable and emits a notification whenever any of its public properties are modified.
public protocol DataSource: Source {
    associatedtype Query = Void

    /// A query limits the available values based on the data source's active filter implementation.
    var query: Query? { get set }
}

// MARK: - Type Extensions

public extension Source {
    /// Create a data source from a source by supplying the missing data source capabilities.
    func with<Query>(filter: @escaping (Value, Query?) -> Bool)
        -> AnyDataSource<Value, Query> {
        var query: Query?
        return AnyDataSource<Value, Query>(
            values: { self.values.filter { filter($0, query) } },
            getSelection: { self.selection }, setSelection: { self.selection = $0 },
            getQuery: { query }, setQuery: { query = $0 }
        ).observes(upstream: self)
    }
}

public extension DataSource {
    /// Hide the implementation details of this data source from a consumer.
    func eraseToAnyDataSource()
        -> AnyDataSource<Value, Query> {
        AnyDataSource(self)
    }

    /// Hide the implementation details of this associated data source from a consumer.
    func eraseToAnyDataSource()
        -> AnyDataSource<Value, Query>.Associated<Self.Association> where Self: Associated {
        AnyDataSource.Associated(self, association: self.association(for:))
    }

    /// Add an association to a data source by supplying the missing capabilities.
    func with<Association>(association: @escaping (Value) -> Association?)
        -> AnyDataSource<Value, Query>.Associated<Association> {
        AnyDataSource.Associated<Association>(self, association: association)
    }

    /// Create a new data source based on this data source with modified values.
    func map<V>(value transform: @escaping (Value) -> V)
        -> AnyDataSource<V, Query> {
        self.map(value: { transform($0) }, reverse: { sources, value in
            sources.first {
                AnyChoice<V>.identity(for: transform($0)) == AnyChoice<V>.identity(for: value)
            }
        })
    }

    /// Create a new data source based on this data source with modified values.
    func map<V>(value transform: @escaping (Value) -> V, reverse: @escaping ([Value], V) -> Value?)
        -> AnyDataSource<V, Query> {
        AnyDataSource<V, Query>(
            values: { self.values.compactMap(transform) },
            getSelection: { self.selection.compactMap(transform) },
            setSelection: { self.selection = $0.compactMap { reverse(self.values, $0) } },
            getQuery: { self.query }, setQuery: { self.query = $0 }
        ).observes(upstream: self)
    }

    /// Create a new data source based on this associated data source with modified values.
    func map<V>(value transform: @escaping (Value) -> V)
        -> AnyDataSource<V, Query>.Associated<Self.Association> where Self: Associated {
        self.map(value: { transform($0) }, reverse: { sources, value in
            sources.first {
                AnyChoice<V>.identity(for: transform($0)) == AnyChoice<V>.identity(for: value)
            }
        })
    }

    /// Create a new data source based on this associated data source with modified values.
    func map<V>(value transform: @escaping (Value) -> V, reverse: @escaping ([Value], V) -> Value?)
        -> AnyDataSource<V, Query>.Associated<Self.Association> where Self: Associated {
        AnyDataSource(self).map(value: transform, reverse: reverse).with {
            reverse(self.values, $0).flatMap(self.association(for:))
        }
    }
}

public func + <D1: DataSource, D2: DataSource>(lhs: D1, rhs: D2)
    -> AnyDataSource<D1.Value, D1.Query> where D1.Value == D2.Value, D1.Query == D2.Query {
    AnyDataSource(
        values: { lhs.values + rhs.values },
        getSelection: { lhs.selection + rhs.selection }, setSelection: { selection in
            let lhsIdentities = lhs.values.map(D1.identity(for:))
            let rhsIdentities = rhs.values.map(D2.identity(for:))
            lhs.selection = selection.filter { lhsIdentities.contains(D1.identity(for: $0)) }
            rhs.selection = selection.filter { rhsIdentities.contains(D2.identity(for: $0)) }
        },
        getQuery: { lhs.query ?? rhs.query }, setQuery: { lhs.query = $0; rhs.query = $0 }
    ).observes(upstream: lhs).observes(upstream: rhs)
}

public func + <Value, Query, Association>(
    lhs: AnyDataSource<Value, Query>.Associated<Association>,
    rhs: AnyDataSource<Value, Query>.Associated<Association>
)
    -> AnyDataSource<Value, Query>.Associated<Association> {
    AnyDataSource<Value, Query>.Associated(lhs as AnyDataSource<Value, Query> + rhs as AnyDataSource<Value, Query>) {
        lhs.association(for: $0) ?? rhs.association(for: $0)
    }
}

// MARK: - Concrete Implementations

/// A concrete data source which hides its underlying implementation.
public class AnyDataSource<Value, Query>: AnySource<Value>, DataSource {
    /// Create an inline custom data source implementation.
    public init(values: @escaping () -> [Value],
                getSelection: @escaping () -> [Value], setSelection: @escaping ([Value]) -> Void,
                getQuery: @escaping () -> Query?, setQuery: @escaping (Query?) -> Void) {
        var objectWillChange: Combine.ObservableObjectPublisher?
        self.upstream = (
            getQuery: getQuery, setQuery: { objectWillChange?.send(); setQuery($0) }
        )
        super.init(values: values, getSelection: getSelection, setSelection: setSelection)
        objectWillChange = self.objectWillChange
    }

    // - DataSource
    public var query: Query? {
        get { self.upstream.getQuery() }
        set {
            self.printPrefix.flatMap { Swift.print("\($0): setQuery: \(newValue as Any)") }
            self.upstream.setQuery(newValue)
        }
    }

    // - Private
    fileprivate init<D: DataSource>(_ upstream: D) where D.Value == Value, D.Query == Query {
        self.upstream = (getQuery: { upstream.query }, setQuery: { upstream.query = $0 })
        super.init(upstream)
    }

    private let upstream: (
        getQuery: () -> Query?,
        setQuery: (Query?) -> Void
    )

    public class Associated<Association>: AnyDataSource<Value, Query>, Orchestration.Associated {
        fileprivate init<D: DataSource>(_ upstream: D, association: @escaping (Value) -> Association?) where D.Value == Value,
            D.Query == Query {
            self.association = association
            super.init(upstream)
        }

        // - Association
        public func association(for value: Value) -> Association? {
            using(self.association(value)) { association in
                self.printPrefix.flatMap { Swift.print("\($0): association[value: \(value)] = \(association as Any)") }
            }
        }

        // - Private
        private let association: (Value) -> Association?
    }
}

/// A data source which exposes the latest values from an upstream publisher and allows you to provide operations through combine.
public class SubjectDataSource<Value, Query>: DataSource {
    public init<V: Publisher>(
        upstreamValues: V,
        filter: ((Value, Query?) -> Bool)? = nil,
        upstreamSelection: CurrentValueSubject<[Value], Never> = .init([])
    ) where V.Output: Collection, V.Output.Element == Value, V.Failure == Never {
        self.upstreamValues = upstreamValues.map(AnyCollection.init).eraseToAnyPublisher()
        self.filter = filter

        self.upstream = (
            getSelection: { upstreamSelection.value },
            setSelection: { upstreamSelection.send($0) }
        )

        self.upstreamSubscription = combineLatest(
            self.upstreamValues,
            self.$filter,
            self.$query
        ).sink { upstream, filter, query in
            self.values = filter.flatMap { filter in upstream.filter { filter($0, query) } } ?? Array(upstream)
            self.selection = upstream.filter(self.isSelected(value:))
        }
    }

    public let upstreamValues: AnyPublisher<AnyCollection<Value>, Never>

    @Published
    public var filter: ((Value, Query?) -> Bool)?

    // - Choice
    public typealias _Self = SubjectDataSource
    @PublishedComputed<[Value], _Self>(get: { $0.upstream.getSelection() }, set: { $0.upstream.setSelection($1) })
    public var selection: [Value]
    @PublishedComputed<Value?, _Self>(get: { $0.upstream.getSelection().first }, set: { $0.upstream.setSelection(Array(only: $1)) })
    public var selected: Value?

    // - Source
    @Published
    public private(set) var values: [Value] = []

    // - DataSource
    @Published
    public var  query:                Query?

    // - Private
    private var subscriptions = [AnyCancellable]()
    private var upstreamSubscription: AnyCancellable?
    private let upstream:             (
        getSelection: () -> [Value],
        setSelection: ([Value]) -> Void
    )

    public class Associated<Association>: SubjectDataSource<Value, Query>, Orchestration.Associated {
        public init<V: Publisher>(
            upstreamValues: V,
            filter: ((Value, Query?) -> Bool)? = nil,
            upstreamSelection: CurrentValueSubject<[Value], Never> = .init([]),
            association: @escaping (Value) -> Association?
        ) where V.Output: Collection, V.Output.Element == Value, V.Failure == Never {
            self.association = association
            super.init(upstreamValues: upstreamValues, filter: filter, upstreamSelection: upstreamSelection)
        }

        // - Association
        public func association(for value: Value) -> Association? {
            self.association(value)
        }

        // - Private
        private let association: (Value) -> Association?
    }
}

/// A simple data source owns and manages an in-memory store of values.
public class SimpleDataSource<Value, Query>: DataSource {
    public convenience init(allValues: [Value] = [], selection: [Value] = [])
        where Query == Void {
        self.init(allValues: allValues, filter: nil, selection: selection)
    }

    public init(
        allValues: [Value] = [],
        filter: ((Value, Query?) -> Bool)? = nil,
        selection: [Value] = []
    ) {
        self.allValues = allValues
        self.filter = filter
        self.selection = selection
        self.update()
    }

    public var allValues: [Value] {
        didSet { self.update() }
    }

    public var filter: ((Value, Query?) -> Bool)? {
        didSet { self.update() }
    }

    // - Choice
    public typealias _Self = SimpleDataSource
    @Published
    public var selection: [Value]
    @PublishedComputed<Value?, _Self>(get: { $0.selection.first }, set: { $0.selection = Array(only: $1) })
    public var selected: Value?

    // - Source
    @Published
    public private(set) var values: [Value] = []

    // - DataSource
    @Published
    public var  query: Query? {
        didSet { self.update() }
    }

    // - Private
    private var subscriptions = [AnyCancellable]()

    private func update() {
        var values = self.allValues
        if let filter = self.filter {
            values = values.filter { filter($0, self.query) }
        }
        self.values = values
        self.selection = self.allValues.filter(self.isSelected(value:))
    }

    public class Associated<Association>: SimpleDataSource<Value, Query>, Orchestration.Associated {
        public convenience init(
            allValues: [Value: Association],
            filter: ((Value, Query?) -> Bool)? = nil,
            selection: [Value] = []
        ) where Value: Hashable {
            self.init(allValues: Array(allValues.keys), filter: filter, selection: selection, association: { allValues[$0]! })
        }

        public init(
            allValues: [Value] = [],
            filter: ((Value, Query?) -> Bool)? = nil,
            selection: [Value] = [],
            association: @escaping (Value) -> Association?
        ) {
            self.association = association
            super.init(allValues: allValues, filter: filter, selection: selection)
        }

        // - Association
        public func association(for value: Value) -> Association? {
            self.association(value)
        }

        // - Private
        private let association: (Value) -> Association?
    }
}
