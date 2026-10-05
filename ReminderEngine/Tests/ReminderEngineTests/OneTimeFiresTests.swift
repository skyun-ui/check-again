import Foundation
import Testing
import ReminderEngine

struct OneTimeFiresTests {
    let now = Date(timeIntervalSince1970: 1_000_000)
    let hour: TimeInterval = 3600

    @Test("한 번짜리 알림: 정한 시각, 1시간 간격 다시 알림 2번, 지난 것은 빼고")
    func oneTimeFires() {
        let due = now.addingTimeInterval(hour)
        let all = ReminderPolicy.oneTimeFires(due: due, followUpEnabled: true, now: now)
        #expect(all.map(\.date) == [due, due.addingTimeInterval(hour), due.addingTimeInterval(2 * hour)])

        let later = ReminderPolicy.oneTimeFires(due: due, followUpEnabled: true, now: due.addingTimeInterval(30 * 60))
        #expect(later.map(\.kind) == [.followUp(1), .followUp(2)])

        #expect(ReminderPolicy.oneTimeFires(due: due, followUpEnabled: false, now: now).count == 1)
    }

    @Test("스케줄러는 반복과 한 번짜리를 함께 시간순으로 합친다")
    func mixedPlan() {
        let repeating = ReminderScheduler.Item(routineID: UUID(), anchor: now, policy: ReminderPolicy(interval: 2 * hour, followUpEnabled: false))
        let once = ReminderScheduler.Item(routineID: UUID(), schedule: .oneTime(due: now.addingTimeInterval(hour), followUpEnabled: false))

        let plan = ReminderScheduler.plan([repeating, once], now: now, limit: 3)

        #expect(plan.map(\.routineID) == [once.routineID, repeating.routineID, repeating.routineID])
    }
}
