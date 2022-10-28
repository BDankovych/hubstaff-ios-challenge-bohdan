//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Combine
import SwiftUI

import Orchestration
import Projects
import Session
import Tracker

/// The tracker feature allows the user to track details about the work he is performing.
public protocol TrackerRouterContract: FeatureRouter {}

public class TrackerRouter: TrackerRouterContract {
    // - Router
    public lazy var featurePresenter: ScreenPresenter = self.timer().featurePresenter

    private func timer() -> FeatureRouter {
        TimerRouter()
    }
}

/// The timer feature lets the user monitor the time that's getting tracked while he's working.
public class TimerRouter: FeatureRouter {
    // - Router
    public lazy var featurePresenter: ScreenPresenter = TimerScreenPresenter(router: self)

    // - Internal
    func projects() -> FeatureRouter {
        SimpleFeatureRouter()
    }

    func timeNote() -> FeatureRouter {
        SimpleFeatureRouter()
    }

    func taskNote() -> FeatureRouter {
        SimpleFeatureRouter()
    }
}
