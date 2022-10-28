//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Combine
import SwiftUI

import Orchestration
import Tracker

class TimerScreenPresenter: ModelPresenter<TimerScreen.Model>, ScreenPresenter {
    public init(router: TimerRouter) {
        self.router = router
        super.init()

        // Monitor the target currently focussed in the tracker and the target's timer.
        self.trackerInteractor.state
            .debounce(for: .zero, scheduler: RunLoop.main)
            .sink(receiveValue: self.updateModel(state:))
            .store(in: &self.subscriptions)
    }

    // - View
    public lazy var view = AnyView(TimerScreen(presenter: self, model: self.modelBinding))

    fileprivate lazy var projectsPresenter = self.router.projects().featurePresenter
    fileprivate lazy var timeNotePresenter = self.router.timeNote().featurePresenter
    fileprivate lazy var taskNotePresenter = self.router.taskNote().featurePresenter

    fileprivate func toggleTracking() {
        // TODO: Tell self.trackerInteractor to start tracking time.
    }

    fileprivate func start(_ model: TimerScreen.Model.BreakItem) {
        // TODO: Tell self.trackerInteractor to start taking a break.
    }

    // - Private
    private let router: TimerRouter
    private var subscriptions = [AnyCancellable]()

    private lazy var trackerInteractor: TrackerInteractor = Registry.shared.resolve()

    private func updateModel(state: TrackerState) {
        // TODO: Populate self.model
    }
}

struct TimerScreen: ModelView {
    struct Model: ViewModel {
        // TODO: Add model data that you want to use in the view.
        var availableBreaks: [BreakItem]?

        struct BreakItem: Identifiable, Hashable {
            @AnyEntity
            var `break`: TrackerBreak!

            var id:    Entity.ID
            var title: String
        }
    }

    @StateOptionalObject
    var presenter: TimerScreenPresenter?
    @Binding
    var model:     Model

    @Environment(\.isTabSelected)
    private var isTabSelected: Bool

    var body: some View {
        VStack(spacing: .zero) {
            // TODO: Add view layout to present the timer.
        }

        // Navigation
        .tabItem {
            Image(named: self.isTabSelected ? "play.circle.fill" : "play.circle.small")
            Text("Timer")
        }
    }
}

#if DEBUG
struct TimerScreen_Previews: PreviewProvider, View {
    static var previews = Self()

    @State
    private var model = MockupModels.timerStopped

    var body: some View {
        TabView {
            TimerScreen(model: self.$model)
        }
        .previewDisplayName("Timer")
        .style(.hubstaff)
    }

    enum MockupModels {
        static let timerStopped  = TimerScreen.Model(
            availableBreaks: [
                TimerScreen.Model.BreakItem(id: 0, title: "Lunch"),
                TimerScreen.Model.BreakItem(id: 1, title: "Personal"),
            ]
        )
        static let timerRunning  = TimerScreen.Model(
            availableBreaks: [
                TimerScreen.Model.BreakItem(id: 0, title: "Lunch"),
                TimerScreen.Model.BreakItem(id: 1, title: "Personal"),
            ]
        )
        static let timerBreak    = TimerScreen.Model(
            availableBreaks: [
                TimerScreen.Model.BreakItem(id: 0, title: "Lunch"),
                TimerScreen.Model.BreakItem(id: 1, title: "Personal"),
            ]
        )
        static let timerExceeded = TimerScreen.Model(
            availableBreaks: []
        )
    }
}
#endif
