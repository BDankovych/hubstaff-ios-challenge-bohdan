//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Combine
import SwiftUI

/// A property wrapper that works like `StateObject`, but accepts an optional object (and supports iOS 13).
@propertyWrapper
public struct StateOptionalObject<T: ObservableObject>: DynamicProperty {
    @State
    public var wrappedValue:   T?
    public var projectedValue: DynamicObject {
        DynamicObject(wrappedValue: self.wrappedValue)
    }

    public init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue

        let proxy = Proxy()
        self.proxy = proxy
        self.proxyObject = proxy

        self.update()
    }

    public mutating func update() {
        let proxy = self.proxy
        self.proxyMonitor = self.wrappedValue?.objectWillChange.sink { [weak proxy] _ in
            proxy?.objectWillChange.send()
        }
    }

    // - Private
    @State private var          proxy:        Proxy
    @ObservedObject private var proxyObject:  Proxy
    private var                 proxyMonitor: AnyCancellable?

    private class Proxy: ObservableObject {}

    @dynamicMemberLookup public struct DynamicObject {
        let wrappedValue: T?

        /// Returns an optional binding to the resulting value of a given key path.
        ///
        /// - Parameter keyPath  : A key path to a specific resulting value.
        ///
        /// - Returns: A new binding.
        public subscript<Subject>(dynamicMember keyPath: ReferenceWritableKeyPath<T, Subject>) -> Binding<Subject>? {
            self.wrappedValue.flatMap { wrappedValue in
                Binding {
                    wrappedValue[keyPath: keyPath]
                } set: { value in
                    wrappedValue[keyPath: keyPath] = value
                }
            }
        }
    }
}
