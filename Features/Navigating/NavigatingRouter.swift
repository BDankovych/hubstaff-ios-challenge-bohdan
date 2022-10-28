//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Combine
import SwiftUI

import Orchestration

/// A navigating router supplies the capability of navigating between many independent routers.
public protocol NavigatingRouter: FeatureRouter {}

// MARK: - Tab

/// A tab router navigates between its children by presenting a UI that allows the user to select the active child through tapping the tab that represents that child.
public class NavigatingTabRouter: NavigatingRouter {
    public required init(children: [FeatureRouter], initial: Int = .zero) {
        self.children = children
        self.initial = initial
    }

    // - Router
    public var featurePresenter: ScreenPresenter { self.presenter }
    public lazy var presenter = NavigatingTabScreenPresenter(router: self)

    // - Internal
    let children: [FeatureRouter]
    let initial:  Int
}

// MARK: - Stack

/// A stack router always presents to last child in the stack and provides a UI the user can use to pop that item off the stack.
public class NavigatingStackRouter: NavigatingRouter {
    public required init(root: FeatureRouter) {
        self.root = root
    }

    // - Router
    public lazy var featurePresenter: ScreenPresenter = NavigatingStackScreenPresenter(router: self)

    // - Internal
    public var root: FeatureRouter
}
