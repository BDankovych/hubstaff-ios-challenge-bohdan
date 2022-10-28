//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Combine
import SwiftUI

import Orchestration

public class NavigatingStackScreenPresenter: ObservableObject, ScreenPresenter {
    public let router: NavigatingStackRouter

    public init(router: NavigatingStackRouter) {
        self.router = router

        self.root = self.router.root.featurePresenter
    }

    // - View
    public lazy var view = AnyView(NavigatingStackScreen(presenter: self))

    @Published
    fileprivate var root: ScreenPresenter
}

public extension View {
    /// Set the navigation bar title to use when this view is in a navigating tab view.
    @ViewBuilder
    func navigationBarTitleColor(_ color: Color?) -> some View {
        self.preference(key: NavigatingStackScreen.TitleColorPreference.self, value: color)
    }
}

public extension EnvironmentValues {
    /// Indicates whether the view is currently the selected tab in a navigating tab view.
    var presentationRoot: Bool {
        get { self[PresentationRoot.self] }
        set { self[PresentationRoot.self] = newValue }
    }

    private struct PresentationRoot: EnvironmentKey {
        static let defaultValue = false
    }
}

struct NavigatingStackScreen: View {
    @ObservedObject
    fileprivate var presenter: NavigatingStackScreenPresenter

    @State
    private var titleColor: Color?

    var body: some View {
        NavigationView {
            self.presenter.root.view
                .environment(\.presentationRoot, true)
                .navigationBarTitle("", displayMode: .inline)
        }
        .navigationViewStyle(.stack)
        .background(NavigationBarConfigurationView(titleColor: self.titleColor))
        .onPreferenceChange(TitleColorPreference.self) {
            self.titleColor = $0
        }
    }

    struct TitleColorPreference: PreferenceKey {
        public static func reduce(value: inout Color?, nextValue: () -> Color?) {
            nextValue().flatMap { value = $0 }
        }
    }

    private struct NavigationBarConfigurationView: UIViewControllerRepresentable {
        var titleColor: Color?

        func makeUIViewController(context: Context) -> ViewController {
            ViewController()
        }

        func updateUIViewController(_ viewController: ViewController, context: Context) {
            viewController.configuration = self
        }

        fileprivate class ViewController: UIViewController {
            var configuration: NavigationBarConfigurationView? {
                didSet { self.update() }
            }

            override func viewWillLayoutSubviews() {
                super.viewWillLayoutSubviews()
                self.update()
            }

            private func update() {
                guard let host = self.view.superview, let siblings = host.superview?.subviews,
                      let siblingIndex = siblings.firstIndex(of: host).flatMap({ siblings.index(after: $0) }),
                      siblingIndex < siblings.endIndex,
                      let navigationHost = siblings[siblingIndex].subviews.first,
                      let navigationBar = (navigationHost.next as? UINavigationController)?.navigationBar
                else { return }

                let titleColor = (self.configuration?.titleColor?.cgColor).flatMap(UIColor.init(cgColor:)) ??
                    UINavigationBar.appearance().standardAppearance.titleTextAttributes[.foregroundColor]
                navigationBar.standardAppearance.titleTextAttributes[.foregroundColor] = titleColor
                navigationBar.compactAppearance?.titleTextAttributes[.foregroundColor] = titleColor
                navigationBar.scrollEdgeAppearance?.titleTextAttributes[.foregroundColor] = titleColor
                navigationBar.compactScrollEdgeAppearance?.titleTextAttributes[.foregroundColor] = titleColor
            }
        }
    }
}

#if DEBUG
struct NavigatingStackScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigatingStackRouter(root: MoreRouter()).featurePresenter.view
            .previewDisplayName("Stack")
            .style(.hubstaff)
    }
}
#endif
