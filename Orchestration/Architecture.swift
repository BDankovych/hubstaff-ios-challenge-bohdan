//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

/// This application implements a modular architecture.
///
/// High-level, what you need to take away is that every module should be:
///
/// 1. Exposed through a contract. The way to use the module is exposed through a protocol that extends a Contract.
/// 2. Self-contained. The implementation only ever calls methods that are inside its own module or exposed by a Contract.
/// 3. Interchangeable. One module can easily be substituted for a different module that implements the same Contract.
/// 4. A Feature or a Service. Features provide a user interface, services a business interface.
///
/// We adopt the VIPER pattern. Please pay close attention to the connecting arrows.
///
/// ```
/// [== FEATURE ========]    [== SERVICE ===========]
/// [          ROUTER   ]
/// [             |     ]
/// [ VIEW —> PRESENTER ] —> [ INTERACTOR —> ENTITY ]
/// ```
///
/// 1. Feature modules expose a Router contract.
/// 2. Service modules expose an Interactor contract.
/// 3. A feature's Router exposes its entry points through public Presenters.
/// 4. A feature's View pulls data from its Presenter, which optionally resolves it from an Interactor.
/// 5. A feature's Presenter uses the Router to find other Presenters, in the same or from other features.
/// 6. A service's Interactor exposes a business interface to access or mutate Entity data.
/// 7. Any of these components should only ever make calls in the direction of their outgoing arrows.
///     (eg. a Router should not call a View and a View should not call an Interactor)
///
/// - SeeAlso: https://docs.google.com/document/d/1bdrB9rDwBsGeW2rbzGgymK1HA4XsOwyCJUYfl4JDzP4/edit?pli=1#heading=h.uqws5kpc32ug
import Combine
import Foundation
import SwiftUI

// MARK: - Architecture

/// A contract is the description of what capabilities are available in a component, defining how they can and should be used.
///
/// The contract can be satisfied by different implementations, allowing the application to substitute one for the other.
public protocol Contract {}

/// A router exposes a feature's public presenters to other routers.
///
/// Internally, a router is used by the feature module's presenters to look up other presenters.
/// Internal presenters are accessed directly by the router and external presenters are accessed by interacting with the public interface of other routers.
///
/// The job of a router is to centralize the choices of which presenters will be used to satisfy a certain UI requirement.
public protocol Router: Contract {}

/// An app router provides an entry point to the main UI through which the user will interact with the application's capabilities.
public protocol AppRouter: Router {
    var appPresenter: ScreenPresenter { get }
}

/// A feature router provides an entry point through which the user can begin using the feature.
public protocol FeatureRouter: Router {
    var featurePresenter: ScreenPresenter { get }
}

/// A presenter provides a view for a user to interact with a certain capability.
///
/// Internally, the presenter uses an interactor to supply and mutate data into the view model.
/// It obtains other presenters from its router to respond to view interactions.
///
/// The job of a presenter is to translate business data into view-specific representations and respond to user requests.
public protocol Presenter: Contract {
    var view: AnyView { get }
}

/// A screen presenter is any presenter that presents a fully self-contained interface.
public protocol ScreenPresenter: Presenter {}

/// A view model is a light-weight structure that holds the presentation data that the view will use. It is populated by a view's presenter.
public protocol ViewModel {
    init()
}

/// A model presenter is a presenter that uses a view model to relay its presentation data to the view.
///
/// Typically, your presenter will inherit directly from this supertype.
/// It is very useful for allowing your preview to present custom model data without instantiating a fully functional backing presenter.
open class ModelPresenter<M: ViewModel>: ObservableObject {
    @Published
    public var model: M
    public var modelBinding: Binding<M> { Binding { self.model } set: { self.model = $0 } }

    public init(model: M = M()) {
        self.model = model
    }
}

/// A view provides the interaction model and hierarchy that the user will be directly exposed to.
///
/// Internally, the view sources its data from a model and invokes a presenter to relay user intentions.
///
/// The job of the view is to lay out the presenter's data in a way that allows a user to easily interpret and interact with it.
public protocol ModelView: View {
    associatedtype M: ViewModel
    associatedtype P: Presenter // where P.M == M

    /// The view's Presenter is responsible for reacting to user actions, requests and events.
    ///
    /// Usually you will declare this property using:
    ///     @ObservedOptionalObject
    ///     var presenter: MyPresenter?
    var presenter: P? { get }
    /// The view's ViewModel provides all the data that this view presents to the user.
    ///
    /// Usually you will declare this property using:
    ///     @Binding
    ///     var model: MyModel
    var model:     M { get nonmutating set }
}

/// An interactor exposes the service's business interface for engaging with entity data.
///
/// Internally, an interactor loads entity data, defines the contract for manipulating it and facilitates synchronization.
///
/// The job of an interactor is to centralize all the validation and logic for the entity state machine, entirely independently from any feature concerns.
public protocol Interactor: Contract {}

/// An entity describes the present state of a unique element in a state machine.
///
/// Internally, entities can evolve over time, however this instance describes an immutable snapshot representation of the entity at a precise moment in the state machine's evolution.
///
/// The job of an entity is to hold the service's authoritative data.
public protocol Entity {
    typealias ID = Int64

    /// An identifier for the entity's stable state which never changes during its lifetime, uniquely grouping all instances describing the same entity together.
    var id:    ID { get }
    /// An identifier for the entity's non-stable state as it evolves over time.
    var state: AnyHashable { get }
}

public func ~= (lhs: Entity?, rhs: Entity?) -> Bool {
    lhs?.id == rhs?.id
}

/// A wrapper type for erasing an entity's concrete type into an opaque entity, adopting conformance with Hashable and Identifiable.
@propertyWrapper
// FIXME: https://bugs.swift.org/browse/SR-55 -- Ideally E : Entity, and remove `entity`.
public struct AnyEntity<E/*: Entity */>: Entity {
    public var wrappedValue: E
    public var entity:       Entity? {
        self.wrappedValue as? Entity
    }

    public init(_ wrappedValue: E) {
        self.init(wrappedValue: wrappedValue)
    }

    public init(wrappedValue: E) {
        self.wrappedValue = wrappedValue
    }
}

// MARK: - Stubs

/// A concrete type that can be any router, and is identifiable to determine when its value changes.
public struct AnyFeatureRouter: FeatureRouter, Identifiable {
    public var featurePresenter: ScreenPresenter { self.router.featurePresenter }
    public var id:               AnyHashable

    public init<R: FeatureRouter & AnyObject>(_ router: R) {
        self.router = router
        self.id = ObjectIdentifier(router)
    }

    public init<R: FeatureRouter & Identifiable>(_ router: R) {
        self.router = router
        self.id = router.id
    }

    // - Private
    private let router: FeatureRouter
}

/// An empty router is a stub feature router that can be used to quickly satisfy any requirement for a feature.
public class SimpleFeatureRouter: FeatureRouter {
    public let featurePresenter: ScreenPresenter

    public init(view: AnyView = AnyView(EmptyView())) {
        self.featurePresenter = SimpleScreenPresenter(view: view)
    }
}

/// An empty screen presenter is a stub presenter that can be used to quickly satisfy any presenter requirement.
///
/// It supplies a view representation that is an empty view with a clear fill color.
public struct SimpleScreenPresenter: ScreenPresenter {
    public let view: AnyView

    public init(view: AnyView = AnyView(EmptyView())) {
        self.view = view
    }
}

// MARK: - Boilerplate

// FIXME: https://github.com/apple/swift-evolution/blob/main/proposals/0309-unlock-existential-types-for-all-protocols.md
public extension Entity where Self: Hashable {
    var state: AnyHashable {
        AnyHashable(self)
    }
}

extension AnyEntity: Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.entity?.state == rhs.entity?.state
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.entity?.state)
    }
}

extension AnyEntity: Identifiable {
    public var id: ID {
        self.entity?.id ?? 0
    }
}

public extension Optional where Wrapped == [Entity] {
    static func == (lhs: Self, rhs: Self) -> Bool {
        if let lhs = lhs {
            if let rhs = rhs {
                return lhs == rhs
            }
            else {
                return false
            }
        }
        else {
            return true
        }
    }

    static func != (lhs: Self, rhs: Self) -> Bool {
        !(lhs == rhs)
    }
}
