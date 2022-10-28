//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import SwiftUI

import Orchestration
import Projects
import Session

public class MoreRouter: FeatureRouter {
    // - Router
    public lazy var featurePresenter: ScreenPresenter = MoreScreenPresenter(router: self)

    // - Internal
    func organizations<V: View>(with options: AnyDataSource<Organization, String>.Associated<V>) -> FeatureRouter {
        SimpleFeatureRouter()
    }

    func screenshots() -> FeatureRouter {
        SimpleFeatureRouter()
    }

    func schedules() -> FeatureRouter {
        SimpleFeatureRouter()
    }

    func permissions() -> FeatureRouter {
        SimpleFeatureRouter()
    }

    func about() -> FeatureRouter {
        SimpleFeatureRouter()
    }

    func issue() -> FeatureRouter {
        SimpleFeatureRouter()
    }

    func map() -> FeatureRouter {
        SimpleFeatureRouter()
    }

    func account() -> FeatureRouter {
        SimpleFeatureRouter()
    }
}
