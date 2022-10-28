//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Foundation

public protocol LoggingInteractor {
    func time<R>(_ topic: String, file: String, line: Int32, function: String, action: () -> R) -> R
    func trace(_ message: String, file: String, line: Int32, function: String)
    func debug(_ message: String, file: String, line: Int32, function: String)
    func info(_ message: String, file: String, line: Int32, function: String)
    func error(_ message: String, file: String, line: Int32, function: String)
    func audit(event: String, _ message: String, file: String, line: Int32, function: String)
}
