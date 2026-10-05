import Foundation

/// 방해 금지 시간.
///
/// 완료 기준 반복에서는 새벽 2시에 체크하면 다음 알림도 새벽 2시에 잡힌다.
/// 이 시간대에 울릴 알림은 끝나는 시각으로 미룬다.
public struct QuietHours: Equatable, Sendable {
    public static let defaultStart = 23 * 60
    public static let defaultEnd = 8 * 60

    public var isEnabled: Bool
    /// 자정부터 분 단위
    public var start: Int
    public var end: Int
    public var calendar: Calendar

    public init(isEnabled: Bool = true, start: Int = defaultStart, end: Int = defaultEnd, calendar: Calendar = .current) {
        self.isEnabled = isEnabled
        self.start = start
        self.end = end
        self.calendar = calendar
    }

    private func minuteOfDay(_ date: Date) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }

    public func contains(_ date: Date) -> Bool {
        guard isEnabled, start != end else { return false }
        let minute = minuteOfDay(date)
        // 자정을 넘는 구간(23:00 ~ 08:00)과 넘지 않는 구간(13:00 ~ 14:00) 모두
        return start < end ? (minute >= start && minute < end) : (minute >= start || minute < end)
    }

    /// 방해 금지 시간이면 끝나는 시각으로 미룬다. 아니면 그대로.
    public func adjusted(_ date: Date) -> Date {
        guard contains(date) else { return date }
        let startOfDay = calendar.startOfDay(for: date)
        var end = calendar.date(byAdding: .minute, value: self.end, to: startOfDay) ?? date
        if end <= date {
            end = calendar.date(byAdding: .day, value: 1, to: end) ?? date
        }
        return end
    }
}
