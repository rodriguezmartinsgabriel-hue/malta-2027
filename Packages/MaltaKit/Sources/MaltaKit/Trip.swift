import Foundation

public struct TripSettings: Codable, Hashable {
    public static let defaultFx = 6.18
    public static let defaultMeta = 10_000.0
    public static let defaultMonthly = 800.0

    /// "2027-08-28" style ISO date.
    public var start: String
    public var meta: Double
    public var monthly: Double
    /// manual FX used when live FX is off or unavailable
    public var manualFx: Double

    public init(start: String = Trip.defaultStart, meta: Double = TripSettings.defaultMeta,
                monthly: Double = TripSettings.defaultMonthly, manualFx: Double = TripSettings.defaultFx) {
        self.start = start
        self.meta = meta
        self.monthly = monthly
        self.manualFx = manualFx
    }
}

public struct Trip {
    public static let defaultStart = "2027-08-28"
    public static let defaultEnd = "2027-09-17"
    public static let days = 21

    /// "2027-08-28" -> Date at noon local. Falls back to today's noon on garbage input.
    public static func date(fromISO iso: String) -> Date {
        var comps = DateComponents()
        let parts = iso.split(separator: "-").compactMap { Int($0) }
        if parts.count == 3 {
            comps.year = parts[0]
            comps.month = parts[1]
            comps.day = parts[2]
            var cal = Calendar(identifier: .iso8601)
            cal.timeZone = TimeZone.current
            if let d = cal.date(from: comps) {
                return dateAtNoon(d)
            }
        }
        return dateAtNoon(Date())
    }

    public static func dateAtNoon(_ d: Date) -> Date {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        var comps = cal.dateComponents([.year, .month, .day], from: d)
        comps.hour = 12
        comps.minute = 0
        return cal.date(from: comps) ?? d
    }

    /// Full days between today (at noon) and the trip start, never negative.
    public static func countdown(toISO iso: String, from now: Date = Date()) -> Int {
        let start = Trip.date(fromISO: iso)
        let today = Trip.dateAtNoon(now)
        let days = start.timeIntervalSince(today) / 86_400.0
        return max(0, Int(days.rounded()))
    }

    /// Date of itinerary line i = start + i days.
    public static func itineraryDate(startISO: String, dayIndex: Int) -> Date {
        let start = Trip.date(fromISO: startISO)
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        return cal.date(byAdding: .day, value: dayIndex, to: start) ?? start
    }

    /// Short pt-BR weekday, uppercase, no punctuation: "DOM", "SEG"...
    public static func weekdayLabel(for date: Date) -> String {
        let names = ["DOM", "SEG", "TER", "QUA", "QUI", "SEX", "SAB"]
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        let weekday = cal.component(.weekday, from: date) // 1 = sunday
        return names[weekday - 1]
    }

    /// "28/08"
    public static func dayMonthLabel(for date: Date) -> String {
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        let d = cal.component(.day, from: date)
        let m = cal.component(.month, from: date)
        let mm = m < 10 ? "0\(m)" : "\(m)"
        return d < 10 ? "0\(d)/\(mm)" : "\(d)/\(mm)"
    }

    public static func longDateLabel(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "pt_BR")
        fmt.timeZone = TimeZone.current
        fmt.dateFormat = "d 'de' MMMM 'de' yyyy"
        return fmt.string(from: date)
    }
}

public struct ItineraryDay: Codable, Identifiable, Hashable {
    public var id: UUID
    public var title: String
    public var note: String
    public var done: Bool

    public init(id: UUID = UUID(), title: String, note: String = "", done: Bool = false) {
        self.id = id
        self.title = title
        self.note = note
        self.done = done
    }
}

public struct ChecklistItem: Codable, Identifiable, Hashable {
    public enum Group: String, Codable, CaseIterable {
        case docs
        case mala
        case dinheiro

        public var label: String {
            switch self {
            case .docs: return "documentos"
            case .mala: return "mala"
            case .dinheiro: return "dinheiro"
            }
        }
    }

    public var id: UUID
    public var text: String
    public var done: Bool

    public init(id: UUID = UUID(), text: String, done: Bool = false) {
        self.id = id
        self.text = text
        self.done = done
    }
}

/// Cofrinho projection: monthly * months between now and the trip start (inclusive).
public func projectedSavings(monthly: Double, startISO: String, _ now: Date = Date()) -> Double {
    let start = Trip.date(fromISO: startISO)
    let months = monthsUntil(start: start, from: now)
    return projected(monthly: monthly, months: months)
}

/// Months between now and the trip start (always >= 0, +1 inclusive aporte).
public func monthsUntil(start: Date, from: Date) -> Int {
    var cal = Calendar.current
    cal.timeZone = TimeZone.current
    let now = Trip.dateAtNoon(from)
    let months = cal.dateComponents([.month], from: now, to: start).month ?? 0
    return max(0, months)
}

public func projected(monthly: Double, months: Int) -> Double {
    monthly * Double(months + 1)
}
