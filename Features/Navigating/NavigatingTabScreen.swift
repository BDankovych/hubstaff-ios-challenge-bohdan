//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Combine
import SwiftUI

import Orchestration

public class NavigatingTabScreenPresenter: ScreenPresenter, ObservableObject {
    public let router: NavigatingTabRouter

    public init(router: NavigatingTabRouter) {
        self.router = router
        self.selection = self.router.initial
    }

    // - View
    public lazy var view = AnyView(NavigatingTabScreen(presenter: self))

    @Published
    public var selection = 0
}

public extension EnvironmentValues {
    /// Indicates whether the view is currently the selected tab in a navigating tab view.
    var isTabSelected: Bool {
        get { self[SelectionKey.self] }
        set { self[SelectionKey.self] = newValue }
    }

    private struct SelectionKey: EnvironmentKey {
        static let defaultValue = false
    }
}

public extension View {
    /// Set the bar title to use in the navigation bar when this view is a child in a navigating tab view.
    func navigationTabTitle(_ title: String) -> some View {
        self.navigationBarTitle(title)
            .preference(key: NavigatingTabScreen.TitlePreference.self, value: title)
    }

    /// Set the bar title to use in the navigation bar when this view is a child in a navigating tab view.
    func navigationTabHidden(_ hidden: Bool) -> some View {
        self.navigationBarHidden(hidden)
            .preference(key: NavigatingTabScreen.HiddenPreference.self, value: hidden)
    }

    /// Set the bar items to use in the navigation bar when this view is a child in a navigating tab view.
    func navigationTabItems<L: View & Equatable, T: View & Equatable>(leading: L, trailing: T) -> some View {
        self.navigationBarItems(leading: leading, trailing: trailing)
            .preference(key: NavigatingTabScreen.ItemsPreference.self, value: NavigatingTabScreen.ItemsPreference.Items(
                leading: AnyEquatableView(leading),
                trailing: AnyEquatableView(trailing)
            ))
    }
}

private struct NavigatingTabScreen: View {
    @ObservedObject
    fileprivate var presenter:     NavigatingTabScreenPresenter
    @State
    private var     tabViewTitle:  String?
    @State
    private var     tabViewHidden: Bool?
    @State
    private var     tabViewItems:  ItemsPreference.Items?
    @State
    private var     tabViewColor:  Color?
    @State
    private var     tabViewStatus: UIStatusBarStyle?

    var body: some View {
        ZStack {
            // First value wins.
            Color.clear
                .navigationBarTitle(self.tabViewTitle ?? "")
                .navigationBarItems(
                    leading: self.tabViewItems?.leading ?? AnyEquatableView(EmptyView()),
                    trailing: self.tabViewItems?.trailing ?? AnyEquatableView(EmptyView())
                )

            TabView(selection: self.$presenter.selection) {
                ForEach(Array(self.presenter.router.children.enumerated()), id: \.0) { c, child in
                    TabItem(
                        router: child,
                        selected: self.presenter.selection == c,
                        tabViewTitle: self.$tabViewTitle,
                        tabViewHidden: self.$tabViewHidden,
                        tabViewItems: self.$tabViewItems,
                        tabViewColor: self.$tabViewColor,
                        tabViewStatus: self.$tabViewStatus
                    )
                }
            }
            // Last value wins.
            .navigationBarTitleColor(self.tabViewColor)
            .navigationBarHidden(self.tabViewHidden ?? false)
            .statusBar(style: self.tabViewStatus)
        }
    }

    private struct TabItem: View {
        let router:   FeatureRouter
        let selected: Bool

        @Binding
        var tabViewTitle:  String?
        @Binding
        var tabViewHidden: Bool?
        @Binding
        var tabViewItems:  ItemsPreference.Items?
        @Binding
        var tabViewColor:  Color?
        @Binding
        var tabViewStatus: UIStatusBarStyle?

        @State
        private var tabItemTitle:  String?
        @State
        private var tabItemHidden: Bool?
        @State
        private var tabItemItems:  ItemsPreference.Items?
        @State
        private var tabItemColor:  Color?
        @State
        private var tabItemStatus: UIStatusBarStyle?
        @State
        private var tabItemVisible = false

        var body: some View {
            self.router.featurePresenter.view
                .environment(\.isTabSelected, self.selected)
                .onPreferenceChange(TitlePreference.self) {
                    self.tabItemTitle = $0
                    self.updateTabView()
                }
                .onPreferenceChange(HiddenPreference.self) {
                    self.tabItemHidden = $0
                    self.updateTabView()
                }
                .onPreferenceChange(ItemsPreference.self) {
                    self.tabItemItems = $0
                    self.updateTabView()
                }
                .onPreferenceChange(NavigatingStackScreen.TitleColorPreference.self) {
                    self.tabItemColor = $0
                    self.updateTabView()
                }
                .onPreferenceChange(StatusBarStyleKey.self) {
                    self.tabItemStatus = $0
                    self.updateTabView()
                }
                .onAppear {
                    self.tabItemVisible = true
                    self.updateTabView()
                }
                .onDisappear {
                    self.tabItemVisible = false
                }
        }

        func updateTabView() {
            guard self.tabItemVisible
            else { return }

            self.tabViewTitle = self.tabItemTitle
            self.tabViewHidden = self.tabItemHidden
            self.tabViewItems = self.tabItemItems
            self.tabViewColor = self.tabItemColor
            self.tabViewStatus = self.tabItemStatus
        }
    }

    fileprivate struct TitlePreference: PreferenceKey {
        public static func reduce(value: inout String?, nextValue: () -> String?) {
            nextValue().flatMap { value = $0 }
        }
    }

    fileprivate struct HiddenPreference: PreferenceKey {
        public static func reduce(value: inout Bool?, nextValue: () -> Bool?) {
            nextValue().flatMap { value = $0 }
        }
    }

    fileprivate struct ItemsPreference: PreferenceKey {
        public static func reduce(value: inout Items?, nextValue: () -> Items?) {
            nextValue().flatMap { value = $0 }
        }

        fileprivate struct Items: Equatable {
            let leading:  AnyEquatableView
            let trailing: AnyEquatableView
        }
    }
}

#if DEBUG
struct NavigatingTabScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigatingTabRouter(children: [
            TrackerRouter(),
            MoreRouter(),
        ]).featurePresenter.view
            .previewDisplayName("Tab")
            .style(.hubstaff)
    }
}
#endif
