//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Combine
import CoreLocation
import Foundation

import Orchestration

/// The data module provides access to the application's authoritative models.
public protocol ProjectsInteractor: Interactor {
    /// A context for unfiltered access to all project-related entities available to the current user.
    var global: ProjectsContext { get }

    /// A context for access to all project-related entities which can be filtered down to a selective subset of the global entities.
    func filtered<T: Publisher, K: Publisher>(by term: T, kind: K) -> FilteredProjectsContext
        where T.Output == String?, T.Failure == Never, K.Output == FilteredKind?, K.Failure == Never

    /// The current system state of the given organization.
    func state(forOrganization organization: Organization) -> CurrentValue<OrganizationState, Never>
    /// The current system state of the given task.
    func state(forTask task: Task) -> StateType
    /// The job that the task is associated with, if it is a task in a project with work order integration.
    func job(forTask task: UserTask) -> UserJob?
    /// Mark a specific task as having been completed by the user. Has no effect if the task's `completion` state is not `available`.
    func complete(task: UserTask)

    /// Send a request to join an organization owned by the Hubstaff member with the given e-mail address.
    ///
    /// - Parameters:
    ///   - email: The e-mail address of the member whose Hubstaff account owns the organization to join.
    /// - Throws: When the Hubstaff server could not service the join request at the given e-mail address.
    func join(organizationWithEmail email: String) async throws
    /// Obtain a form used for creating a new organization.
    ///
    /// When the form is submitted successfully, a new organization reflecting the form's fields will be added to the server.
    func createOrganizationForm() -> FieldForm
    /// Obtain a form used for creating a new project in a given organization.
    ///
    /// When the form is submitted successfully, a new project reflecting the form's fields will be added to the organization.
    ///
    /// - Parameter organization: Pre-selected organization in the project creation form. May be changed in the form returned.
    func createProjectForm(forOrganization organization: Organization?) -> FieldForm
    /// Obtain a form used for creating a new task in a given project.
    ///
    /// When the form is submitted successfully, a new task reflecting the form's fields will be added to the project.
    func createTaskForm(forProject project: UserProject) -> FieldForm

    /// Request an update for all project-related data entities.
    func refresh()
}

public protocol ProjectsContext {
    /// The Hubstaff organizations that are known to the current user.
    ///
    /// Publishes `nil` when the current user is new and has not yet been invited to any organization.
    func organizations() -> CurrentValue<[Organization]?, Never>
    /// The Hubstaff projects under the given organization that are available to the current user.
    func projects(for organization: Organization) -> CurrentValue<[UserProject], Never>
    /// The Hubstaff tasks under the given project that are available to the current user.
    func tasks(for project: UserProject) -> CurrentValue<[UserTask], Never>
    /// The breaks available to users while working for the given organization.
    func breaks(for organization: Organization) -> CurrentValue<[BreakPolicy], Never>
}

public protocol FilteredProjectsContext: AnyObject, ProjectsContext {
    /// If set, all collections within this context return only those values which pass the filter.
    var term:    String? { get set }
    var kind:    FilteredKind? { get set }
    var exclude: FilteredExclusion { get set }
}

public enum FilteredKind {
    case desk
    case field
}

public struct FilteredExclusion: OptionSet {
    public static var completed: FilteredExclusion = .init(rawValue: 1 << 0)
    public static var deleted:   FilteredExclusion = .init(rawValue: 1 << 1)

    public init(rawValue: Int) { self.rawValue = rawValue }

    public let rawValue: Int
}

/// Any individual using the Hubstaff platform as a participant to one or more organizations.
public protocol Member: Entity {
    var name:   String { get }
    var avatar: Avatar { get }
}

/// An organization represents a direct Hubstaff customer entity that governs all projects, tasks and members under it.
public protocol Organization: Entity {
    var title:  String { get }
    var avatar: Avatar { get }
}

/// Any information directly associated with an organization that is not unique to its identity is available here.
public protocol OrganizationState: Entity {
    var organization:    Organization { get }
    var features:        [OrganizationFeature] { get }
    var userPermissions: [OrganizationPermission] { get }
}

/// An organization feature is a mechanism to allow / deny specific functionality
public enum OrganizationFeature: Hashable {
    case locationTracking
    case projects
    case workBreaks
    case workOrders
    case other(feature: String)
}

/// An organization permission is a capability that is available to a user in the context of an organization.
public enum OrganizationPermission: Hashable {
    case createProject
}

/// A project is a grouping within an organization under which members assign and perform tasks.
public protocol Project: Entity {
    var title:  String { get }
    var avatar: Avatar { get }
}

/// A project that the current user has been assigned access to.
public protocol UserProject: Project {}

/// A task is the description of an action item against which organization members are able to perform work.
public protocol Task: Entity {
    var title: String { get }
}

/// A task that the current user has been assigned access to.
public protocol UserTask: Task {
    var project:  UserProject { get }
    var timeSpan: DateInterval? { get }
}

/// The current state of a task in the Hubstaff system.
public protocol TaskState: Entity {
    var task: Task { get }

    var title:   String { get }
    var details: String { get }
}

/// The current state of a task, which is assigned to the current user, in the Hubstaff system.
public protocol UserTaskState: TaskState {
    // FIXME: https://forums.swift.org/t/using-subtypes-in-the-implementation-of-protocol-properties-and-function-return-values/51430/15
    var userTask: UserTask { get }

    var url:         (() async -> URL?)? { get }
    var integration: String { get }
    var fields:      [TaskAttribute] { get }

    var completion: ProgressiveState { get }
    var deletion:   ProgressiveState { get }
}

/// A job is a kind of task under the work order project integration type. Work can be tracked against them, and they can also be scheduled.
public protocol Job: Task {}

/// A job that the current user has been assigned access to.
public protocol UserJob: Job, UserTask {
    var client: String { get }
}

/// The current state of a job in the Hubstaff system.
public protocol JobState: TaskState {
    // FIXME: https://forums.swift.org/t/using-subtypes-in-the-implementation-of-protocol-properties-and-function-return-values/51430/15
    var job: Job { get }

    var instructions: String { get }
    var timeSpan:     DateInterval { get }
    var worked:       (amount: TimeInterval, span: DateInterval)? { get }
    var site:         JobSite? { get }

    var status:    JobStatus { get }
    var assignees: [Member] { get }
    var notes:     [JobNote] { get }
}

/// The current state of a job, which is assigned to the current user, in the Hubstaff system.
public protocol UserJobState: JobState {
    // FIXME: https://forums.swift.org/t/using-subtypes-in-the-implementation-of-protocol-properties-and-function-return-values/51430/15
    var userJob: UserJob { get }

    // TODO: Move this to userJob.client: https://github.com/NetsoftHoldings/hubstaff-client/discussions/1267
    var client:  Client? { get }
}

/// A beneficiary party of the work performed in a job. Jobs are generally billed to the client.
public protocol Client: Entity {
    var name:   String { get }
    var avatar: Avatar { get }
    var phone:  String? { get }
}

public enum JobStatus {
    case other(label: String, tint: Tint)
    case scheduled(label: String, tint: Tint)
    case early(label: String, tint: Tint)
    case onTime(label: String, tint: Tint)
    case late(label: String, tint: Tint)
    case missed(label: String, tint: Tint)
    case abandoned(label: String, tint: Tint)
    case mixed(label: String, tint: Tint)
    case completed(label: String, tint: Tint)

    public var badge: (label: String, tint: Tint) {
        switch self {
            case let .other(label, tint),
                 let .scheduled(label, tint),
                 let .early(label, tint),
                 let .onTime(label, tint),
                 let .late(label, tint),
                 let .missed(label, tint),
                 let .abandoned(label, tint),
                 let .mixed(label, tint),
                 let .completed(label, tint):
                return (label: label, tint: tint)
        }
    }
}

public enum StateType {
    /// State description for any task in the system.
    case anyTask(CurrentValue<TaskState, Never>)
    /// State description for a task in the system to which the user has been assigned access.
    case userTask(CurrentValue<UserTaskState, Never>)
    /// State description for any job in the system.
    case anyJob(CurrentValue<JobState, Never>)
    /// State description for a job in the system to which the user has been assigned access.
    case userJob(CurrentValue<UserJobState, Never>)
}

/// A physical location in the world where the job is expected to be performed.
public protocol JobSite {
    var name:    String { get }
    var avatar:  Avatar { get }
    var address: String { get }
    var center:  CLLocationCoordinate2D { get }
    var radius:  CLLocationDistance { get }
}

/// A note that was attached to this job by any of its assigned members while working on the task.
public protocol JobNote {
    var id:          Entity.ID { get }
    var author:      Member { get }
    var moment:      Date { get }
    var text:        String { get }
    var attachments: [JobNoteAttachment] { get }
}

/// A file that was attached to a job note.
public protocol JobNoteAttachment {
    var id:        Entity.ID { get }
    var image:     URLRequest? { get }
    var thumbnail: URLRequest? { get }
}

/// A task attribute is a task-specific attribute association.
///
/// Task attributes are defined by the task's project integration.
public protocol TaskAttribute: Attribute {
    /// The task metatype if it is known. The type is a standard way to interpret the attribute's value for the task.
    var type: TaskAttributeType? { get }
}

/// Attributes describe a certain type of information that can be associated with tasks through fields.
///
/// This enum describes only the set of known attributes.
public enum TaskAttributeType {
    /// A short description of the task, used as the primary means of identification.
    case summary
    /// A long description of the task, used to explain what needs to be done.
    case details
    /// Identifies the moment the task was originally created.
    case created
    /// Identifies the most recent moment when the task was meaningfully modified.
    case updated
    /// Identifies the moment when the task is expected to be completed.
    case due
    /// Identifies the moment when the task was effectively marked as completed.
    case completed
}

/// A break is a relaxation item available to organization members while working on a certain project.
public protocol BreakPolicy: Entity {
    var title:    String { get }
    var duration: TimeInterval { get }
}

/// A break policy that the current user has been assigned access to.
public protocol UserBreak: BreakPolicy {}

/// The state lifecycle that a property can go through which can be performed asynchronously.
public enum ProgressiveState {
    /// The entity does not support this property.
    case unavailable
    /// The property is ready to be performed.
    case available
    /// The property is currently being performed and will soon transition.
    case performing
    /// The property has been performed and is now completed.
    case finished
}

/// Attributes are key-value types used for associating arbitrary data with an entity.
///
/// Attributes have read-only typed values that can be used, interpreted, processed or presented.
public protocol Attribute {
    /// The unique identifier of this specific attribute amidst its siblings.
    var id:    String { get }
    /// The title introducing this field's purpose to the user.
    var label: String { get }
    /// The current value associated with this field.
    var value: AttributeValue { get }
}

/// Fields are used for two-way communication about associated attributes.
///
/// They inform about how users can modify or create field-based entities based on their associated attributes.
public protocol Field {
    /// The entity's attribute that this field will affect.
    var attribute:  Attribute { get }
    /// `true` if this field cannot pass validation without having a value assigned to it.
    var isRequired: Bool { get }
    /// `true` if this field is currently being re-calculated as a result of a change to the form.
    var isUpdating: Bool { get }
    /// `true` if this field's value cannot be modified.
    ///
    /// - Note: This differs from `FieldValue.none` in that none fields are always un-editable while read-only fields may alternate from read-write to read-only, depending upon the form's current state.
    var isReadOnly: Bool { get }
    /// A user hint about the value that can be entered into the field.
    var hint:       String { get }
    /// The current value associated with this field. May be nil if this field is not editable.
    var value:      FieldValue? { get }
    /// If the current value is deemed invalid, describes the issue to the user.
    var fault:      String? { get }
}

/// Forms are used to request changes to an entity's associated attributes.
public protocol FieldForm {
    /// The current set of fields that need to be populated for the form to pass validation and be processed.
    ///
    /// The fields in a form may change when new field data is submitted, to reflect inter-field relationships.
    var fields:     CurrentValue<[Field], Never> { get }
    /// Indicates the form's current state during submission processing.
    ///
    /// - unavailable: The form's field values are incompatible with the attribute's requirements.
    /// - available: The form's field values meet all base requirements for the form to be submitted and validated.
    /// - performing: The form is currently being submitted and validated.
    /// - finished: The form is has been successfully submitted and its related action performed.
    var submission: CurrentValue<ProgressiveState, Never> { get }
    /// If the form's values were deemed invalid during submission, the fault describes information on the issue.
    var fault:      CurrentValue<FormFault?, Never> { get }
    /// Submit the form for processing.
    ///
    /// You can monitor the `submission` for updates on its progress. Submission may also affect `fault` and `fields`.
    func submit()
}

/// A fault that occurred during the submission of a form, rejecting the request.
public protocol FormFault {
    /// A short description on the submission that was attempted but rejected.
    var summary:     String { get }
    /// Details on why the form submission could not be accepted.
    var details:     String { get }
    /// A fatal situation implies the form is no longer relevant to or acceptable by the system.
    var isFatal:     Bool { get }
    /// Information that might help user to eliminate the obstacles towards submission.
    var suggestions: [String] { get }
    /// A page that provides supporting details to help users understand and handle the reported issue.
    var support:     URL? { get }
}

/// Attribute values describe arbitrary data values associated with an entity.
public enum AttributeValue: Hashable {
    /// A text value describes any value represented by a string of characters.
    /// It may also be used for unknown underlying types that have been formatted as text.
    case text(value: String?)
    /// A numeric value describes an amount.
    /// It represents either a natural or real number.
    case number(value: Float?)
    /// An option describes a selectable item.
    /// It represents a single member from a group of available options.
    case option(value: String?)
    /// A day value describes a point on a calendar.
    /// It represents the same day on everyone's calendar, irrespective of their time zone.
    case day(value: Day?)
    /// A time value describes a point in someone's day.
    /// 9AM is 9AM for everyone, irrespective of their time zone (even if those may all be separate moments).
    case time(value: TimeOfDay?)
    /// A moment describes a universal instant in time.
    /// The moment happens at the same time for everyone, even if the clock reads a different time/day in their time zones.
    case moment(value: Date?)
    /// A duration describes an amount of time that can elapse.
    /// It is independent of calendars and time zones.
    case duration(value: TimeInterval?)
}

/// Field values describe editable data values associated with a form.
///
/// The field's type carries type-specific metadata describing the range of alternative values that are deemed valid replacements for the field's current value.
public enum FieldValue {
    /// A text value describes any value represented by a string of characters.
    /// It may also be used for unknown underlying types that have been formatted as text.
    /// - Parameter length: The minimum & maximum length, in characters of the text, that may be specified. Unlimited if nil.
    case text(value: CurrentValueSubject<String?, Never>, singleLine: Bool, length: ClosedRange<Int32>?)
    /// A numeric value describes an amount.
    /// It represents either a natural or real number.
    /// - Parameter range: The minimum & maximum numeric value that may be specified. Unlimited if nil.
    case number(value: CurrentValueSubject<Float?, Never>, range: ClosedRange<Int32>?)
    /// An option describes selectable item(s).
    /// It represents members from a group of available options.
    /// - Parameter amount: The minimum & maximum amount of values that may be selected from the items. Unlimited if nil.
    case option(value: AnySource<FieldValueItem>, amount: ClosedRange<Int32>?)
    /// A day value describes a point on a calendar.
    /// It represents the same day on everyone's calendar, irrespective of their time zone.
    case day(value: CurrentValueSubject<Day?, Never>)
    /// A time value describes a point in someone's day.
    /// 9AM is 9AM for everyone, irrespective of their time zone (even if those may all be separate moments).
    case time(value: CurrentValueSubject<TimeOfDay?, Never>)
    /// A moment describes a universal instant in time.
    /// The moment happens at the same time for everyone, even if the clock reads a different time/day in their time zones.
    case moment(value: CurrentValueSubject<Date?, Never>)
    /// A duration describes an amount of time that can elapse.
    /// It is independent of calendars and time zones.
    case duration(value: CurrentValueSubject<TimeInterval?, Never>)
}

/// A single option eligible for selection from a list of selectable items.
public struct FieldValueItem: Identifiable, Hashable {
    /// The value used for selecting this option.
    public let id:    String
    /// A short user-friendly representation of this option.
    public let label: String

    public init(id: String, label: String) {
        self.id = id
        self.label = label
    }
}

// MARK: - Concrete Types

/// Utility for hooking into a foreign form and changing its values or submit behaviour.
public class ModifiedFieldForm: FieldForm {
    public init(
        _ form: FieldForm,
        fields: @escaping ([Field]) -> [Field] = { $0 },
        submission: @escaping (ProgressiveState) -> ProgressiveState = { $0 },
        fault: @escaping (FormFault?) -> FormFault? = { $0 },
        onSubmit: @escaping (() -> Void) -> Void = { $0() }
    ) {
        self.parent = (form: form, fields: fields, submission: submission, fault: fault, onSubmit: onSubmit)
    }

    public lazy var fields     = CurrentValue(self.parent.form.fields.map(self.parent.fields))
    public lazy var submission = CurrentValue(self.parent.form.submission.map(self.parent.submission))
    public lazy var fault      = CurrentValue(self.parent.form.fault.map(self.parent.fault))

    public func submit() {
        self.parent.onSubmit(self.parent.form.submit)
    }

    // - Private
    private let parent: (
        form: FieldForm,
        fields: ([Field]) -> [Field],
        submission: (ProgressiveState) -> ProgressiveState,
        fault: (FormFault?) -> FormFault?,
        onSubmit: (() -> Void) -> Void
    )
}

/// Convenient way of creating an in-memory form.
public struct SimpleForm: FieldForm {
    @ErasedCurrentSubject<[Field], [Field]>
    public var fields:     CurrentValue<[Field], Never>
    @ErasedCurrentSubject<ProgressiveState, ProgressiveState>
    public var submission: CurrentValue<ProgressiveState, Never>
    @ErasedCurrentSubject<FormFault?, FormFault?>
    public var fault:      CurrentValue<FormFault?, Never>

    public init(
        fields: [Field], submission: ProgressiveState = .available, fault: FormFault? = nil,
        submit: @escaping () -> ProgressiveState = { .finished }
    ) {
        self._fields = .init(fields)
        self._submission = .init(submission)
        self._fault = .init(fault)
        self.onSubmit = submit
    }

    public func submit() {
        self.$submission.send(self.onSubmit())
    }

    // - Private
    private let onSubmit: () -> ProgressiveState
}

/// Convenient way of creating an in-memory form field.
public class SimpleField: Field {
    @ErasedValue<Attribute, Projects.Attribute>
    public var attribute:  Projects.Attribute
    public var isRequired: Bool
    public private(set) var isUpdating = false
    public var isReadOnly: Bool
    public var hint:       String
    public private(set) var value: FieldValue?
    public var fault: String?

    public init(
        id: String? = nil, label: String, isRequired: Bool = false, isReadOnly: Bool = false, hint: String = "", fault: String? = nil,
        value: AttributeValue, singleLine: Bool = true, range: ClosedRange<Int32>? = nil, items: [FieldValueItem] = []
    ) {
        self._attribute = .init(Attribute(id: id ?? label, label: label, value: value))
        self.isRequired = isRequired
        self.isReadOnly = isReadOnly
        self.hint = hint
        self.fault = fault

        switch self.attribute.value {
            case let .text(value: value):
                self.value = .text(value: using(.init(value)) {
                    self.valueMonitor = $0.sink { self.$attribute.value = .text(value: $0) }
                }, singleLine: singleLine, length: range)
            case let .number(value: value):
                self.value = .number(value: using(.init(value)) {
                    self.valueMonitor = $0.sink { self.$attribute.value = .number(value: $0) }
                }, range: range)
            case let .option(value: value):
                self.value = .option(value: using(SimpleDataSource(allValues: items, selection: items.filter { $0.id == value })) {
                    self.valueMonitor = $0.$selected.sink { self.$attribute.value = .option(value: $0?.id) }
                }.eraseToAnySource(), amount: range)
            case let .day(value: value):
                self.value = .day(value: using(.init(value)) {
                    self.valueMonitor = $0.sink { self.$attribute.value = .day(value: $0) }
                })
            case let .time(value: value):
                self.value = .time(value: using(.init(value)) {
                    self.valueMonitor = $0.sink { self.$attribute.value = .time(value: $0) }
                })
            case let .moment(value: value):
                self.value = .moment(value: using(.init(value)) {
                    self.valueMonitor = $0.sink { self.$attribute.value = .moment(value: $0) }
                })
            case let .duration(value: value):
                self.value = .duration(value: using(.init(value)) {
                    self.valueMonitor = $0.sink { self.$attribute.value = .duration(value: $0) }
                })
        }
    }

    public init(
        id: String? = nil, label: String, isRequired: Bool = false, isReadOnly: Bool = false, hint: String = "", fault: String? = nil,
        amount: ClosedRange<Int32>? = nil, option: AnySource<FieldValueItem>
    ) {
        self._attribute = .init(Attribute(id: id ?? label, label: label, value: .option(value: option.selected?.id)))
        self.isRequired = isRequired
        self.isReadOnly = isReadOnly
        self.hint = hint
        self.value = .option(value: option, amount: amount)
        self.fault = fault
        self.valueMonitor = option.objectWillChange.sink { self.$attribute.value = .option(value: option.selected?.id) }
    }

    // - Private
    var valueMonitor: AnyCancellable?

    public struct Attribute: Projects.Attribute {
        public fileprivate(set) var id:    String
        public fileprivate(set) var label: String
        public fileprivate(set) var value: AttributeValue
    }
}
