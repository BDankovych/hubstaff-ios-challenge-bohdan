//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Foundation

import Logging
import Orchestration

public class LoggingSampleInteractor: NSObject, LoggingInteractor {
    public func time<R>(_ topic: String, file: String, line: Int32, function: String, action: () -> R) -> R {
        let start = Date()
        defer { print("[time: \(Int(-start.timeIntervalSinceNow * 1000)) ms] \(topic)") }
        return action()
    }

    public func trace(_ message: String, file: String, line: Int32, function: String) {
        print("[trace] \(message)")
    }

    public func debug(_ message: String, file: String, line: Int32, function: String) {
        print("[debug] \(message)")
    }

    public func info(_ message: String, file: String, line: Int32, function: String) {
        print("[info] \(message)")
    }

    public func error(_ message: String, file: String, line: Int32, function: String) {
        print("[error] \(message)")
    }

    public func audit(event: String, _ message: String, file: String, line: Int32, function: String) {
        print("[audit: \(event)] \(message)")
    }
}
