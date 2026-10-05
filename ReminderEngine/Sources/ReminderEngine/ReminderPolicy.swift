import Foundation

/// 알림 한 건: 언제, 어떤 종류로 울리는지.
public struct ReminderFire: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case due
        case followUp(Int)
    }

    public let date: Date
    public let kind: Kind

    public init(date: Date, kind: Kind) {
        self.date = date
        self.kind = kind
    }
}

/// 할 일 하나의 알림 일정 계산.
///
/// 핵심은 **완료 기준 반복**이다. 다음 알림은 정해진 시각이 아니라 마지막으로 완료한 시각(anchor)부터 센다.
/// 체크하지 않으면 주기의 1/24 간격(최소 10분)으로 최대 2번 더 알리고, 그래도 안 하면 다음 주기에 다시 알린다.
public struct ReminderPolicy: Equatable, Sendable {
    public static let maxFollowUps = 2
    public static let minimumFollowUpInterval: TimeInterval = 10 * 60
    /// 한 번만 하는 일은 주기가 없어서 다시 알림 간격을 1시간으로 고정한다.
    public static let oneTimeFollowUpInterval: TimeInterval = 60 * 60

    /// 한 번만 하는 일의 알림: 정한 시각, 그리고 다시 알림 최대 2회. `now` 이후 것만.
    public static func oneTimeFires(due: Date, followUpEnabled: Bool, now: Date) -> [ReminderFire] {
        var fires = [ReminderFire(date: due, kind: .due)]
        if followUpEnabled {
            for count in 1...maxFollowUps {
                fires.append(ReminderFire(date: due.addingTimeInterval(oneTimeFollowUpInterval * Double(count)), kind: .followUp(count)))
            }
        }
        return fires.filter { $0.date > now }
    }

    public var step: IntervalValue
    public var followUpEnabled: Bool
    public var customFollowUpInterval: TimeInterval?
    public var calendar: Calendar

    public init(
        step: IntervalValue,
        followUpEnabled: Bool = true,
        customFollowUpInterval: TimeInterval? = nil,
        calendar: Calendar = .current
    ) {
        self.step = step
        self.followUpEnabled = followUpEnabled
        self.customFollowUpInterval = customFollowUpInterval
        self.calendar = calendar
    }

    public init(interval: TimeInterval, followUpEnabled: Bool = true, customFollowUpInterval: TimeInterval? = nil) {
        self.init(step: IntervalValue(seconds: interval), followUpEnabled: followUpEnabled, customFollowUpInterval: customFollowUpInterval)
    }

    /// 대략적인 주기 길이(초). 월·년은 30일·365일로 본다.
    public var interval: TimeInterval { step.seconds }

    /// 다시 알림 간격. 지정값이 없으면 주기의 1/24, 최소 10분.
    public var followUpInterval: TimeInterval? {
        guard followUpEnabled else { return nil }
        return max(customFollowUpInterval ?? interval / 24, Self.minimumFollowUpInterval)
    }

    public func dueDate(after anchor: Date) -> Date {
        due(cycle: 0, anchor: anchor)
    }

    /// `cycle`번째 주기의 알림 시각. 0이 첫 알림.
    private func due(cycle: Int, anchor: Date) -> Date {
        step.date(byAdding: cycle + 1, to: anchor, calendar: calendar)
    }

    /// 기준 시각 이후, `now`보다 뒤에 울릴 알림을 시간순으로 최대 `limit`개 만든다.
    public func upcomingFires(anchor: Date, now: Date, limit: Int) -> [ReminderFire] {
        guard interval > 0, limit > 0 else { return [] }

        // 오래 밀린 할 일은 이미 지나간 주기를 건너뛴다. 월·년은 길이가 달마다 달라서 대략값으로 넉넉히(두 주기 앞부터) 본다.
        var cycle = max(0, Int(now.timeIntervalSince(anchor) / interval) - 2)
        var fires: [ReminderFire] = []
        while fires.count < limit {
            let due = due(cycle: cycle, anchor: anchor)
            let nextDue = self.due(cycle: cycle + 1, anchor: anchor)
            for fire in firesInCycle(due: due, nextDue: nextDue) where fire.date > now {
                fires.append(fire)
                if fires.count == limit { break }
            }
            cycle += 1
        }
        return fires
    }

    private func firesInCycle(due: Date, nextDue: Date) -> [ReminderFire] {
        var fires = [ReminderFire(date: due, kind: .due)]
        guard let followUpInterval else { return fires }

        for count in 1...Self.maxFollowUps {
            let date = due.addingTimeInterval(followUpInterval * Double(count))
            guard date < nextDue else { break }
            fires.append(ReminderFire(date: date, kind: .followUp(count)))
        }
        return fires
    }
}
