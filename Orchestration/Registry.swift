//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Foundation

public class Registry {
    public static var shared = Registry()

    private var factory  = [ObjectIdentifier: () -> Any]()
    private var registry = [ObjectIdentifier: Any]()

    public func register<C/*: Contract */>(_ contract: C.Type, resolving: @escaping @autoclosure () -> C) {
        self.factory[ObjectIdentifier(contract)] = resolving
    }

    public func resolve<C/*: Contract */>(_ contract: C.Type = C.self) -> C {
        let contractIdentifier = ObjectIdentifier(contract)

        if let resolved = self.registry[contractIdentifier] as? C {
            return resolved
        }

        if let resolved = self.factory[contractIdentifier]?() as? C {
            self.registry[contractIdentifier] = resolved
            return resolved
        }

        fatalError("No implementation for \(contract) has been registered.")
    }
}
