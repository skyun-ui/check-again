import Foundation

/// 반복 주기의 단위
public enum IntervalUnit: String, CaseIterable, Identifiable, Sendable {
    case hour, day, week, month, year

    public var id: Self { self }

    /// 단위 하나의 길이(초). 월·년은 대략값이고, 실제 날짜 계산은 달력으로 한다.
    public var seconds: TimeInterval {
        switch self {
        case .hour: 60 * 60
        case .day: 24 * 60 * 60
        case .week: 7 * 24 * 60 * 60
        case .month: 30 * 24 * 60 * 60
        case .year: 365 * 24 * 60 * 60
        }
    }

    public var label: String {
        switch self {
        case .hour: "시간"
        case .day: "일"
        case .week: "주"
        case .month: "개월"
        case .year: "년"
        }
    }
}

/// 사람이 고르고 읽는 반복 주기. 예: 3일, 6개월
public struct IntervalValue: Hashable, Sendable {
    public var amount: Int
    public var unit: IntervalUnit

    public init(amount: Int, unit: IntervalUnit) {
        self.amount = amount
        self.unit = unit
    }

    /// 초로만 저장된 값을 읽을 때: 나누어떨어지는 가장 큰 단위로 표현한다. 예: 1,209,600초 → 2주
    public init(seconds: TimeInterval) {
        let unit = [IntervalUnit.week, .day].first { seconds.truncatingRemainder(dividingBy: $0.seconds) == 0 } ?? .hour
        self.init(amount: max(1, Int((seconds / unit.seconds).rounded())), unit: unit)
    }

    /// 대략적인 길이(초). 다시 알림 간격처럼 정확한 날짜가 필요 없는 곳에 쓴다.
    public var seconds: TimeInterval { Double(amount) * unit.seconds }

    /// 기준 시각에서 주기를 `count`번 지난 시각.
    /// 월·년은 달력 기준이라 3월 15일 → 4월 15일이 되고, 없는 날짜(1월 31일 → 2월)는 그달 마지막 날이 된다.
    /// 매번 기준 시각에서 더하기 때문에 1월 31일 → 2월 28일 → 3월 31일처럼 날짜가 밀리지 않는다.
    public func date(byAdding count: Int, to date: Date, calendar: Calendar) -> Date {
        switch unit {
        case .hour, .day, .week:
            date.addingTimeInterval(seconds * Double(count))
        case .month:
            calendar.date(byAdding: .month, value: amount * count, to: date) ?? date.addingTimeInterval(seconds * Double(count))
        case .year:
            calendar.date(byAdding: .year, value: amount * count, to: date) ?? date.addingTimeInterval(seconds * Double(count))
        }
    }

    /// 짧은 표현. 예: 12시간, 1일, 3개월
    public var label: String { "\(amount)\(unit.label)" }

    /// 반복 표현. 예: 매일, 3일마다, 매달
    public var repeatLabel: String {
        switch (amount, unit) {
        case (1, .hour): "매시간"
        case (1, .day): "매일"
        case (1, .week): "매주"
        case (1, .month): "매달"
        case (1, .year): "매년"
        default: "\(label)마다"
        }
    }
}
