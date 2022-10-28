//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Combine
import SwiftUI

import Orchestration
import Projects
import Session

class MoreScreenPresenter: ModelPresenter<MoreScreen.Model>, ScreenPresenter {
    public init(router: MoreRouter) {
        self.router = router
        super.init()

        combineLatest(
            self.sessionInteractor.stage.removeNil(),
            self.projectsInteractor.global.organizations()
        )
        .debounce(for: .zero, scheduler: RunLoop.main)
        .sink(receiveValue: self.updateModel(data:))
        .store(in: &self.subscriptions)

        self.organizations.$selected.removeNil().removeDuplicates(by: ~=)
            .sink { self.sessionInteractor.stage.value?.session?.focus(organization: $0) }
            .store(in: &self.subscriptions)
    }

    // - View
    public lazy var view = AnyView(MoreScreen(presenter: self, model: self.modelBinding))

    fileprivate func permissionsPresenter() -> ScreenPresenter {
        self.router.permissions().featurePresenter
    }

    fileprivate func screenshotsPresenter() -> ScreenPresenter {
        self.router.screenshots().featurePresenter
    }

    fileprivate func schedulesPresenter() -> ScreenPresenter {
        self.router.schedules().featurePresenter
    }

    fileprivate func aboutPresenter() -> ScreenPresenter {
        self.router.about().featurePresenter
    }

    fileprivate func issuePresenter() -> ScreenPresenter {
        self.router.issue().featurePresenter
    }

    fileprivate func mapPresenter() -> ScreenPresenter {
        self.router.map().featurePresenter
    }

    fileprivate func organizationPickerPresenter() -> ScreenPresenter {
        self.router.organizations(with: self.organizations.eraseToAnyDataSource()).featurePresenter
    }

    fileprivate func accountPresenter() -> ScreenPresenter {
        self.router.account().featurePresenter
    }

    // - Private
    private let router: MoreRouter
    private var subscriptions = [AnyCancellable]()
    private let organizations = SimpleDataSource<Organization, String>.Associated<OrganizationOptionView>(
        filter: { organization, query in (query?.nonEmpty).flatMap(organization.title.localizedCaseInsensitiveContains) ?? true },
        association: { OrganizationOptionView(organization: $0) }
    )

    private lazy var sessionInteractor:  SessionInteractor  = Registry.shared.resolve()
    private lazy var projectsInteractor: ProjectsInteractor = Registry.shared.resolve()

    private func updateModel(data: (sessionStage: SessionStage, organizations: [Organization]?)) {
        self.organizations.allValues = data.organizations ?? []

        self.model = MoreScreen.Model(
            organization: {
                switch data.sessionStage {
                    case let .ready(_, organization):
                        self.organizations.selected = organization
                        return MoreScreen.Model.Item(avatar: organization.avatar, title: organization.title)
                    default:
                        self.organizations.selected = nil
                        return nil
                }
            }(),
            primaryButtons: [
                MoreScreen.Model.Action(icon: "calendar", title: "Schedules") { self.schedulesPresenter().view },
                MoreScreen.Model.Action(icon: "map", title: "Map") { self.mapPresenter().view },
                MoreScreen.Model.Action(icon: "landscape.artframe", title: "Screenshots") { self.screenshotsPresenter().view },
            ],
            secondaryButtons: [
                MoreScreen.Model.Action(icon: "questionmark.circle", title: "Help") {
                    AnyView(
                        WebPage(url: URL(string: "https://support.hubstaff.com/category/hubstaff/mobile-apps/")!)
                            .edgesIgnoringSafeArea(.all)
                            .navigationBarHidden(true)
                    )
                },
                MoreScreen.Model.Action(icon: "ladybug", title: "Report an issue") { self.issuePresenter().view },
                MoreScreen.Model.Action(icon: "waveform.path.ecg", title: "What Hubstaff tracks") { self.permissionsPresenter().view },
            ]
        )
    }
}

struct MoreScreen: ModelView {
    struct Model: ViewModel {
        var organization:     Item?
        var primaryButtons:   [Action] = []
        var secondaryButtons: [Action] = []

        struct Item {
            let avatar: Avatar
            let title:  String
        }

        struct Action {
            let icon:        String
            let title:       String
            let destination: () -> AnyView
        }
    }

    @StateOptionalObject
    var presenter: MoreScreenPresenter?
    @Binding
    var model:     Model

    @Environment(\.isTabSelected)
    private var isTabSelected: Bool

    var body: some View {
        VStack(spacing: .zero) {
            // Organization info & Selector
            if let organization = self.model.organization {
                VStack(spacing: .hsRelated) {
                    AvatarBadge(model: organization.avatar, font: .hsDisplay)
                        .frame(width: .hsGroup * 4, height: .hsGroup * 4)
                        .background(organization.avatar.tint.color())
                        .cornerRadius(.hsRelated)

                    HStack(alignment: .center, spacing: .hsInternal) {
                        Text(organization.title)
                            .font(.hsTitle)
                        Image(named: "arrowtriangle.down.fill")
                            .foregroundColor(.hsSecondary)
                    }
                }
                .navigationLink {
                    self.presenter?.organizationPickerPresenter().view
                }
                .padding(.hsBreak + .hsGroup)
            }

            // Primary buttons
            LazyVGrid(columns: Array(repeating: .init(spacing: .hsInternal), count: 2), spacing: .hsInternal) {
                ForEach(Array(self.model.primaryButtons.enumerated()), id: \.0) { _, button in
                    GroupBox(icon: button.icon, title: button.title)
                        .navigationLink(destination: button.destination)
                }
            }

            Spacer().frame(height: .hsBreak)

            // Secondary buttons
            VStack(spacing: .hsRelated) {
                ForEach(Array(self.model.secondaryButtons.enumerated()), id: \.0) { _, button in
                    HStack(spacing: .hsRelated) {
                        Image(named: button.icon)
                            .foregroundColor(.hsPrimary)

                        Text(button.title)
                            .font(.hsControl)
                            .foregroundColor(.hsPrimary)
                    }
                    .navigationLink(destination: button.destination)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Spacer()
        }
        .padding(.horizontal, .hsGroup)
        .padding(.bottom, .hsRelated)

        // Navigation
        .navigationTabTitle("More")
        .tabItem {
            Image(named: self.isTabSelected ? "ellipsis.fill" : "ellipsis")
            Text("More").accessibility(identifier: "more_tab_button")
        }
    }
}

// View for organization presentation in the organization chooser list
struct OrganizationOptionView: View {
    let organization: Organization

    @Environment(\.isOptionSelected)
    private var isOptionSelected: Bool

    var body: some View {
        HStack {
            AvatarBadge(model: self.organization.avatar)

            Text(self.organization.title)
                .font(self.isOptionSelected ? .hsControl.weight(.semibold) : .hsControl)
        }
    }
}

#if DEBUG
struct MoreScreen_Previews: PreviewProvider, View {
    static var previews = Self()

    @State
    private var model = MockupModels.base

    var body: some View {
        NavigationView {
            TabView {
                MoreScreen(model: self.$model)
                    .navigationBarTitle("", displayMode: .inline)
            }
        }
        .previewDisplayName("More")
        .style(.hubstaff)
    }

    fileprivate enum MockupModels {
        static let base = MoreScreen.Model(
            organization: MoreScreen.Model.Item(
                avatar: SimpleAvatar(image: nil, tint: UIColor.hsGreen, moniker: "G"),
                title: "G-Corp"
            ),
            primaryButtons: [
                MoreScreen.Model.Action(icon: "calendar", title: "Schedules", destination: { AnyView(EmptyView()) }),
                MoreScreen.Model.Action(icon: "map", title: "Map", destination: { AnyView(EmptyView()) }),
                MoreScreen.Model.Action(icon: "landscape.artframe", title: "Screenshots", destination: { AnyView(EmptyView()) }),
            ],
            secondaryButtons: [
                MoreScreen.Model.Action(icon: "questionmark.circle", title: "Help", destination: { AnyView(EmptyView()) }),
                MoreScreen.Model.Action(icon: "ladybug", title: "Report a bug", destination: { AnyView(EmptyView()) }),
                MoreScreen.Model.Action(icon: "waveform.path.ecg", title: "What Hubstaff tracks", destination: {
                    AnyView(EmptyView())
                }),
            ]
        )
    }
}
#endif
