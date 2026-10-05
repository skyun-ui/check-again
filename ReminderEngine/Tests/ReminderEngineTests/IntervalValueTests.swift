import Foundation
import Testing
import ReminderEngine

private let secondsCases: [(TimeInterval, IntervalValue)] = [
    (12 * 3600, IntervalValue(amount: 12, unit: .hour)),
    (24 * 3600, IntervalValue(amount: 1, unit: .day)),
    (14 * 24 * 3600, IntervalValue(amount: 2, unit: .week)),
    (30 * 24 * 3600, IntervalValue(amount: 30, unit: .day)),
]

struct IntervalValueTests {
    @Test("초를 나누어떨어지는 가장 큰 단위로 바꾼다", arguments: secondsCases)
    func initFromSeconds(seconds: TimeInterval, expected: IntervalValue) {
        #expect(IntervalValue(seconds: seconds) == expected)
        #expect(expected.seconds == seconds)
    }

    @Test("반복 표현")
    func repeatLabel() {
        #expect(IntervalValue(amount: 1, unit: .month).repeatLabel == "매달")
        #expect(IntervalValue(amount: 6, unit: .month).repeatLabel == "6개월마다")
        #expect(IntervalValue(amount: 1, unit: .year).repeatLabel == "매년")
        #expect(IntervalValue(amount: 1, unit: .day).repeatLabel == "매일")
        #expect(IntervalValue(amount: 1, unit: .week).repeatLabel == "매주")
        #expect(IntervalValue(amount: 3, unit: .day).repeatLabel == "3일마다")
        #expect(IntervalValue(amount: 12, unit: .hour).repeatLabel == "12시간마다")
    }
}
