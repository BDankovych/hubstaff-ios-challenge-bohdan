//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Foundation
import Orchestration
import SwiftUI
import UIKit

public extension View {
    /// Supply any kind of accessory view to an ancestor AccessoryReader.
    ///
    /// Use this variant for convenience. The view can be any view.
    /// The view is responsible for its own updates, or updates can be triggered by a change in `id`.
    ///
    /// Set `isPresented` to `false` to remove the accessory.
    func accessory<A: View>(isPresented: Bool, id: AnyHashable = 0, @ViewBuilder content: @escaping () -> A) -> some View {
        self.preference(
            key: AccessoryContentPreference.self,
            value: !isPresented ? nil : AnyEquatableView(Lazy(id: id) { content() })
        )
    }

    /// Supply an accessory view to an ancestor AccessoryReader.
    ///
    /// Use this variant for full control over the view's updates.
    /// The view should be equatable and will only update if the new view is not equal to the previous value.
    ///
    /// Return nil to remove the accessory.
    func accessory<A: View & Equatable>(@ViewBuilder content: @escaping () -> A?) -> some View {
        self.preference(
            key: AccessoryContentPreference.self,
            value: content().flatMap { AnyEquatableView($0) }
        )
    }
}

/// A wrapper that listens to its hierarchy for accessory views. If one is detected, it is passed to the content.
public struct AccessoryReader<Content: View>: View {
    @ViewBuilder
    public var content: (AnyEquatableView?) -> Content

    @State
    private var accessoryContent = AccessoryContentPreference.defaultValue

    public var body: some View {
        self.content(self.accessoryContent)
            .onPreferenceChange(AccessoryContentPreference.self) { self.accessoryContent = $0 }
    }
}

private struct AccessoryContentPreference: PreferenceKey {
    public static func reduce(value: inout AnyEquatableView?, nextValue: () -> AnyEquatableView?) {
        nextValue().flatMap { value = $0 }
    }
}
