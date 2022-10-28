//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

import Foundation

import Logging

public func time<R>(
    _ topic: String, file: String = #file, line: Int32 = #line, function: String = #function,
    action: () -> R
)
    -> R {
    Registry.shared.resolve(LoggingInteractor.self).time(topic, file: file, line: line, function: function, action: action)
}

public func trc(_ message: String, file: String = #file, line: Int32 = #line, function: String = #function) {
    Registry.shared.resolve(LoggingInteractor.self).trace(message, file: file, line: line, function: function)
}

public func dbg(_ message: String, file: String = #file, line: Int32 = #line, function: String = #function) {
    Registry.shared.resolve(LoggingInteractor.self).debug(message, file: file, line: line, function: function)
}

public func inf(_ message: String, file: String = #file, line: Int32 = #line, function: String = #function) {
    Registry.shared.resolve(LoggingInteractor.self).info(message, file: file, line: line, function: function)
}

public func err(_ message: String, file: String = #file, line: Int32 = #line, function: String = #function) {
    Registry.shared.resolve(LoggingInteractor.self).error(message, file: file, line: line, function: function)
}

public func aud(event: String, _ message: String, file: String = #file, line: Int32 = #line, function: String = #function) {
    Registry.shared.resolve(LoggingInteractor.self).audit(event: event, message, file: file, line: line, function: function)
}
