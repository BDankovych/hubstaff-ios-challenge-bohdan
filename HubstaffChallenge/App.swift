//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import SwiftUI

import Orchestration

@main
struct HubstaffChallenge: App {
    @State
    private var presenter: ScreenPresenter = HubstaffRouter().appPresenter

    var body: some Scene {
        WindowGroup {
            self.presenter.view
        }
    }
}
