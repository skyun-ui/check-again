import Foundation

/// 모든 할 일의 알림을 합쳐 실제로 예약할 목록을 정한다.
///
/// iOS는 앱당 예약 알림을 64개까지만 유지한다. 할 일마다 다시 알림을 미리 예약하면 금방 넘치므로,
/// 모든 할 일의 앞으로 울릴 알림을 시간순으로 합쳐 **가장 가까운 64개만** 예약하고, 데이터가 바뀔 때마다 다시 계산한다.
public enum ReminderScheduler {
    /// iOS가 앱당 유지하는 예약 알림 수.
    public static let systemLimit = 64

    public struct Item: Sendable {
        public enum Schedule: Sendable {
            case repeating(anchor: Date, policy: ReminderPolicy)
            case oneTime(due: Date, followUpEnabled: Bool)
        }

        public let routineID: UUID
        public let schedule: Schedule

        public init(routineID: UUID, schedule: Schedule) {
            self.routineID = routineID
            self.schedule = schedule
        }

        public init(routineID: UUID, anchor: Date, policy: ReminderPolicy) {
            self.init(routineID: routineID, schedule: .repeating(anchor: anchor, policy: policy))
        }

        public func upcomingFires(now: Date, limit: Int) -> [ReminderFire] {
            switch schedule {
            case let .repeating(anchor, policy):
                policy.upcomingFires(anchor: anchor, now: now, limit: limit)
            case let .oneTime(due, followUpEnabled):
                ReminderPolicy.oneTimeFires(due: due, followUpEnabled: followUpEnabled, now: now)
            }
        }
    }

    public struct Request: Equatable, Sendable {
        public let routineID: UUID
        public let fire: ReminderFire

        public init(routineID: UUID, fire: ReminderFire) {
            self.routineID = routineID
            self.fire = fire
        }

        /// 알림 식별자. 같은 할 일·같은 시각이면 같은 값이라 다시 예약해도 중복되지 않는다.
        public var identifier: String {
            "\(routineID.uuidString)-\(Int(fire.date.timeIntervalSince1970))"
        }
    }

    /// 앞으로 울릴 알림 중 가장 가까운 `limit`개를 시간순으로 돌려준다.
    /// 방해 금지 시간에 걸린 알림은 끝나는 시각으로 미루고, 같은 할 일의 알림이 같은 시각으로 모이면 하나만 남긴다.
    public static func plan(
        _ items: [Item],
        now: Date,
        limit: Int = systemLimit,
        quietHours: QuietHours? = nil
    ) -> [Request] {
        let requests = items.flatMap { item -> [Request] in
            var seen = Set<Date>()
            return item.upcomingFires(now: now, limit: limit).compactMap { fire in
                let date = quietHours?.adjusted(fire.date) ?? fire.date
                guard seen.insert(date).inserted else { return nil }
                return Request(routineID: item.routineID, fire: ReminderFire(date: date, kind: fire.kind))
            }
        }
        return Array(requests.sorted { $0.fire.date < $1.fire.date }.prefix(limit))
    }
}
