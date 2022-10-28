//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Combine
import Foundation
import Orchestration
import Projects
import UIKit

public var sampleOrganizations = [
    SampleOrganization(
        id: 1,
        title: "Maarten's Sand Castle",
        avatar: .init(SimpleAvatar(
            image: nil,
            tint: SampleTint(red: 0.75, green: 0.7, blue: 0.07),
            moniker: "M"
        )),
        features: [.locationTracking, .workOrders],
        userPermissions: [.createProject],
        projects: [
            SampleProject(
                id: 15,
                type: .field,
                title: "Product design",
                avatar: SimpleAvatar(
                    image: nil,
                    tint: SampleTint(red: 0.07, green: 0.08, blue: 0.78),
                    moniker: "P"
                ),
                tasks: [
                    SampleTask(id: 151, title: "Mobile app redesign"),
                ]
            ),
            SampleProject(
                id: 14,
                type: .field,
                title: "Feature Dig Site",
                avatar: SimpleAvatar(
                    image: nil,
                    tint: SampleTint(red: 0.07, green: 0.08, blue: 0.78),
                    moniker: "A"
                ),
                tasks: [
                    SampleTask(id: 141, title: "Find a spot"),
                    SampleTask(id: 142, title: "Gather sand"),
                    SampleTask(id: 143, title: "Outline structure"),
                    SampleTask(id: 144, title: "Source water"),
                    SampleTask(id: 145, title: "Prepare sand mixture"),
                    SampleTask(id: 146, title: "Construct the Keep"),
                ]
            ),
            SampleProject(
                id: 11,
                type: .desk,
                title: "Blank Project",
                avatar: SimpleAvatar(
                    image: nil,
                    tint: SampleTint(red: 0.19, green: 0.5, blue: 0.35),
                    moniker: "B"
                ),
                tasks: []
            ),
            SampleProject(
                id: 12,
                type: .field,
                title: "Task Dig Site",
                avatar: SimpleAvatar(
                    image: nil,
                    tint: SampleTint(red: 0.58, green: 0.04, blue: 0.35),
                    moniker: "T"
                ),
                tasks: []
            ),
            SampleProject(
                id: 13,
                type: .field,
                title: "MA1000 - Sand Man",
                avatar: SimpleAvatar(
                    image: nil,
                    tint: SampleTint(red: 0.27, green: 0.27, blue: 0.78),
                    moniker: "S"
                ),
                tasks: []
            ),
        ],
        breaks: [
            SampleBreak(id: 1401, title: "Lunch Break", duration: 30 * 60),
            SampleBreak(id: 1402, title: "Sigh Break", duration: 5),
        ]
    ),

    SampleOrganization(
        id: 0,
        title: "Asana Organization",
        avatar: .init(SimpleAvatar(
            image: nil,
            tint: SampleTint(red: 190, green: 50, blue: 20),
            moniker: "A"
        )),
        features: [.locationTracking],
        userPermissions: [],
        projects: [
            SampleProject(
                id: 10,
                type: .desk,
                title: "Asana Project",
                avatar: SimpleAvatar(
                    image: nil,
                    tint: SampleTint(red: 0.1, green: 0.2, blue: 0.8),
                    moniker: "A"
                ),
                tasks: []
            ),
        ],
        breaks: []
    ),
]

public var sampleMembers = [
    SampleMember(
        id: 0,
        name: "Sean Webster",
        avatar: .init(SimpleAvatar(image: nil, tint: SampleTint(UIColor.systemRed), moniker: "S")),
        memberships: [sampleOrganizations[0]]
    ),
    SampleMember(
        id: 1,
        name: "Jeff Burton",
        avatar: .init(SimpleAvatar(image: nil, tint: SampleTint(UIColor.systemBlue), moniker: "J")),
        memberships: [sampleOrganizations[0]]
    ),
    SampleMember(
        id: 2,
        name: "Allen Rodgers",
        avatar: .init(SimpleAvatar(image: nil, tint: SampleTint(UIColor.systemPink), moniker: "A")),
        memberships: [sampleOrganizations[1]]
    ),
    SampleMember(
        id: 3,
        name: "Scott McCormick",
        avatar: .init(SimpleAvatar(image: nil, tint: SampleTint(UIColor.systemOrange), moniker: "S")),
        memberships: [sampleOrganizations[0], sampleOrganizations[1]]
    ),
    SampleMember(
        id: 4,
        name: "Aaron Logan",
        avatar: .init(SimpleAvatar(image: nil, tint: SampleTint(UIColor.systemIndigo), moniker: "A")),
        memberships: [sampleOrganizations[0], sampleOrganizations[1]]
    ),
    SampleMember(
        id: 5,
        name: "Alessia Taylor",
        avatar: .init(SimpleAvatar(image: nil, tint: SampleTint(UIColor.systemGreen), moniker: "A")),
        memberships: [sampleOrganizations[0], sampleOrganizations[1]]
    ),
    SampleMember(
        id: 6,
        name: "Bradley Morrison",
        avatar: .init(SimpleAvatar(image: nil, tint: SampleTint(UIColor.systemYellow), moniker: "B")),
        memberships: [sampleOrganizations[0], sampleOrganizations[1]]
    ),
    SampleMember(
        id: 7,
        name: "Linda van Meyde",
        avatar: .init(SimpleAvatar(image: nil, tint: SampleTint(UIColor.systemTeal), moniker: "L")),
        memberships: [sampleOrganizations[0], sampleOrganizations[1]]
    ),
    SampleMember(
        id: 8,
        name: "Bradley Morrison",
        avatar: .init(SimpleAvatar(image: nil, tint: SampleTint(UIColor.systemPurple), moniker: "B")),
        memberships: [sampleOrganizations[0], sampleOrganizations[1]]
    ),
    SampleMember(
        id: 9,
        name: "Natalia Wilczynska",
        avatar: .init(SimpleAvatar(image: nil, tint: SampleTint(UIColor.systemGray), moniker: "N")),
        memberships: [sampleOrganizations[0], sampleOrganizations[1]]
    ),
]

public class ProjectsSampleInteractor: ProjectsInteractor {
    public init() {}

    public var global: ProjectsContext = SampleProjectsContext()

    public func filtered<T: Publisher, K: Publisher>(by term: T, kind: K) -> FilteredProjectsContext
        where T.Output == String?, T.Failure == Never, K.Output == FilteredKind?, K.Failure == Never {
        SampleProjectsContext(term: term, kind: kind)
    }

    public func state(forOrganization organization: Organization) -> CurrentValue<OrganizationState, Never> {
        CurrentValue(Just(sampleOrganizations.first(where: { $0 ~= organization })! as OrganizationState))
    }

    public func state(forTask task: Projects.Task) -> StateType {
        .userTask(self.taskDetails[task.id, defaultSet: CurrentValue(self.taskDetailsSubjects[
            task.id, defaultSet: self.createTaskDetails(forTask: task)
        ].map { $0 as UserTaskState })])
    }

    public func job(forTask task: UserTask) -> UserJob? {
        nil
    }

    public func complete(task: UserTask) {
        self.taskDetailsSubjects[task.id]?.value.completion = .finished
    }

    public func join(organizationWithEmail email: String) async throws {
        fatalError("join(organizationWithEmail:) has not been implemented")
    }

    public func createOrganizationForm() -> FieldForm {
        SimpleForm(fields: [
            SimpleField(label: "Name", hint: "Organization name", value: .text(value: nil)),
            SimpleField(label: "Industry", hint: "Industry", value: .option(value: nil)),
            SimpleField(label: "Team size", hint: "Team size", value: .option(value: nil)),
        ])
    }

    public func createProjectForm(forOrganization organization: Organization?) -> FieldForm {
        fatalError("createProjectForm(forOrganization:) has not been implemented")
    }

    public func createTaskForm(forProject project: UserProject) -> FieldForm {
        fatalError("createTaskForm(forProject:) has not been implemented")
    }

    public func refresh() {}

    // - Private

    private lazy var taskDetailsSubjects: [Task.ID: CurrentValueSubject<SampleTaskState, Never>] = [:]
    private lazy var taskDetails:         [Task.ID: CurrentValue<UserTaskState, Never>]          = [:]

    private func createTaskDetails(forTask task: Task) -> CurrentValueSubject<SampleTaskState, Never> {
        let sampleTask = task as! SampleTask // swiftlint:disable:this force_cast

        return .init(SampleTaskState(
            id: task.id,
            userTask: .init(sampleTask),
            details: "Details!",
            client: ["Cyclops, Inc", "Beasts with claws, Inc", "Neversleep, Inc", "BadLands, Inc"].randomElement(),
            timeSpan: Bool.random() ? DateInterval(start: Date(), duration: 37 * 60) : nil,
            url: nil,
            integration: "Sample",
            fields: .init([]),
            completion: .available,
            deletion: .available
        ))
    }
}

public class SampleProjectsContext: FilteredProjectsContext {
    public var  term:    String?
    public var  kind:    FilteredKind?
    public var  exclude: FilteredExclusion = []
    private var monitor: AnyCancellable?

    public required init() {}

    public convenience init<T: Publisher, K: Publisher>(term: T, kind: K)
        where T.Output == String?, T.Failure == Never, K.Output == FilteredKind?, K.Failure == Never {
        self.init()

        self.monitor = combineLatest(
            term.removeDuplicates(),
            kind.removeDuplicates()
        ).sink(
            receiveCompletion: { _ in self.term = nil; self.kind = nil },
            receiveValue: {
                self.term = $0.0
                self.kind = $0.1

                self.tasksSubjects.forEach {
                    $0.value.value = self.filtered(tasks: $0.value.value, forProjectId: $0.key)
                }

                self.projectsSubjects.forEach {
                    $0.value.value = self.filtered(projects: $0.value.value, forOrganizationId: $0.key)
                }
            }
        )
    }

    public func organizations() -> CurrentValue<[Organization]?, Never> {
        CurrentValue(Just(sampleOrganizations))
    }

    public func projects(for organization: Organization) -> CurrentValue<[UserProject], Never> {
        let allProjects = sampleOrganizations.first { $0 ~= organization }?.projects ?? []
        return self.projects[organization.id, defaultSet: CurrentValue(self.projectsSubjects[
            organization.id, defaultSet: CurrentValueSubject(allProjects)
        ].map { $0 as [UserProject] })]
    }

    public func tasks(for project: UserProject) -> CurrentValue<[UserTask], Never> {
        let allTasks = sampleOrganizations.flatMap(\.projects).first { $0 ~= project }?.tasks ?? []
        return self.tasks[project.id, defaultSet: CurrentValue(self.tasksSubjects[
            project.id, defaultSet: CurrentValueSubject(allTasks)
        ].map { $0 as [UserTask] })]
    }

    public func breaks(for organization: Organization) -> CurrentValue<[BreakPolicy], Never> {
        let allBreaks = sampleOrganizations.first { $0 ~= organization }?.breaks ?? []
        return self.breaks[organization.id, defaultSet: CurrentValue(self.breaksSubjects[
            organization.id, defaultSet: CurrentValueSubject(allBreaks)
        ].map { $0 as [BreakPolicy] })]
    }

    // - Private

    private func filtered(projects: [SampleProject], forOrganizationId: Organization.ID) -> [SampleProject] {
        var filteredProjects = projects

        // Exclude projects based on their kind
        if let kind = self.kind {
            filteredProjects = filteredProjects.filter {
                map(from: $0.type, where: [
                    (if: .field, then: .field),
                    (if: .desk, then: .desk),
                ]) == kind
            }
        }

        // Exclude projects based on title search query,
        // keep the projects if there are tasks in search results too
        if let term = self.term, !term.isEmpty {
            filteredProjects = filteredProjects.filter {
                $0.title.lowercased().contains(term.lowercased()) || self.tasks[$0.id]?.value.isEmpty == false
            }
        }

        if self.term?.isEmpty == true, self.kind == nil {
            filteredProjects = sampleOrganizations.first { $0.id == forOrganizationId }?.projects ?? []
        }

        return filteredProjects
    }

    private func filtered(tasks: [SampleTask], forProjectId: UserProject.ID) -> [SampleTask] {
        if let term = self.term, !term.isEmpty {
            return tasks.filter { $0.title.lowercased().contains(term.lowercased()) }
        }
        else {
            return sampleOrganizations.flatMap(\.projects).first { $0.id == forProjectId }?.tasks ?? []
        }
    }

    private lazy var projects: [Organization.ID: CurrentValue<[UserProject], Never>] = [:]
    private lazy var tasks:    [UserProject.ID: CurrentValue<[UserTask], Never>]     = [:]
    private lazy var breaks:   [Organization.ID: CurrentValue<[BreakPolicy], Never>] = [:]

    private lazy var projectsSubjects: [Organization.ID: CurrentValueSubject<[SampleProject], Never>] = [:]
    private lazy var tasksSubjects:    [UserProject.ID: CurrentValueSubject<[SampleTask], Never>]     = [:]
    private lazy var breaksSubjects:   [UserProject.ID: CurrentValueSubject<[SampleBreak], Never>]    = [:]
}

public struct SampleTint: Tint {
    public static func random() -> SampleTint {
        .init(red: .random(in: 0 ..< 1), green: .random(in: 0 ..< 1), blue: .random(in: 0 ..< 1))
    }

    public let extendedSRGB: (red: Double, green: Double, blue: Double)

    public init(red: Double, green: Double, blue: Double) {
        self.extendedSRGB = (red: red, green: green, blue: blue)
    }

    public init(_ tint: Tint) {
        self.extendedSRGB = tint.extendedSRGB
    }
}

public struct SampleOrganization: Organization, OrganizationState, Identifiable, Hashable {
    public let id: ID

    public let title:  String
    @ErasedValue<SimpleAvatar, Avatar>
    public var avatar: Avatar

    public var organization:    Organization { self }
    public let features:        [OrganizationFeature]
    public var userPermissions: [OrganizationPermission]
    public var projects:        [SampleProject]
    public var breaks:          [SampleBreak]

    public var state: AnyHashable {
        AnyHashable(self.projects)
    }
}

public struct SampleProject: UserProject, Identifiable, Hashable {
    public let id: ID

    public let type:   FilteredKind
    public let title:  String
    @ErasedValue<SimpleAvatar, Avatar>
    public var avatar: Avatar

    public var tasks: [SampleTask]

    public var state: AnyHashable {
        AnyHashable(self.tasks)
    }

    public init(id: ID, type: FilteredKind, title: String, avatar: SimpleAvatar, tasks: [SampleTask]) {
        self.id = id
        self.type = type
        self.title = title
        self._avatar = .init(avatar)
        self.tasks = tasks
    }
}

public struct SampleTask: UserTask, Identifiable, Hashable {
    public let id: ID

    public let title: String

    public let client:   String?
    public let timeSpan: DateInterval?

    public var project: UserProject {
        sampleOrganizations.compactMap { $0.projects.first { $0.tasks.contains { $0 ~= self } } }[0]
    }

    public init(id: ID, title: String, client: String? = nil, timeSpan: DateInterval? = nil) {
        self.id = id
        self.title = title
        self.client = client
        self.timeSpan = timeSpan
    }
}

public struct SampleBreak: BreakPolicy, Identifiable, Hashable {
    public let id: ID

    public let title:    String
    public let duration: TimeInterval
}

public struct SampleTaskState: UserTaskState, Identifiable, Hashable {
    public let id: ID

    public var task:     Task { self.userTask }
    @ErasedValue<SampleTask, UserTask>
    public var userTask: UserTask

    public var title:   String { self.task.title }
    public let details: String

    public var client:   String?
    public var timeSpan: DateInterval?

    @IgnoreHashable
    public var url:         (() async -> URL?)?
    public let integration: String
    @ErasedValue<[SampleTaskAttribute], [TaskAttribute]>
    public var fields:      [TaskAttribute]

    public var completion: ProgressiveState
    public let deletion:   ProgressiveState
}

public struct SampleTaskAttribute: TaskAttribute, Hashable {
    public var id:    String
    public var label: String
    public var value: AttributeValue
    public var type:  TaskAttributeType?
}

public struct SampleMember: Member, Hashable {
    public var id: ID

    public var name:   String
    @ErasedValue<SimpleAvatar, Avatar>
    public var avatar: Avatar

    public var memberships: [SampleOrganization]
}
