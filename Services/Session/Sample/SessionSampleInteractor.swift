//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Combine
import Foundation

import Orchestration
import Projects
import ProjectsSample
import Session

public class SessionSampleInteractor: SessionInteractor {
    @ErasedCurrentSubject(nil as SessionStage?)
    public var stage:   CurrentValue<SessionStage?, Never>
    @ErasedCurrentSubject([])
    public var methods: CurrentValue<[AuthenticationMethod], Never>
    @ErasedValue(SimpleDataSource(allValues: SampleServer.allCases, selection: [SampleServer.staging]), eraser: { $0.eraseToAnySource() })
    public var server: AnySource<Server>
    public var resetPage: URL { URL(string: "https://hubstaff-account-staging.herokuapp.com/forgot_password")! }

    public init(provideSession: Bool = false) {
        if provideSession {
            self.$stage.send(
                .ready(
                    session: SampleSession(
                        user: sampleUser,
                        lastSync: Date(),
                        server: SampleServer.staging,
                        sessionInteractor: self
                    ),
                    focus: (self.projectsInteractor.global.organizations().value?.first)!
                )
            )
        }
    }

    public func new(forCustomerWithEmail email: String, usingPassword password: String) async throws {
        guard email == "bob@hubstaff.com", password == "bobby"
        else {
            throw SampleSessionError(
                errorDescription: "Incorrect username or password.",
                failureReason: "Use bob@hubstaff.com with password 'bobby' to sign into the sample provider."
            )
        }

        self.$stage.send(
            .ready(
                session: SampleSession(
                    user: sampleUser,
                    lastSync: Date(),
                    server: SampleServer.staging,
                    sessionInteractor: self
                ),
                focus: (self.projectsInteractor.global.organizations().value?.first)!
            )
        )
    }

    public func register(customerNamed fullName: String, withEmail email: String, usingPassword password: String) async throws {
        fatalError("register(customerNamed:withEmail:usingPassword:) has not been implemented")
    }

    public func report(issue: String) async throws {
        fatalError("report(issue:) has not been implemented")
    }

    public func deleteAccount() async throws {
        fatalError("delete() has not been implemented")
    }

    public func reset() async {
        self.$stage.send(.unidentified)
    }

    public func set(organization: Organization) {
        self.$stage.send(
            .ready(
                session: SampleSession(
                    user: sampleUser,
                    lastSync: Date(),
                    server: self.$server.selected!,
                    sessionInteractor: self
                ),
                focus: organization
            )
        )
    }

    // MARK: - Private

    private lazy var projectsInteractor: ProjectsInteractor = Registry.shared.resolve()
}

public struct SampleSessionError: LocalizedError {
    public let errorDescription:   String?
    public let failureReason:      String?
    public let recoverySuggestion: String?
    public let helpAnchor:         String?

    public init(errorDescription: String, failureReason: String? = nil, recoverySuggestion: String? = nil, helpAnchor: String? = nil) {
        self.errorDescription = errorDescription
        self.failureReason = failureReason
        self.recoverySuggestion = recoverySuggestion
        self.helpAnchor = helpAnchor
    }
}

struct SampleSession: Session {
    var user:              User
    var lastSync:          Date
    var server:            Server
    let sessionInteractor: SessionSampleInteractor

    func focus(organization: Organization) {}

    func deleteAccount() async throws {
        try await self.sessionInteractor.deleteAccount()
    }
}

enum SampleServer: Server, CaseIterable, Identifiable, Hashable {
    static var allCases: [SampleServer] = [.production, .staging, .pr(number: 1234)]

    case production
    case staging
    case pr(number: Int)

    var id: ID {
        ID(self.name.hashValue)
    }

    var name: String {
        switch self {
            case .production:
                return "Hubstaff Production"
            case .staging:
                return "Hubstaff Staging"
            case .pr:
                return "Hubstaff Pull Request"
        }
    }

    var specifier: String? {
        get {
            switch self {
                case .production, .staging:
                    return nil
                case let .pr(number):
                    return "\(number)"
            }
        }
        set {
            if case .pr = self {
                self = .pr(number: Int(newValue ?? "") ?? 0)
            }
        }
    }
}

public struct SampleUser: User, Hashable {
    public let      email:  String
    public var      id:     ID { self.member.id }
    public var      name:   String { self.member.name }
    public var      avatar: Avatar { self.member.avatar }
    fileprivate let member: SampleMember
}

public var sampleUser = SampleUser(
    email: "sean.webster@hubstaff.com",
    member: sampleMembers[0]
)
