//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Combine
import Foundation

import Orchestration
import Projects

/// The tracker module enables users to track work committed toward projects they participate in.
public protocol TrackerInteractor: Interactor {
    /// The tracker state fully describes the current situation.
    var state: CurrentValue<TrackerState, Never> { get }

    /// Obtain a target to use if the user wants to focus the given project in the tracker.
    ///
    /// - Returns: `nil` if the given project is not available for tracking to the current user.
    func target(for project: UserProject) -> TrackerTarget?
    /// Obtain a target to use if the user wants to focus the given task in the tracker.
    ///
    /// - Returns: `nil` if the given task is not available for tracking to the current user.
    func target(for task: UserTask) -> TrackerTarget?
    /// Obtain a target to use if the user wants to focus the given break in the tracker.
    ///
    /// - Returns: `nil` if the given break is not available for tracking to the current user.
    func target(for break: UserBreak) -> TrackerTarget?

    /// Switch the tracker's current focus target to the given target.
    ///
    /// If the new target is identical to the current focus, this operation has no effect.
    /// If the old target was being tracked, the tracker will be stopped.
    func focus(on target: TrackerTarget?)
    /// Begin tracking work against the given target, stop tracking of any previous target.
    ///
    /// If the given target is not `nil`, it becomes the tracker's current focus target.
    /// If a different target was being tracked, its tracker is stopped.
    func track(on target: TrackerTarget?)

    /// Emit the tracker's status regarding a specific tracker target to keep up-to-date on work tracked against it over time.
    func timer(for target: TrackerTarget) -> CurrentValue<TrackerTimer, Never>

    /// Record a new time note against the tracker's currently focussed task.
    @discardableResult
    func addTimeNote(withText: String) -> Bool

    /// Record a new task note against the tracker's currently focussed task.
    @discardableResult
    func addTaskNote(withText: String, attachments: [URL]) -> Bool

    /// Request that the recency of the tracker data is verified and updated if relevant new information is available.
    func refresh()
}

public protocol TrackerState {
    /// The focus defines the target that is the subject of all of the tracker's events.
    var focus:               TrackerTarget? { get }
    /// The user's global timer summarizes the work that's currently tracking.
    ///
    /// If focussed on work, it's the total time worked against the focussed target's project today.
    /// If focussed on a break, it's the time remaining on your break.
    var timer:               TrackerTimer { get }
    /// Information on all break policies the user's membership has given him access to, and their current state in the tracker.
    ///
    /// If break policies are not enabled for the current target, emits `nil`.
    var breaks:              [TrackerBreak]? { get }
    /// Information on the limitations currently in effect for the user.
    ///
    /// If work limits are not enabled for the current target, emits `nil`.
    var limits:              TrackerLimits? { get }
    /// `true` when the focus target supports adding time notes
    var isTimeNoteSupported: Bool { get }
    /// `true` when the focus target supports adding task notes
    var isTaskNoteSupported: Bool { get }
}

/// An entity that can be used as a target for tracking work to.
public protocol Trackable: Entity {
    /// The reason the user is inhibited from tracking time to this trackable target, if any.
    var blockage: TrackerBlock? { get }
}

/// A project that the user can focus on in the tracker.
public protocol TrackerProject: UserProject, Trackable {}

/// A task that the user can focus on in the tracker.
public protocol TrackerTask: UserTask, Trackable {}

/// A break policy that the user can focus on in the tracker.
public protocol TrackerBreak: UserBreak, Trackable {}

/// A tracker target is a context loaded into the tracker against which work can be tracked.
public enum TrackerTarget {
    case project(_ project: TrackerProject)
    case task(_ task: TrackerTask)
    case `break`(_ break: TrackerBreak)
}

/// Time in the tracker describes a relative amount of seconds currently being tracked toward a target.
public protocol TrackerTimer {
    /// The target this timer describes the tracker state for.
    ///
    /// `nil` if this timer describes a target aggregate rather than a direct target.
    var target:     TrackerTarget? { get }
    /// The relative amount of seconds currently on the clock for this type of time.
    var seconds:    TimeInterval { get }

    /// `true` if the tracker is currently logging work being performed against the target.
    var isRunning:  Bool { get }
    /// `true` if the timer for this target has exceeded the allotted time available to the user.
    var isExceeded: Bool { get }
    /// Whether anything is inhibiting this timer from being able to start running, if so, what it might be.
    var blockage:   TrackerBlock? { get }
}

/// Describes conditions that prevent the tracker's timer from running.
public enum TrackerBlock: Hashable {
    /// The tracker is not focussed on a trackable target.
    case missingTarget(details: String)
    /// The target cannot be tracked directly: tracking is only supported on a sub-task of it.
    case requiresTask(details: String)
    /// Tracking to this target is not permitted from this type of device.
    case disallowedPlatform(details: String)
    /// The tracker cannot track any target due to lack of available hours.
    case limitReached(details: String)
    /// The tracker is not able to start for this target due to an unspecified issue. Check the details for more.
    case undefined(details: String)
}

public protocol TrackerLimits {
    var summary: String { get }
    var details: String? { get }
}

// MARK: - Boilerplate

extension TrackerTarget: Trackable {
    private var subject: Trackable {
        switch self {
            case let .project(project):
                return project
            case let .task(task):
                return task
            case let .break(`break`):
                return `break`
        }
    }

    public var blockage: TrackerBlock? {
        self.subject.blockage
    }
}

extension TrackerTarget: Entity, Identifiable {
    public var id: ID {
        self.subject.id
    }

    public var state: AnyHashable {
        self.subject.state
    }
}

extension TrackerTarget: Hashable {
    public static func == (lhs: TrackerTarget, rhs: TrackerTarget) -> Bool {
        lhs.state == rhs.state
    }

    public func hash(into hasher: inout Hasher) {
        self.state.hash(into: &hasher)
    }
}

// FIXME: https://github.com/apple/swift-evolution/blob/main/proposals/0309-unlock-existential-types-for-all-protocols.md
public func == (lhs: TrackerTimer, rhs: TrackerTimer) -> Bool {
    lhs.seconds == rhs.seconds && lhs.isRunning == rhs.isRunning && lhs.isExceeded == rhs.isExceeded && lhs.blockage == rhs.blockage
}

public func != (lhs: TrackerTimer, rhs: TrackerTimer) -> Bool {
    !(lhs == rhs)
}
