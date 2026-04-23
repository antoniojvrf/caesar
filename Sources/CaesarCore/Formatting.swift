import Foundation

public enum AppFormatting {
    public static let brazilianCurrency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "BRL"
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    public static let monthLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "MMM"
        return formatter
    }()

    public static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM"
        return formatter
    }()

    public static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()

    public static func currency(_ value: Double) -> String {
        brazilianCurrency.string(from: NSNumber(value: value)) ?? "R$ \(value)"
    }

    public static func percent(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    public static func isoDate(_ date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else {
            return ""
        }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    public static func monthKey(_ date: Date, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let year = components.year, let month = components.month else {
            return ""
        }
        return String(format: "%04d-%02d", year, month)
    }

    public static func date(fromISO value: String, calendar: Calendar = .current) -> Date? {
        guard value.count >= 10 else { return nil }
        let parts = value.prefix(10).split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]
        return calendar.date(from: components)
    }

    public static func shortDate(_ iso: String) -> String {
        guard let date = date(fromISO: iso) else { return iso }
        return shortDateFormatter.string(from: date)
    }

    public static func addingMonths(_ months: Int, toISODate iso: String, calendar: Calendar = .current) -> String {
        guard let date = date(fromISO: iso, calendar: calendar),
              let next = calendar.date(byAdding: .month, value: months, to: date) else {
            return iso
        }
        return isoDate(next, calendar: calendar)
    }

    public static func monthLabel(for month: String, calendar: Calendar = .current) -> String {
        guard let date = date(fromISO: "\(month)-01", calendar: calendar) else {
            return month
        }
        let rawLabel = monthLabelFormatter.string(from: date).replacingOccurrences(of: ".", with: "")
        return rawLabel.prefix(1).uppercased() + rawLabel.dropFirst()
    }
}
