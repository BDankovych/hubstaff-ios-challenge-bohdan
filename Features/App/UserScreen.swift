//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

import Orchestration
import Projects
import Session

class UserScreenPresenter: ObservableObject, ScreenPresenter {
    init(router: UserRouter) {
        self.router = router
    }

    // - View
    lazy var view = AnyView(UserScreen(presenter: self))

    fileprivate lazy var tabsPresenter = NavigatingTabRouter(children: [
        // DashboardRouter(),
        // TimesheetsRouter(),
        TrackerRouter(),
        // ReportsRouter(),
        MoreRouter(),
    ], initial: 0).presenter

    // - Private
    private let     router:          UserRouter
    private var     subscriptions = [AnyCancellable]()
}

struct UserScreen: View {
    @StateObject
    var presenter: UserScreenPresenter

    var body: some View {
        self.presenter.tabsPresenter.view
    }
}

#if DEBUG
struct UserScreenPresenter_Previews: PreviewProvider, View {
    static var previews = Self()

    var body: some View {
        NavigationView {
            UserRouter().featurePresenter.view
                .navigationBarTitleDisplayMode(.inline)
        }
        .previewDisplayName("User")
        .style(.hubstaff)
    }
}
#endif
