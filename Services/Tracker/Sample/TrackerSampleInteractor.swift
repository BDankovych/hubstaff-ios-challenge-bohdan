//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Combine
import Foundation

import Orchestration
import Projects
import Session
import Tracker

import ProjectsSample

public class TrackerSampleInteractor: TrackerInteractor {
    @ErasedCurrentSubject(SampleTrackerContext())
    public var state: CurrentValue<TrackerState, Never>

    public init(focus: Bool = false, timeNotes: Bool = false, taskNotes: Bool = false, blockage: TrackerBlock? = .none) {
        // FIXME: Currently this code produces recursion, `removeDuplicates` swallows the error.
        self.contextMonitor = self.state
            .map(\.focus).removeDuplicates()
            .sink { old, new in
                // When focus changes, automatically stop the timer.
                old.flatMap { self.targetTimer[$0] }?.cancel()

                // Publish the breaks applicable to the new target.
                self.breakMonitor = (self.sessionInteractor.stage.value?.organization).flatMap {
                    self.projectsInteractor.global.breaks(for: $0)
                }.or(Just([]))
                    .map { $0.map(SampleWorkBreak.init) }
                    .sink { self.$state.value.breaks = $0 }
            }

        self.$state.value.isTaskNoteSupported = taskNotes
        self.$state.value.isTimeNoteSupported = timeNotes
        self.$state.value.$timer.blockage = blockage

        if focus {
            if case let .ready(_, organization) = self.sessionInteractor.stage.value,
               let firstTask = self.projectsInteractor.global.projects(for: organization).value.compactMap({
                   self.projectsInteractor.global.tasks(for: $0).value.first
               }).first, let target = self.target(for: firstTask) {
                self.$state.value.focus = target
            }
        }
    }

    public func target(for project: UserProject) -> TrackerTarget? {
        (project as? SampleProject).flatMap(TrackerTarget.project)
    }

    public func target(for task: UserTask) -> TrackerTarget? {
        (task as? SampleTask).flatMap(TrackerTarget.task)
    }

    public func target(for break: UserBreak) -> TrackerTarget? {
        (`break` as? SampleWorkBreak).flatMap { TrackerTarget.break($0) }
    }

    public func focus(on target: TrackerTarget?) {
        guard !(self.state.value.focus ~= target)
        else { return }

        self.$state.value.focus = target
    }

    public func track(on target: TrackerTarget?) {
        guard let target = target
        else {
            if let focus = self.state.value.focus {
                self.targetTimer[focus]?.cancel()
            }

            return
        }

        self.focus(on: target)

        // The target's timer starts running when time begins ticking, steps each second and stops when it ends.
        self.targetTimer[target] = Timer
            .publish(every: 1, on: .main, in: .default).autoconnect()
            .handleEvents(receiveSubscription: { _ in
                self.time(for: target).value.start()
                self.$state.value.$timer = self.projectTime()
            }, receiveCancel: {
                self.time(for: target).value.stop()
                self.$state.value.$timer = self.projectTime()
            })
            .sink(receiveValue: { _ in
                self.time(for: target).value.step()
                self.$state.value.$limits.tracked += 1
                self.$state.value.$timer = self.projectTime()
            })
    }

    public func timer(for target: TrackerTarget) -> CurrentValue<TrackerTimer, Never> {
        CurrentValue(self.time(for: target).map { $0 as TrackerTimer })
    }

    public func addTimeNote(withText content: String) -> Bool {
        // TODO: Implement adding task note into Timesheet
        guard !content.isEmpty
        else {
            return false
        }

        return true
    }

    public func addTaskNote(withText: String, attachments: [URL]) -> Bool {
        // TODO: Implement adding task note into Timesheet
        guard !withText.isEmpty || !attachments.isEmpty
        else {
            return false
        }

        return true
    }

    public func refresh() {}

    // MARK: - Private

    private struct SampleTrackerContext: TrackerState {
        public var focus: TrackerTarget?

        @ErasedValue(SampleTrackerTimer())
        public var timer:  TrackerTimer
        public var breaks: [TrackerBreak]?
        @ErasedValue(SampleTrackerLimits(tracked: 45 * 3600 - 5, limit: 45 * 3600))
        public var limits: TrackerLimits?
        public var isTimeNoteSupported = false
        public var isTaskNoteSupported = false
    }

    private lazy var sessionInteractor:  SessionInteractor  = Registry.shared.resolve()
    private lazy var projectsInteractor: ProjectsInteractor = Registry.shared.resolve()

    private var targetTime  = [TrackerTarget: CurrentValueSubject<SampleTrackerTimer, Never>]()
    private var targetTimer = [TrackerTarget: Cancellable]()
    private var restoreTarget:  TrackerTarget?
    private var contextMonitor: Cancellable?, breakMonitor: Cancellable?

    private func time(for target: TrackerTarget) -> CurrentValueSubject<SampleTrackerTimer, Never> {
        if let time = self.targetTime[target] {
            return time
        }

        // Target is not yet known, initialize its timer.
        let time: CurrentValueSubject<SampleTrackerTimer, Never>
        switch target {
            case .project:
                time = CurrentValueSubject(SampleTrackerTimer(target: target))
            case .task:
                time = CurrentValueSubject(SampleTrackerTimer(target: target))
            case .break:
                fatalError("TODO: Start tracking time to a break.")
        }
        self.targetTime[target] = time
        return time
    }

    private func projectTime() -> SampleTrackerTimer {
        guard let focus = self.state.value.focus
        else { return SampleTrackerTimer() }
        var focusTime = self.time(for: focus).value
        if !focusTime.isWork {
            return focusTime
        }

        if self.$state.value.$limits.tracked >= self.$state.value.$limits.limit {
            focusTime.isExceeded = true
        }

        return self.targetTime.values.map(\.value).filter { !($0.target ~= focus) && $0.project ~= focusTime.project }
            .reduce(focusTime) {
                SampleTrackerTimer(
                    seconds: $0.seconds + $1.secondsWorked,
                    isRunning: $0.isRunning || $1.isRunning,
                    isExceeded: $0.isExceeded || $1.isExceeded,
                    blockage: $0.blockage ?? $1.blockage,
                    isWork: true
                )
            }
    }
}

extension SampleProject: TrackerProject {
    public var blockage: TrackerBlock? { nil }
}

extension SampleTask: TrackerTask {
    public var blockage: TrackerBlock? { nil }
}

private struct SampleWorkBreak: TrackerBreak {
    fileprivate let breakPolicy: BreakPolicy

    var title: String {
        self.breakPolicy.title
    }

    public var blockage: TrackerBlock? {
        nil
    }

    var duration: TimeInterval {
        self.breakPolicy.duration
    }
}

private struct SampleTrackerLimits: TrackerLimits {
    var tracked: TimeInterval = 0
    var limit: TimeInterval
    var summary: String { "Limit: \(Int(self.tracked / 3600)) / \(Int(self.limit / 3600)) hrs" }
    var details: String? { self.tracked < self.limit ? nil : "You have exceeded your weekly limit." }
}

extension SampleWorkBreak: Identifiable, Hashable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.breakPolicy.state == rhs.breakPolicy.state &&
            lhs.blockage == rhs.blockage
    }

    var id: ID {
        self.breakPolicy.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.breakPolicy.state)
        hasher.combine(self.blockage)
    }
}

public struct SampleTrackerTimer: TrackerTimer {
    public var target:   TrackerTarget?
    public var seconds:  TimeInterval = 0
    public var isRunning              = false
    public var isExceeded             = false
    public var blockage: TrackerBlock?
    public var isWork                 = true

    fileprivate var secondsWorked: TimeInterval {
        self.isWork ? max(0, self.seconds) : 0
    }

    fileprivate var project: UserProject? {
        switch self.target {
            case let .project(project):
                return project
            case let .task(task):
                return task.project
            case .break, .none:
                return nil
        }
    }

    mutating func start() {
        self.isRunning = true
    }

    mutating func stop() {
        self.isRunning = false

        if !self.isWork {
            self.seconds = 0
        }
    }

    mutating func step() {
        self.isRunning = true

//        if self.isWork {
//            self.seconds += 1
//        }
//        else {
//            self.seconds -= 1
//        }
        
        self.seconds += self.isWork ? 1 : -1

        self.isExceeded = self.seconds < 0
    }
}
