//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import SwiftUI

import Logging
import LoggingSample
import Orchestration
import Projects
import ProjectsSample
import Session
import SessionSample
import Tracker
import TrackerSample

public class HubstaffRouter: AppRouter {
    init() {
        let environment = ProcessInfo.processInfo.environment
        // if environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || environment["HSTEST"] == "1" {
        self.registerTestServices(with: environment)
        // }
        // else {
        //     self.registerLiveServices()
        // }

        inf("Starting: \(versionInfoString().replacingOccurrences(of: "\n", with: ", "))")
    }

    // - Router
    public lazy var appPresenter: ScreenPresenter = self.session().featurePresenter

    // - Private
    private func session() -> FeatureRouter {
        UserRouter()
    }
    
    /// Populate the registry for use in a local environment for testing.
    ///
    /// In this situation, the application should not need any network capabilities or access to real Hubstaff back-end services.
    private func registerTestServices(with environment: [String: String]) {
        Registry.shared.register(ProjectsInteractor.self, resolving: ProjectsSampleInteractor())
        Registry.shared.register(SessionInteractor.self, resolving: SessionSampleInteractor(
            provideSession: true
        ))
        Registry.shared.register(TrackerInteractor.self, resolving: TrackerSampleInteractor(
            focus: false,
            timeNotes: true,
            taskNotes: false
        ))
        Registry.shared.register(LoggingInteractor.self, resolving: LoggingSampleInteractor())
    }

    /// Populate the registry for use in a fully capable environment.
    ///
    /// In this situation, the application should be able to interact with real Hubstaff back-end services with full persistence.
    private func registerLiveServices() {
        // Registry.shared.register(CoreInteractor.self, resolving: CoreInteractor())
        // Registry.shared.register(ProjectsInteractor.self, resolving: ProjectsCoreInteractor())
        // Registry.shared.register(SessionInteractor.self, resolving: SessionCoreInteractor())
        // Registry.shared.register(TrackerInteractor.self, resolving: TrackerCoreInteractor())
        // Registry.shared.register(ReportsInteractor.self, resolving: ReportsCoreInteractor())
        // Registry.shared.register(TimesheetsInteractor.self, resolving: TimesheetsCoreInteractor())
        // Registry.shared.register(PermissionsInteractor.self, resolving: PermissionsCoreInteractor())
        // Registry.shared.register(LocationsInteractor.self, resolving: LocationsCoreInteractor())
        // Registry.shared.register(NotificationsInteractor.self, resolving: NotificationsCoreInteractor())
        // Registry.shared.register(LoggingInteractor.self, resolving: LoggingCoreInteractor())
    }
}

public class UserRouter: FeatureRouter {
    // - Router
    public lazy var featurePresenter: ScreenPresenter = UserScreenPresenter(router: self)
}

public func versionInfoString() -> String {
    var versionInfo = ""

    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
        versionInfo += "v\(version)"
    }

    if let build = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String {
        versionInfo += "#\(build)"
    }

    versionInfo += "\non \(UIDevice.current.model), \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
    return versionInfo
}
