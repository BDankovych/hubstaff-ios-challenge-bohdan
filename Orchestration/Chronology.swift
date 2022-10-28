//
// Copyright (c) 2021-2022 Netsoft Inc. All rights reserved.
//

/// The purpose of this file is to supply purpose-specific types for working with time.
import Foundation

/// Specifies a Gregorian calendar day.
public struct Day: Hashable {
    public static let epoch = Self(year: 1970, month: 1, day: 1)

    public let year:  UInt16
    public let month: UInt8
    public let day:   UInt8

    public init(year: UInt16, month: UInt8, day: UInt8) {
        self.year = year
        self.month = month
        self.day = day
    }
}

/// Specifies a time-of-day on a 24-hour clock.
public struct TimeOfDay: Hashable {
    public static let midnight = Self(hour: 0, minute: 0, second: 0)

    public let hour:   UInt8
    public let minute: UInt8
    public let second: TimeInterval

    public init(hour: UInt8, minute: UInt8, second: TimeInterval = 0) {
        self.hour = hour
        self.minute = minute
        self.second = second
    }
}

@inlinable public func min(_ x: Day, _ y: Day) -> Day { x - y < .zero ? x : y }

@inlinable public func max(_ x: Day, _ y: Day) -> Day { x - y > .zero ? x : y }

@inlinable public func min(_ x: TimeOfDay, _ y: TimeOfDay) -> TimeOfDay { x - y < .zero ? x : y }

@inlinable public func max(_ x: TimeOfDay, _ y: TimeOfDay) -> TimeOfDay { x - y > .zero ? x : y }

/// Specifies a calendar range which includes its start day, end day, and all days in-between.
public struct DayInterval: Hashable {
    public let first: Day
    public let last:  Day

    public init(only: Day) {
        self.init(first: only, last: only)
    }

    public init(first: Day, last: Day) {
        self.first = first
        self.last = last
    }
}

// MARK: - Calendar Time

public enum TimePeriod {
    case past
    case present
    case future
}

public extension Day {
    /// The calendar day that occurred just before this day on the Gregorian UTC calendar.
    var previous: Day? {
        self.utcMoment().flatMap { Calendar.utc.date(byAdding: .day, value: -1, to: $0) }.flatMap(Day.init(utc:))
    }

    /// The calendar day that occurs just after this day on the Gregorian UTC calendar.
    var next: Day? {
        self.utcMoment().flatMap { Calendar.utc.date(byAdding: .day, value: 1, to: $0) }.flatMap(Day.init(utc:))
    }

    /// Change the current day to the `previous` day, based on the Gregorian UTC calendar.
    @discardableResult
    mutating func formPrevious() -> Bool {
        guard let previous = self.previous
        else { return false }

        self = previous
        return true
    }

    /// Change the current day to the `next` day, based on the Gregorian UTC calendar.
    @discardableResult
    mutating func formNext() -> Bool {
        guard let next = self.next
        else { return false }

        self = next
        return true
    }

    /// For a given calendar component, the interval for when its occurrence that contains this day, has started and will end.
    func interval(of component: Calendar.Component) -> DayInterval? {
        self.utcMoment().flatMap { Calendar.utc.dateInterval(of: component, for: $0) }.flatMap(DayInterval.init(utc:))
    }
}

public extension DayInterval {
    /// The calendar range that starts on the given day and spans a total of length days on the Gregorian UTC calendar.
    init?(first: Day, length: Int) {
        guard let start = first.utcMoment()
        else { return nil }

        self.init(utc: DateInterval(start: start, duration: 3600 * 24 * 7))
    }

    /// The calendar range that starts on the given day and spans a total of length days on the Gregorian UTC calendar.
    init(utc: DateInterval) {
        let days = utc.map(granularity: .day, transform: { $0 })
        self.init(first: .init(utc: days.first ?? utc.start), last: .init(utc: days.last ?? utc.start))
    }

    /// The calendar range that starts on the given day and spans a total of length days on the Gregorian calendar.
    init(local: DateInterval) {
        let days = local.map(granularity: .day, transform: { $0 })
        self.init(first: .init(local: days.first ?? local.start), last: .init(local: days.last ?? local.start))
    }

    func period(for day: Day) -> TimePeriod {
        if day > self.last { return .past }
        if day < self.first { return .future }

        return .present
    }

    /// Each calendar day in the interval, as specified by the Gregorian UTC calendar.
    ///
    /// - Returns: empty if the interval is not valid in the UTC calendar.
    var each:     [Day] {
        guard let absoluteInterval = self.utcInterval()
        else { return [] }

        return absoluteInterval.map(granularity: .day, transform: Day.init(utc:))
    }

    /// The calendar range just before this one with an equal length, as specified by the Gregorian UTC calendar.
    var previous: DayInterval? {
        self.utcInterval()?.previous(granularity: .day).flatMap(DayInterval.init(utc:))
    }

    /// The calendar range just after this one with an equal length, as specified by the Gregorian UTC calendar.
    var next:     DayInterval? {
        self.utcInterval()?.next(granularity: .day).flatMap(DayInterval.init(utc:))
    }

    /// Split this interval into sub-intervals representing units of the component's range on the Gregorian UTC calendar.
    ///
    /// - Parameters:
    ///   - component: The calendar component to iterate over in this interval's sub-ranges.
    ///   - clamp: If `true`, limit the first and last intervals to this interval's range.
    ///            If `false` the first interval can start before this interval, if the calendar component begins earlier, and the last can end after.
    func split(by component: Calendar.Component, clamp: Bool = false) -> [DayInterval] {
        guard var interval = self.first.utcMoment()
            .flatMap({ Calendar.utc.dateInterval(of: component, for: $0) }).flatMap(DayInterval.init(utc:))
        else { return [self] }

        var intervals = [DayInterval](), n = 0
        while interval.first <= self.last, n < 15 {
            if clamp {
                intervals.append(DayInterval(first: max(interval.first, self.first), last: min(interval.last, self.last)))
            }
            else {
                intervals.append(interval)
            }

            guard let nextInterval = (interval.last.next?.utcMoment())
                .flatMap({ Calendar.utc.dateInterval(of: component, for: $0) }).flatMap(DayInterval.init(utc:))
            else { break }

            interval = nextInterval
            n += 1
        }

        return intervals
    }
}

// MARK: - Absolute Time

extension Day: Comparable {
    /// The local calendar day at the current moment.
    public static var today: Self { Self(local: Date()) }

    /// The UTC calendar day at the given moment in time.
    ///
    /// Use this variant when your date is defined to describe a calendar day (relative to UTC).
    public init(utc moment: Date) {
        let components = Calendar.utc.dateComponents([.year, .month, .day], from: moment)
        self.init(year: .init(components.year!), month: .init(components.month!), day: .init(components.day!))
    }

    /// The local calendar day at the given moment in time.
    ///
    /// Use this variant when your date is defined to describe a moment in absolute time and you want to find out what day it is for the current user at this moment in time.
    public init(local moment: Date) {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: moment)
        self.init(year: .init(components.year!), month: .init(components.month!), day: .init(components.day!))
    }

    /// The calendar day at the specified moment in time.
    ///
    /// Use this variant when you have a moment in absolute time described in a string that conforms to the RFC 3339 Internet Time standard, and you want to find out what day it was at this moment in time.
    public init?(rfc3339 string: String) {
        guard let moment = String.rfc3339Formatter.date(from: string)
        else { return nil }

        self.init(utc: moment)
    }

    /// The moment in time when this calendar day occurred in UTC.
    public func utcMoment() -> Date? {
        Calendar.utc.date(from: self.components)
    }

    /// The moment in time when this calendar day occurred on the current user's local calendar.
    public func localMoment() -> Date? {
        Calendar.current.date(from: self.components)
    }

    public static func - (lhs: Self, rhs: Self) -> TimeInterval {
        guard let lhs = lhs.utcMoment(), let rhs = rhs.utcMoment()
        else { return 0 }

        return lhs.timeIntervalSinceNow - rhs.timeIntervalSinceNow
    }

    public static func < (lhs: Self, rhs: Self) -> Bool { rhs - lhs > .zero }

    public static func > (lhs: Self, rhs: Self) -> Bool { lhs - rhs > .zero }

    public static func <= (lhs: Self, rhs: Self) -> Bool { rhs - lhs >= .zero }

    public static func >= (lhs: Self, rhs: Self) -> Bool { lhs - rhs >= .zero }
}

public extension TimeOfDay {
    /// The local time-of-day at the current moment.
    static var now: Self { Self(local: Date()) }

    /// The UTC time-of-day at the given moment in time.
    ///
    /// Use this variant when your date is defined to represent a time-of-day (relative to UTC).
    init(utc moment: Date) {
        let components = Calendar.utc.dateComponents([.hour, .minute, .second, .nanosecond], from: moment)
        self.init(
            hour: .init(components.hour!), minute: .init(components.minute!),
            second: .init(components.second!) + UnitDuration.nanoseconds.converter.baseUnitValue(fromValue: .init(components.nanosecond!))
        )
    }

    /// The local time-of-day at the given moment in time.
    ///
    /// Use this variant when your date is defined to describe a moment in absolute time and you want to find out what the time-of-day was for the current user at this moment in time.
    init(local moment: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: moment)
        self.init(
            hour: .init(components.hour!), minute: .init(components.minute!),
            second: .init(components.second!) + UnitDuration.nanoseconds.converter.baseUnitValue(fromValue: .init(components.nanosecond!))
        )
    }

    /// The moment in time when this time-of-day occurred in UTC.
    ///
    /// - Parameter day: The calendar day on which the time-of-day applies.
    func utcMoment(on day: Day = .epoch) -> Date? {
        Calendar.utc.date(from: day.components.union(self.components))
    }

    /// The moment in time when this time-of-day occurred on the current user's local calendar.
    ///
    /// - Parameter day: The calendar day on which the time-of-day applies.
    func localMoment(on day: Day = .today) -> Date? {
        Calendar.current.date(from: day.components.union(self.components))
    }

    static func - (lhs: Self, rhs: Self) -> TimeInterval {
        guard let lhs = lhs.utcMoment(), let rhs = rhs.utcMoment()
        else { return 0 }

        return lhs.timeIntervalSinceNow - rhs.timeIntervalSinceNow
    }
}

public extension DayInterval {
    /// An interval spanning only the local calendar day at the current moment.
    static var today: Self { Self(only: .today) }

    /// The moment in time when this calendar range occurred in UTC.
    func utcInterval() -> DateInterval? {
        guard let start = self.first.utcMoment(), let end = self.last.utcMoment()
        else { return nil }

        return DateInterval(start: start, duration: (end.timeIntervalSinceReferenceDate - start.timeIntervalSinceReferenceDate) + 3600 * 24)
    }

    /// The moment in time when this calendar range occurred on the current user's local calendar.
    func localInterval() -> DateInterval? {
        guard let start = self.first.localMoment(), let end = self.last.localMoment()
        else { return nil }

        return DateInterval(start: start, duration: (end.timeIntervalSinceReferenceDate - start.timeIntervalSinceReferenceDate) + 3600 * 24)
    }
}

public extension DayInterval {
    var range: ClosedRange<Day> { self.first ... self.last }

    init(_ range: ClosedRange<Day>) {
        self.first = range.lowerBound
        self.last = range.upperBound
    }
}

// MARK: - Formatting

extension Day: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(self.year)-\(self.month)-\(self.day)"
    }
}

extension TimeOfDay: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(self.hour):\(self.minute):\(self.second)"
    }
}

extension DayInterval: CustomDebugStringConvertible {
    public var debugDescription: String {
        "\(self.first) -> \(self.last)"
    }
}

public extension String {
    /// Localized representation of an integer number.
    static func format<N: BinaryInteger>(number: N, as style: NumberFormatter.Style = .decimal) -> String {
        Self.format(number: Int64(number) as NSNumber, as: style)
    }

    /// Localized representation of a floating-point number.
    static func format<N: BinaryFloatingPoint>(number: N, as style: NumberFormatter.Style = .decimal) -> String {
        Self.format(number: Double(number) as NSNumber, as: style)
    }

    /// Localized representation of a number.
    static func format(number: NSNumber, as style: NumberFormatter.Style = .decimal) -> String {
        NumberFormatter.localizedString(from: number, number: style)
    }

    /// Localized representation of an absolute time duration using the given time units.
    static func format(duration: TimeInterval, units: NSCalendar.Unit, inline: Bool = true) -> String {
        var format = using(self.componentsFormatter) {
            $0.allowedUnits = units
        }.string(from: duration) ?? units.toComponents().map { _ in "--" }.joined(separator: ":")

        if inline {
            // 00:00 -> 0:00. DateComponentsFormatter can't pad individual components differently.
            format = format.replacingOccurrences(of: #"^[0-]([\d-])"#, with: "$1", options: .regularExpression)
        }

        return duration < 0 ? "-\(format)" : format
    }

    /// Localized representation of an absolute time duration as a brief platform-specific description.
    static func format(duration: TimeInterval, relative: Bool = false) -> String {
        relative ? self.relativeFormatter.localizedString(fromTimeInterval: duration) : self.durationFormatter.string(from: duration) ?? ""
    }

    /// Localized representation of a range of calendar days.
    static func format(period days: DayInterval) -> String {
        days.utcInterval().flatMap(self.utcPeriodFormatter.string(from:)) ?? ""
    }

    /// Localized representation of the day-of-the-week that the given day lands on.
    static func format(yearMonthOf day: Day) -> String {
        day.utcMoment().flatMap(self.utcYearMonthFormatter.string(from:)) ?? ""
    }

    /// Localized representation of the day-of-the-week that the given day lands on.
    static func format(weekDayOf day: Day) -> String {
        day.utcMoment().flatMap(self.utcDayLetterFormatter.string(from:)) ?? ""
    }

    /// Localized representation of a calendar day.
    static func format(day: Day) -> String {
        day.utcMoment().flatMap(self.utcDateFormatter.string(from:)) ?? ""
    }

    /// Localized representation of a clock time-of-day.
    static func format(time: TimeOfDay) -> String {
        time.utcMoment().flatMap(self.utcTimeFormatter.string(from:)) ?? ""
    }

    /// Localized representation of a moment in time.
    static func format(moment: Date, timeSeparator: String = " • ", zoneSeparator: String = " ") -> String {
        (self.localDateFormatter.string(from: moment)) + timeSeparator +
            (self.localTimeFormatter.string(from: moment)) + zoneSeparator +
            (self.localZoneFormatter.string(from: moment))
    }

    /// Localized representation of an event that spanned across time.
    static func format(span: DateInterval) -> String {
        self.localScheduleFormatter.string(from: span) ?? ""
    }

    // - Private

    private static let componentsFormatter = using(DateComponentsFormatter()) {
        $0.zeroFormattingBehavior = .pad
    }

    private static let yearMonthFormatter = using(DateComponentsFormatter()) {
        $0.allowedUnits = [.year, .month]
    }

    private static let durationFormatter = using(DateComponentsFormatter()) {
        $0.unitsStyle = .brief
    }

    private static let relativeFormatter = using(RelativeDateTimeFormatter()) {
        $0.unitsStyle = .abbreviated
    }

    private static let utcPeriodFormatter = using(DateIntervalFormatter()) {
        $0.dateStyle = .medium
        $0.timeStyle = .none
        $0.timeZone = .utc
    }

    private static let utcYearMonthFormatter = using(DateFormatter()) {
        $0.setLocalizedDateFormatFromTemplate("yyyyLLLL") // LDML stand-alone localized month and year, eg. "September, 2022"
        $0.timeZone = .utc
    }

    private static let utcDayLetterFormatter = using(DateFormatter()) {
        $0.setLocalizedDateFormatFromTemplate("ccccc") // LDML stand-alone localized day of week, eg. "T"
        $0.timeZone = .utc
    }

    private static let utcDateFormatter = using(DateFormatter()) {
        $0.dateStyle = .medium
        $0.timeStyle = .none
        $0.timeZone = .utc
    }

    private static let utcTimeFormatter = using(DateFormatter()) {
        $0.dateStyle = .none
        $0.timeStyle = .short
        $0.timeZone = .utc
    }

    private static let localDateFormatter = using(DateFormatter()) {
        $0.dateStyle = .medium
        $0.timeStyle = .none
    }

    private static let localTimeFormatter = using(DateFormatter()) {
        $0.dateStyle = .none
        $0.timeStyle = .short
    }

    private static let localZoneFormatter = using(DateFormatter()) {
        $0.dateFormat = "v" // The short generic non-location zone, eg. "ET"
    }

    private static let localScheduleFormatter = using(DateIntervalFormatter()) {
        $0.dateStyle = .none
        $0.timeStyle = .short
    }

    fileprivate static let rfc3339Formatter = using(ISO8601DateFormatter()) {
        $0.formatOptions = .withInternetDateTime
        $0.timeZone = .utc
    }
}

// MARK: - Foundation

public extension Day {
    /// The calendar components expressed by this time-of-day. Includes `year`, `month`, and `day` components.
    var components: DateComponents {
        DateComponents(year: Int(self.year), month: Int(self.month), day: Int(self.day))
    }
}

public extension TimeOfDay {
    /// The calendar components expressed by this time-of-day. Includes `hour`, `minute`, `second` and `nanosecond` components.
    var components: DateComponents {
        DateComponents(
            hour: Int(self.hour), minute: Int(self.minute), second: Int(self.second),
            nanosecond: Int(UnitDuration.nanoseconds.converter.value(fromBaseUnitValue: self.second.truncatingRemainder(dividingBy: 1)))
        )
    }
}

public extension Calendar {
    /// A standard calendar instance which operates in the UTC time zone.
    static var utc: Calendar = using(Calendar(identifier: .iso8601)) {
        $0.timeZone = .utc
    }
}

public extension TimeZone {
    /// A standard timezone instance which operates in the UTC time zone.
    static var utc = TimeZone(secondsFromGMT: .zero)!
}

public extension Calendar.Component {
    static var allUnits: [Self: NSCalendar.Unit] = [
        .era: .era,
        .year: .year,
        .month: .month,
        .day: .day,
        .hour: .hour,
        .minute: .minute,
        .second: .second,
        .weekday: .weekday,
        .weekdayOrdinal: .weekdayOrdinal,
        .quarter: .quarter,
        .weekOfMonth: .weekOfMonth,
        .weekOfYear: .weekOfYear,
        .yearForWeekOfYear: .yearForWeekOfYear,
        .nanosecond: .nanosecond,
        .calendar: .calendar,
        .timeZone: .timeZone,
    ]

    /// The ordinality of a calendar component groups components by what standard calendar component they directly affect.
    var ordinality: Int {
        switch self {
            case .era:
                return 7
            case .year:
                return 6
            case .month:
                return 5
            case .day:
                return 4
            case .hour:
                return 3
            case .minute:
                return 2
            case .second:
                return 1
            case .weekday:
                return Self.day.ordinality
            case .weekdayOrdinal:
                return Self.day.ordinality
            case .quarter:
                return Self.month.ordinality
            case .weekOfMonth:
                return Self.day.ordinality
            case .weekOfYear:
                return Self.day.ordinality
            case .yearForWeekOfYear:
                return Self.year.ordinality
            case .nanosecond:
                return 0
            case .calendar:
                return Self.day.ordinality
            case .timeZone:
                return Self.hour.ordinality
            @unknown default:
                return Self.day.ordinality
        }
    }

    /// The previous smaller calendar component describes a smaller standard increment in time on the calendar.
    var previous:   Self {
        let ordinals: [Self] = [.nanosecond, .second, .minute, .hour, .day, .month, .year, .era]
        return ordinals[max(self.ordinality - 1, 0)]
    }

    /// The next greater calendar component describes a bigger standard increment in time on the calendar.
    var next:       Self {
        let ordinals: [Self] = [.nanosecond, .second, .minute, .hour, .day, .month, .year, .era]
        return ordinals[min(self.ordinality + 1, ordinals.count - 1)]
    }
}

public extension NSCalendar.Unit {
    func toComponents() -> Set<Calendar.Component> {
        Set(Calendar.Component.allUnits.compactMap { self.contains($0.value) ? $0.key : nil })
    }
}

public extension DateComponents {
    func union(_ other: DateComponents) -> DateComponents {
        var new = self
        for component in Calendar.Component.allUnits.keys {
            other.value(for: component).flatMap {
                new.setValue($0, for: component)
            }
        }
        return new
    }
}

public extension DateInterval {
    /// The moment just before this date interval begins, at the specified time granularity.
    func before(granularity: Calendar.Component) -> Date? {
        Calendar.utc.date(byAdding: granularity, value: -1, to: self.start)
    }

    /// The moment right after this date interval ends, at the specified time granularity.
    func after(granularity: Calendar.Component) -> Date? {
        Calendar.utc.date(byAdding: granularity, value: 1, to: self.end)
    }

    func period(for date: Date) -> TimePeriod {
        if date > self.end { return .past }
        if date < self.start { return .future }

        return .present
    }

    /// The next interval starts just past where this interval ends, and is the same length, at the specified granularity.
    func next(granularity: Calendar.Component) -> DateInterval? {
        guard let length = Calendar.utc.dateComponents([granularity], from: self.start, to: self.end).value(for: granularity),
              let nextEnd = Calendar.utc.date(byAdding: granularity, value: length, to: self.end)
        else { return nil }

        return DateInterval(start: self.end, end: nextEnd)
    }

    /// The previous interval ends just before where this interval starts, and is the same length, at the specified granularity.
    func previous(granularity: Calendar.Component) -> DateInterval? {
        guard let length = Calendar.utc.dateComponents([granularity], from: self.start, to: self.end).value(for: granularity),
              let previousStart = Calendar.utc.date(byAdding: granularity, value: -length, to: self.start)
        else { return nil }

        return DateInterval(start: previousStart, end: self.start)
    }

    /// Calculate a result for each moment in this date interval, stepping at the specified granularity.
    @discardableResult
    func map<V>(granularity: Calendar.Component, transform: (Date) -> V) -> [V] {
        var results = [transform(self.start)]

        Calendar.utc.enumerateDates(
            startingAfter: self.start,
            matching: Calendar.utc.dateComponents([granularity.previous], from: self.start),
            matchingPolicy: .nextTime
        ) { date, _, stop in
            guard let date = date
            else { return }

            if date >= self.end {
                stop = true
            }
            else {
                results.append(transform(date))
            }
        }

        return results
    }
}
