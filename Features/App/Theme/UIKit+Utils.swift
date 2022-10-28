//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

/// The purpose of this file is to extend features introduced by the UIKit Framework.
import Orchestration
import UIKit

extension UIView {
    /// UIView equivalent of SwiftUI's allowsHitTesting, to disable hit testing for particular views.
    public var allowsHitTesting: Bool {
        get {
            self.get(forAssociation: \Self.allowsHitTesting, defaultSet: true)
        }
        set {
            self.set(forAssociation: \Self.allowsHitTesting, value: newValue)
            Self.allowsHitTestingSwizzle
        }
    }

    // - Private
    private static let allowsHitTestingSwizzle: Void = method_exchangeImplementations(
        class_getInstanceMethod(UIView.self, #selector(UIView.hitTest))!,
        class_getInstanceMethod(UIView.self, #selector(UIView._hitTest))!
    )

    @objc
    private func _hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = self._hitTest(point, with: event)
        return self.allowsHitTesting || hitView != self ? hitView : nil
    }
}

extension UIViewController {
    /// Search the view hierarchy for the navigation controller that controls this controller's view presentation.
    ///
    /// Especially useful in cases where the view controller is not properly installed in the view controller hierarchy or the view
    /// is a subview of a navigation component such as the navigation bar.
    public func findNavigationController() -> UINavigationController? {
        if let navigationController = self as? UINavigationController ?? self.navigationController {
            return navigationController
        }

        return Self.findNavigationController(for: self.view.superview)
    }

    // - Private
    private static func findNavigationController(for host: UIResponder?) -> UINavigationController? {
        guard let host = host
        else { return nil }

        if let navigationController = host as? UINavigationController {
            return navigationController
        }
        if let navigationController = (host as? UIViewController)?.navigationController {
            return navigationController
        }
        if let navigationController = (host as? UINavigationBar)?.delegate as? UINavigationController {
            return navigationController
        }

        return self.findNavigationController(for: host.next)
    }
}
