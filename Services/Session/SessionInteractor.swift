//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Combine
import Foundation

import Orchestration
import Projects

/// The session module provides access to global application state specific to a fully authenticated user.
public protocol SessionInteractor: Interactor {
    /// The stage of engaging with a Hubstaff server session that the user's account is currently in. `nil` while the system is transitioning.
    var stage:   CurrentValue<SessionStage?, Never> { get }

    /// The authentication methods currently supported by the active Hubstaff server, in order of preference.
    var methods: CurrentValue<[AuthenticationMethod], Never> { get }

    /// The source of Hubstaff servers currently available. The selected server will be used for new sessions.
    var server:  AnySource<Server> { get }

    /// Request that a new customer account be created on the Hubstaff server.
    /// A successful authentication will emit an update with a valid session to \stage.
    ///
    /// - Parameters:
    ///   - fullName: The first and last name of the user to create an account for.
    ///   - email: The e-mail address to register the user's Hubstaff account under.
    ///   - password: The password the user will be using to prove their authenticity.
    /// - Throws: When the requested Hubstaff user account could not be created on the server.
    func register(customerNamed fullName: String, withEmail email: String, usingPassword password: String) async throws

    /// End the current user session, removing all active state on the currently authenticated user.
    ///
    /// A successful invalidation will emit an update with an `unidentified` value to \SessionInteractor.stage, removing the current session if there was one.
    func reset() async

    /// Report an issue encountered by the user during the current session.
    ///
    /// - Parameter issue: A detailed description of what the user was expecting and what he experienced instead.
    /// - Throws: When report is not submitted.
    func report(issue: String) async throws
}

/// Different ways for users to authenticate themselves to the system.
public enum AuthenticationMethod {
    /// This legacy method uses the user's e-mail address and their Hubstaff password to authenticate them.
    ///
    /// - Parameter begin: Try to open a new session by authenticating the user that's currently using the application.
    /// - Parameter email: The e-mail address the user has registered to their Hubstaff account.
    /// - Parameter password: The password the user uses to prove their authenticity.
    /// - Parameter resetPage: A web page that allows the user to reset their access credentials with the current server.
    case direct(begin: (_ email: String, _ password: String) async throws -> Void, resetPage: () -> URL)
    /// This method uses a global web authentication session where the user can interact with their organization's configured authentication method.
    ///
    /// - Parameter begin: Try to open a new session by authenticating the user that's currently using the application.
    case oauth(begin: () async throws -> Void)
}

/// The stage of the Hubstaff user account that the system is engaged with.
public enum SessionStage {
    /// No account is currently active in the system.
    case unidentified
    /// The active account is still pending activation confirmation. The user may need to click a link in a confirmation email.
    case unconfirmed
    /// No Hubstaff organization focus has been set. The user may need to select, create or join an organization.
    case unfocused(session: Session)
    /// The active account is ready for use.
    case ready(session: Session, focus: Organization)
}

/// A session represents the global application state of the currently authenticated user.
public protocol Session {
    /// The fully authenticated user currently using the application.
    var user:     User { get }
    /// The recency of the current data available in the application.
    var lastSync: Date { get }
    /// The Hubstaff services instance that is providing the user's data.
    var server:   Server { get }
    /// Focus the application on the organization. Focussed views will ignore other applications the user may be a member of.
    func focus(organization: Organization)
    /// Request that the currently-logged-in user's account be permanently deleted from the session's Hubstaff server.
    ///
    /// - Throws: When the Hubstaff server could not be reached or could not fulfill the request.
    func deleteAccount() async throws
}

/// A server represents an instance of the Hubstaff platform that supplies the services being used.
public protocol Server: Entity {
    /// A short description to the user for what connecting to this server represents.
    var name:      String { get }
    /// Some servers take an additional specifier to distinguish between separate sets within its domain, such as the PR servers.
    var specifier: String? { get set }
}

public protocol User: Member {
    var email: String { get }
}

// MARK: - Boilerplate

extension SessionStage: Unitary {
    public var id:           Int {
        switch self {
            case .unidentified: return 1
            case .unconfirmed: return 2
            case .unfocused: return 3
            case .ready: return 4
        }
    }

    /// The current user session if in a stage where one is available (ie. the user has been authorized).
    public var session:      Session? {
        switch self {
            case let .unfocused(session), let .ready(session, _):
                return session
            default:
                return nil
        }
    }

    /// The currently focussed organization if in a stage where it is set.
    public var organization: Organization? {
        switch self {
            case let .ready(_, organization):
                return organization
            default:
                return nil
        }
    }
}
