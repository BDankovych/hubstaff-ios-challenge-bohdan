//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Foundation
import Orchestration
import SwiftUI
import UIKit

public extension View {
    func navigationLink<D: View>(id: AnyHashable = 0, @ViewBuilder destination: @escaping () -> D) -> some View {
        self.overlay(
            UINavigationLink { Lazy(id: id, content: destination) }
                .frame(minWidth: .hsControl, minHeight: .hsControl)
        )
    }
}

private struct UINavigationLink<Destination: View>: UIViewControllerRepresentable {
    @ViewBuilder
    var destination: Destination

    func makeUIViewController(context: Context) -> ViewController {
        ViewController(nibName: nil, bundle: nil)
    }

    func updateUIViewController(_ viewController: ViewController, context: Context) {
        viewController.configuration = self
    }

    class ViewController: UIViewController {
        var configuration: UINavigationLink?

        override func loadView() {
            self.view = using(UIButton()) {
                $0.addTarget(self, action: #selector(actionTriggered), for: .primaryActionTriggered)
            }
        }

        @objc
        private func actionTriggered() {
            if let navigationController = self.findNavigationController(), let configuration = self.configuration {
                let destination = UIHostingController(rootView: configuration.destination.environment(\.presentationRoot, false))
                navigationController.pushViewController(destination, animated: true)
            }
        }
    }
}
