import Foundation

public enum AppDateValidation {
    public static func normalizedISODate(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let date = AppFormatting.date(fromISO: trimmed) {
            return AppFormatting.isoDate(date)
        }

        let slashParts = trimmed.split(separator: "/").compactMap { Int($0) }
        if slashParts.count == 3 {
            var components = DateComponents()
            components.calendar = Calendar(identifier: .gregorian)
            components.day = slashParts[0]
            components.month = slashParts[1]
            components.year = slashParts[2]
            if let date = components.calendar?.date(from: components) {
                return AppFormatting.isoDate(date)
            }
        }

        return nil
    }

    public static func normalizedMonthKey(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 7 else { return nil }
        let candidate = String(trimmed.prefix(7))
        let parts = candidate.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2, (1...12).contains(parts[1]) else { return nil }
        return String(format: "%04d-%02d", parts[0], parts[1])
    }
}
